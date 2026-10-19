#!/usr/bin/env python3
"""Audit MAT->NWB parity for manuscript sessions.

This checks whether NWB files preserve the source data needed for downstream
analysis by comparing deterministic session content between MAT and NWB:
- trial table fields (correct, beep time, trial time index, stimulation marker)
- flattened pupil value channel 4
- per-unit anchored spike times (exact transform used in conversion)

The script exits non-zero if any session fails parity checks.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

import numpy as np
from pynwb import NWBHDF5IO
from scipy.io import loadmat


@dataclass(frozen=True)
class SessionKey:
    monkey: str
    session_file: str


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


def load_manuscript_filters(session_csv: Path, unit_csv: Path) -> Tuple[set[SessionKey], Dict[SessionKey, set[int]]]:
    include_sessions: set[SessionKey] = set()
    include_units: Dict[SessionKey, set[int]] = {}

    with session_csv.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            key = SessionKey(monkey=row["monkey"], session_file=row["session_file"])
            include_sessions.add(key)

    with unit_csv.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            key = SessionKey(monkey=row["monkey"], session_file=row["session_file"])
            include_units.setdefault(key, set()).add(int(float(row["unit"])))

    return include_sessions, include_units


def iter_mat_sessions(data_root: Path, monkeys: Sequence[str]) -> Iterable[Tuple[str, Path]]:
    for monkey in monkeys:
        clean_dir = data_root / monkey / "LC" / "clean"
        if not clean_dir.exists():
            continue
        for mat_file in sorted(clean_dir.glob("*.mat")):
            yield monkey, mat_file


def extract_spike_times(cell_value) -> np.ndarray:
    arr = np.asarray(cell_value)
    if arr.size == 0:
        return np.array([], dtype=float)
    flat = np.ravel(arr).astype(float)
    return flat[np.isfinite(flat)]


def build_expected_from_mat(mat_path: Path, included_local_units: Optional[set[int]]) -> dict:
    data = loadmat(str(mat_path), squeeze_me=False, struct_as_record=False)
    if "siteData" not in data:
        raise RuntimeError(f"siteData missing in {mat_path}")

    flat_cells = np.ravel(data["siteData"])
    if flat_cells.size < 3:
        raise RuntimeError(f"Unexpected siteData format in {mat_path}")

    trial_meta = np.asarray(flat_cells[0], dtype=float)
    pupil = np.asarray(flat_cells[1], dtype=float)
    spikes = np.asarray(flat_cells[2], dtype=object)

    if trial_meta.ndim != 2 or trial_meta.shape[1] < 9:
        raise RuntimeError(f"trial_meta malformed in {mat_path}")

    n_trials = int(trial_meta.shape[0])

    stim_markers = trial_meta[:, 8] if trial_meta.shape[1] >= 9 else np.array([])
    include_stim_col = bool(np.any(np.isfinite(stim_markers)))

    trials = {
        "correct": trial_meta[:, 2].astype(float),
        "beep_time_ms": trial_meta[:, 3].astype(float),
        "trial_time_index": trial_meta[:, 6].astype(float),
        "stimulation_marker": trial_meta[:, 8].astype(float) if include_stim_col else None,
    }

    pupil_flat = None
    if pupil.ndim == 3 and pupil.shape[2] >= 4:
        pupil_flat = np.asarray(pupil[:, :, 3], dtype=float).reshape(-1)

    n_units_total = spikes.shape[1] if spikes.ndim == 2 else 0
    units: Dict[int, np.ndarray] = {}
    for unit_idx in range(1, n_units_total):
        local_unit = unit_idx
        if included_local_units is not None and local_unit not in included_local_units:
            continue

        unit_spikes: List[np.ndarray] = []
        for tr in range(n_trials):
            st = extract_spike_times(spikes[tr, unit_idx])
            if st.size > 0:
                st = np.sort(st)
                unit_spikes.append((st / 1000.0) + float(tr))

        if unit_spikes:
            all_spikes = np.sort(np.concatenate(unit_spikes))
            if all_spikes.size > 0 and all_spikes[0] < 0:
                all_spikes = all_spikes - all_spikes[0]
        else:
            all_spikes = np.array([], dtype=float)

        # NWB stores source_unit_index as 1-based MATLAB column index.
        source_unit_index = unit_idx + 1
        units[source_unit_index] = all_spikes

    return {
        "n_trials": n_trials,
        "trials": trials,
        "pupil_flat": pupil_flat,
        "units": units,
    }


def values_equal(a: np.ndarray, b: np.ndarray, atol: float = 1e-12) -> bool:
    if a.shape != b.shape:
        return False
    return np.array_equal(np.isnan(a), np.isnan(b)) and np.allclose(a, b, atol=atol, rtol=0.0, equal_nan=True)


def build_nwb_index(dandiset_dir: Path) -> Dict[Tuple[str, str], Path]:
    index: Dict[Tuple[str, str], Path] = {}
    for nwb_path in sorted(dandiset_dir.rglob("*.nwb")):
        with NWBHDF5IO(str(nwb_path), "r", load_namespaces=True) as io:
            nwb = io.read()
            subj = str(nwb.subject.subject_id)
            sess = str(nwb.session_id)
            index[(subj, sess)] = nwb_path
    return index


def compare_session(expected: dict, nwb_path: Path) -> Tuple[bool, List[str]]:
    errors: List[str] = []

    with NWBHDF5IO(str(nwb_path), "r", load_namespaces=True) as io:
        nwb = io.read()

        # Trial count and columns
        nwb_trials = nwb.trials.to_dataframe()
        if len(nwb_trials) != expected["n_trials"]:
            errors.append(f"trial count mismatch: MAT={expected['n_trials']} NWB={len(nwb_trials)}")

        for col in ["correct", "beep_time_ms", "trial_time_index"]:
            if col not in nwb_trials.columns:
                errors.append(f"missing NWB trial column: {col}")
                continue
            mat_arr = expected["trials"][col]
            nwb_arr = nwb_trials[col].to_numpy(dtype=float)
            if not values_equal(mat_arr, nwb_arr):
                errors.append(f"trial column mismatch: {col}")

        mat_stim = expected["trials"]["stimulation_marker"]
        has_nwb_stim = "stimulation_marker" in nwb_trials.columns
        if mat_stim is None and has_nwb_stim:
            errors.append("unexpected NWB stimulation_marker column")
        if mat_stim is not None:
            if not has_nwb_stim:
                errors.append("missing NWB stimulation_marker column")
            else:
                nwb_stim = nwb_trials["stimulation_marker"].to_numpy(dtype=float)
                if not values_equal(mat_stim, nwb_stim):
                    errors.append("trial column mismatch: stimulation_marker")

        # Pupil flattened channel
        mat_pupil = expected["pupil_flat"]
        has_nwb_pupil = "pupil_value_channel4" in nwb.acquisition
        if mat_pupil is None and has_nwb_pupil:
            errors.append("unexpected NWB pupil_value_channel4 acquisition")
        if mat_pupil is not None:
            if not has_nwb_pupil:
                errors.append("missing NWB pupil_value_channel4 acquisition")
            else:
                nwb_pupil = np.asarray(nwb.acquisition["pupil_value_channel4"].data[:], dtype=float)
                if not values_equal(mat_pupil, nwb_pupil):
                    errors.append("pupil flattened data mismatch")

        # Units + spike times
        mat_units: Dict[int, np.ndarray] = expected["units"]
        nwb_units_df = nwb.units.to_dataframe() if nwb.units is not None else None
        if nwb_units_df is None:
            if mat_units:
                errors.append("missing NWB units table")
        else:
            if "source_unit_index" not in nwb_units_df.columns:
                errors.append("missing NWB units.source_unit_index column")
            else:
                nwb_by_src: Dict[int, np.ndarray] = {}
                for _, row in nwb_units_df.iterrows():
                    src_idx = int(row["source_unit_index"])
                    st = np.asarray(row["spike_times"], dtype=float)
                    nwb_by_src[src_idx] = st

                if set(mat_units.keys()) != set(nwb_by_src.keys()):
                    errors.append(
                        "unit index set mismatch: "
                        f"MAT={sorted(mat_units.keys())} NWB={sorted(nwb_by_src.keys())}"
                    )
                else:
                    for src_idx, mat_spikes in mat_units.items():
                        nwb_spikes = nwb_by_src[src_idx]
                        if not values_equal(mat_spikes, nwb_spikes):
                            errors.append(f"spike_times mismatch for source_unit_index={src_idx}")

    return len(errors) == 0, errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit MAT and NWB parity for manuscript sessions")
    parser.add_argument("--repo-root", type=Path, default=None, help="Repository root (default: auto-detect)")
    parser.add_argument("--dandiset-dir", type=Path, default=Path("002034"), help="Local dandiset folder containing NWB files")
    parser.add_argument("--session-include-csv", type=Path, default=Path("Code/dandi_tools/manuscript_session_include.csv"))
    parser.add_argument("--unit-include-csv", type=Path, default=Path("Code/dandi_tools/manuscript_unit_include.csv"))
    parser.add_argument("--report", type=Path, default=Path("Code/Results/mat_nwb_audit_report.json"))
    args = parser.parse_args()

    repo_root = args.repo_root or find_repo_root(Path(__file__).resolve())
    code_dir = repo_root / "Code"
    data_root = parse_data_root_from_config(code_dir / "config_paths.m")

    dandiset_dir = args.dandiset_dir if args.dandiset_dir.is_absolute() else (repo_root / args.dandiset_dir)
    if not dandiset_dir.exists():
        raise FileNotFoundError(f"Dandiset directory not found: {dandiset_dir}")

    sess_csv = args.session_include_csv if args.session_include_csv.is_absolute() else (repo_root / args.session_include_csv)
    unit_csv = args.unit_include_csv if args.unit_include_csv.is_absolute() else (repo_root / args.unit_include_csv)
    include_sessions, include_units = load_manuscript_filters(sess_csv, unit_csv)

    nwb_index = build_nwb_index(dandiset_dir)

    sessions_tested = 0
    sessions_passed = 0
    failures: List[dict] = []

    for monkey, mat_path in iter_mat_sessions(data_root, ["Oz", "Cicero"]):
        key = SessionKey(monkey=monkey, session_file=mat_path.name)
        if key not in include_sessions:
            continue

        nwb_key = (monkey, mat_path.stem)
        nwb_path = nwb_index.get(nwb_key)
        if nwb_path is None:
            failures.append(
                {
                    "monkey": monkey,
                    "session_file": mat_path.name,
                    "session_id": mat_path.stem,
                    "errors": ["NWB file not found for (subject_id, session_id)"]
                }
            )
            sessions_tested += 1
            continue

        expected = build_expected_from_mat(mat_path, include_units.get(key, set()))
        ok, errs = compare_session(expected, nwb_path)
        sessions_tested += 1
        if ok:
            sessions_passed += 1
        else:
            failures.append(
                {
                    "monkey": monkey,
                    "session_file": mat_path.name,
                    "session_id": mat_path.stem,
                    "nwb_path": str(nwb_path),
                    "errors": errs,
                }
            )

    report = {
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "repo_root": str(repo_root),
        "data_root": str(data_root),
        "dandiset_dir": str(dandiset_dir),
        "sessions_tested": sessions_tested,
        "sessions_passed": sessions_passed,
        "sessions_failed": len(failures),
        "pass_rate": (sessions_passed / sessions_tested) if sessions_tested else math.nan,
        "failures": failures,
    }

    report_path = args.report if args.report.is_absolute() else (repo_root / args.report)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")

    print(f"Sessions tested: {sessions_tested}")
    print(f"Sessions passed: {sessions_passed}")
    print(f"Sessions failed: {len(failures)}")
    print(f"Report: {report_path}")

    return 0 if len(failures) == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
