#!/usr/bin/env python3
"""Convert cleaned LC-pupil MAT files to NWB for DANDI submission.

This script is a first-pass conversion utility tailored to the current
LCPupil_Joshi_Analysis data layout and session MAT schema.
"""

from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

import numpy as np
import csv
from pynwb import NWBHDF5IO, NWBFile
from pynwb.behavior import TimeSeries as BehavioralTimeSeries
from pynwb.file import Subject
from scipy.io import loadmat


def find_repo_root(start: Path) -> Path:
    cur = start.resolve()
    for candidate in [cur] + list(cur.parents):
        if (candidate / "Code" / "config_paths.m").exists():
            return candidate
    raise FileNotFoundError("Could not locate repository root containing Code/config_paths.m")


def parse_data_root_from_config(config_path: Path) -> Path:
    text = config_path.read_text(encoding="utf-8")
    m = re.search(r"paths\.data_root\s*=\s*'([^']+)'", text)
    if not m:
        raise RuntimeError("Could not parse paths.data_root from config_paths.m")
    return Path(m.group(1)).expanduser()


def infer_session_start_time() -> datetime:
    # Placeholder timestamp because source files do not currently expose
    # timezone-aware acquisition start in a standardized field.
    return datetime(2000, 1, 1, tzinfo=timezone.utc)


def create_subject(monkey: str) -> Subject:
    # DANDI-required metadata fields are present.
    # Age is unknown in source metadata; we use a placeholder ISO-8601
    # duration that should be updated if exact age later becomes available.
    return Subject(
        subject_id=monkey,
        species="Macaca mulatta",
        sex="M",
        age="P0D",
        description=f"Monkey {monkey}; sex=M; age unknown at conversion time",
    )


def _extract_spike_times(cell_value) -> np.ndarray:
    arr = np.asarray(cell_value)
    if arr.size == 0:
        return np.array([], dtype=float)
    flat = np.ravel(arr).astype(float)
    return flat[np.isfinite(flat)]


def _load_manuscript_includes(session_csv: Path, unit_csv: Path) -> Tuple[set, Dict[Tuple[str, str], set]]:
    include_sessions = set()
    include_units: Dict[Tuple[str, str], set] = {}

    with session_csv.open("r", encoding="utf-8", newline="") as f:
        r = csv.DictReader(f)
        for row in r:
            monkey = row["monkey"]
            session_file = row["session_file"]
            include_sessions.add((monkey, session_file))

    with unit_csv.open("r", encoding="utf-8", newline="") as f:
        r = csv.DictReader(f)
        for row in r:
            monkey = row["monkey"]
            session_file = row["session_file"]
            local_unit = int(float(row["unit"]))
            key = (monkey, session_file)
            include_units.setdefault(key, set()).add(local_unit)

    return include_sessions, include_units


def build_nwb_for_session(
    mat_path: Path,
    monkey: str,
    session_idx: int,
    output_dir: Path,
    include_local_units: set | None = None,
) -> Tuple[Path, Dict[str, int]]:
    data = loadmat(str(mat_path), squeeze_me=False, struct_as_record=False)
    if "siteData" not in data:
        raise RuntimeError(f"siteData variable not found in {mat_path}")

    site_data = data["siteData"]
    # MATLAB cell array comes in as object ndarray shape (1, N)
    flat_cells = np.ravel(site_data)
    if flat_cells.size < 3:
        raise RuntimeError(f"Unexpected siteData format in {mat_path}; need >=3 cells")

    trial_meta = np.asarray(flat_cells[0], dtype=float)
    pupil = np.asarray(flat_cells[1], dtype=float)
    spikes = np.asarray(flat_cells[2], dtype=object)

    if trial_meta.ndim != 2 or trial_meta.shape[1] < 9:
        raise RuntimeError(f"trial metadata must be [n_trials x >=9] in {mat_path}")

    n_trials = trial_meta.shape[0]
    trial_spacing_seconds = 100.0
    n_units_total = spikes.shape[1] if spikes.ndim == 2 else 0
    n_single_units = max(0, n_units_total - 1)

    session_id = mat_path.stem
    nwbfile = NWBFile(
        session_description="LC-pupil fixation task session",
        identifier=f"{session_id}",
        session_start_time=infer_session_start_time(),
        session_id=session_id,
        institution="University of Pennsylvania",
        lab="Joshua Gold",
        experiment_description="Converted from siteData MAT format",
        experimenter=("Joshi, Siddhartha",),
        keywords=("LC", "pupil", "electrophysiology", "fixation"),
    )
    nwbfile.subject = create_subject(monkey)

    # Trials table
    nwbfile.add_trial_column(name="correct", description="Trial correctness flag from siteData{1} col3")
    nwbfile.add_trial_column(name="beep_time_ms", description="Beep time (ms) from siteData{1} col4")
    nwbfile.add_trial_column(name="trial_time_index", description="Trial time index from siteData{1} col7")
    stim_markers = trial_meta[:, 8] if trial_meta.shape[1] >= 9 else np.array([])
    include_stim_col = np.any(np.isfinite(stim_markers))
    if include_stim_col:
        nwbfile.add_trial_column(name="stimulation_marker", description="Stimulation marker from siteData{1} col9")

    for i in range(n_trials):
        end_ms = trial_meta[i, 1] if np.isfinite(trial_meta[i, 1]) else 0.0
        start_time = float(i) * trial_spacing_seconds
        end_time = start_time + max(0.001, float(end_ms) / 1000.0)
        trial_kwargs = dict(
            start_time=start_time,
            stop_time=end_time,
            correct=float(trial_meta[i, 2]) if np.isfinite(trial_meta[i, 2]) else np.nan,
            beep_time_ms=float(trial_meta[i, 3]) if np.isfinite(trial_meta[i, 3]) else np.nan,
            trial_time_index=float(trial_meta[i, 6]) if np.isfinite(trial_meta[i, 6]) else np.nan,
        )
        if include_stim_col:
            trial_kwargs["stimulation_marker"] = float(trial_meta[i, 8]) if np.isfinite(trial_meta[i, 8]) else np.nan
        nwbfile.add_trial(**trial_kwargs)

    # Pupil (store value channel index 4 when present)
    if pupil.ndim == 3 and pupil.shape[2] >= 4:
        pupil_value = pupil[:, :, 3]  # 0-based index => field 4
        # Flatten trials x time into one long timeseries for storage simplicity.
        flat_pupil = np.asarray(pupil_value, dtype=float).reshape(-1)
        flat_pupil = np.nan_to_num(flat_pupil, nan=np.nan)
        ts = BehavioralTimeSeries(
            name="pupil_value_channel4",
            data=flat_pupil,
            unit="a.u.",
            rate=1000.0,
            description="Flattened [trial x time] pupil value from siteData{2}(:,:,4)",
        )
        nwbfile.add_acquisition(ts)

    # Units and spike times
    unit_min_shift_applied = 0
    units_written = 0
    if n_units_total > 1:
        nwbfile.add_unit_column(name="source_unit_index", description="Original unit column in siteData{3} (1-based)")
        nwbfile.add_unit_column(name="spike_time_policy", description="How spike times were transformed for NWB")
        # Spike times are derived from millisecond-scale source timestamps.
        # Set resolution once the units table exists.
        nwbfile.units.resolution = 1e-3
        for unit_idx in range(1, n_units_total):
            local_unit = unit_idx
            if include_local_units is not None and local_unit not in include_local_units:
                continue
            unit_spikes: List[np.ndarray] = []
            policy = f"trial_anchor_seconds_from_trial_index_spacing_{trial_spacing_seconds:g}s"
            for tr in range(n_trials):
                cell = spikes[tr, unit_idx]
                st = _extract_spike_times(cell)
                if st.size > 0:
                    st = np.sort(st)
                    # Preserve within-trial timing while anchoring each trial into
                    # a monotonic absolute timeline for NWB validation.
                    trial_anchor = float(tr) * trial_spacing_seconds
                    unit_spikes.append((st / 1000.0) + trial_anchor)
            if unit_spikes:
                all_spikes = np.concatenate(unit_spikes)
                all_spikes = np.sort(all_spikes)
            else:
                all_spikes = np.array([], dtype=float)
                policy += ";no_spikes"
            nwbfile.add_unit(
                spike_times=all_spikes,
                source_unit_index=unit_idx + 1,
                spike_time_policy=policy,
            )
            units_written += 1

    output_dir.mkdir(parents=True, exist_ok=True)
    out_name = f"sub-{monkey}_ses-{session_idx:03d}_ecephys.nwb"
    out_path = output_dir / out_name
    with NWBHDF5IO(str(out_path), "w") as io:
        io.write(nwbfile)

    stats = {
        "n_trials": int(n_trials),
        "n_units": int(n_single_units),
        "n_units_written": int(units_written),
        "units_with_nonnegative_shift": int(unit_min_shift_applied),
        "had_no_single_units": bool(n_units_total <= 1),
        "manuscript_filtered": bool(include_local_units is not None),
    }
    return out_path, stats


def iter_session_files(data_root: Path, monkeys: Iterable[str]) -> Iterable[Tuple[str, Path]]:
    for monkey in monkeys:
        d = data_root / monkey / "LC" / "clean"
        if not d.exists():
            continue
        for f in sorted(d.glob("*.mat")):
            yield monkey, f


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert MAT sessions to NWB files")
    parser.add_argument("--repo-root", type=Path, default=None, help="Repository root (default: auto-detect)")
    parser.add_argument("--output-dir", type=Path, required=True, help="Directory for output NWB files")
    parser.add_argument("--max-files", type=int, default=0, help="Convert at most N files (0 = all)")
    parser.add_argument("--manifest", type=Path, default=None, help="Path to write conversion manifest JSON")
    parser.add_argument("--skip-existing", action="store_true", help="Skip writing files that already exist in output-dir")
    parser.add_argument("--manuscript-filter", action="store_true", help="Restrict conversion to manuscript include lists from CSV files")
    parser.add_argument("--session-include-csv", type=Path, default=Path("Code/dandi_tools/manuscript_session_include.csv"), help="CSV with monkey,session_file include list")
    parser.add_argument("--unit-include-csv", type=Path, default=Path("Code/dandi_tools/manuscript_unit_include.csv"), help="CSV with monkey,session_file,unit include list")
    args = parser.parse_args()

    repo_root = args.repo_root or find_repo_root(Path(__file__).resolve())
    code_dir = repo_root / "Code"
    data_root = parse_data_root_from_config(code_dir / "config_paths.m")

    monkeys = ["Oz", "Cicero"]
    converted = []
    failures = []

    include_sessions = None
    include_units = None
    if args.manuscript_filter:
        sess_csv = args.session_include_csv
        unit_csv = args.unit_include_csv
        if not sess_csv.is_absolute():
            sess_csv = repo_root / sess_csv
        if not unit_csv.is_absolute():
            unit_csv = repo_root / unit_csv
        if not sess_csv.exists() or not unit_csv.exists():
            raise FileNotFoundError("Manuscript filter requested but include CSVs are missing")
        include_sessions, include_units = _load_manuscript_includes(sess_csv, unit_csv)

    for idx, (monkey, mat_path) in enumerate(iter_session_files(data_root, monkeys), start=1):
        key = (monkey, mat_path.name)
        if include_sessions is not None and key not in include_sessions:
            continue
        if args.max_files and len(converted) >= args.max_files:
            break
        try:
            out_name = f"sub-{monkey}_ses-{idx:03d}_ecephys.nwb"
            out_path = args.output_dir / out_name
            if args.skip_existing and out_path.exists():
                print(f"[SKIP] {out_name} already exists")
                continue
            out_path, stats = build_nwb_for_session(
                mat_path=mat_path,
                monkey=monkey,
                session_idx=idx,
                output_dir=args.output_dir,
                include_local_units=(include_units.get(key, set()) if include_units is not None else None),
            )
            converted.append(
                {
                    "monkey": monkey,
                    "input": str(mat_path),
                    "output": str(out_path),
                    **stats,
                }
            )
            print(f"[OK] {mat_path.name} -> {out_path.name}")
        except Exception as exc:  # pragma: no cover
            failures.append({"monkey": monkey, "input": str(mat_path), "error": str(exc)})
            print(f"[FAIL] {mat_path}: {exc}")

    manifest = {
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "repo_root": str(repo_root),
        "data_root": str(data_root),
        "converted": converted,
        "failures": failures,
    }
    manifest_path = args.manifest or (args.output_dir / "conversion_manifest.json")
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    print(f"Converted files: {len(converted)}")
    print(f"Failed files: {len(failures)}")
    print(f"Manifest: {manifest_path}")
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
