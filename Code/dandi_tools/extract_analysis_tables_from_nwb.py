#!/usr/bin/env python3
"""Build analysis-ready beep/fix tables from NWB files.

This reproduces the same per-unit/per-trial extraction logic used by
Code/helpers/process_site_file.m so downstream MATLAB analysis can run
against DANDI NWB content.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path
from typing import Dict, List, Tuple

import numpy as np
from pynwb import NWBHDF5IO


def _safe_float(x) -> float:
    try:
        return float(x)
    except Exception:
        return float("nan")


def _zscore(vec: np.ndarray) -> np.ndarray:
    out = np.full(vec.shape, np.nan, dtype=float)
    mask = np.isfinite(vec)
    if np.sum(mask) == 0:
        return out
    vals = vec[mask]
    mu = np.mean(vals)
    sd = np.std(vals, ddof=1)
    if not np.isfinite(sd) or sd == 0:
        out[mask] = 0.0
    else:
        out[mask] = (vals - mu) / sd
    return out


def _fit_residuals(times: np.ndarray, values: np.ndarray) -> np.ndarray:
    # Linear residuals y - (a*x + b), matching fitlm baseline behavior.
    out = np.full(values.shape, np.nan, dtype=float)
    mask = np.isfinite(times) & np.isfinite(values)
    if np.sum(mask) < 2:
        return out
    x = times[mask]
    y = values[mask]
    A = np.vstack([x, np.ones_like(x)]).T
    try:
        coeff, *_ = np.linalg.lstsq(A, y, rcond=None)
        pred = A @ coeff
        out_mask = y - pred
        out[mask] = out_mask
    except Exception:
        pass
    return out


def _movmean_omitnan(x: np.ndarray, window: int) -> np.ndarray:
    # Centered moving mean with truncated edge windows, ignoring NaNs.
    n = x.size
    out = np.full(n, np.nan, dtype=float)
    if n == 0:
        return out
    left = (window - 1) // 2
    right = window - left - 1
    for i in range(n):
        lo = max(0, i - left)
        hi = min(n, i + right + 1)
        seg = x[lo:hi]
        valid = np.isfinite(seg)
        if np.any(valid):
            out[i] = float(np.mean(seg[valid]))
    return out


def process_nwb_file(nwb_path: Path) -> Tuple[List[Dict], List[Dict]]:
    times = np.array([[-100, 0], [0, 800], [-400, 0], [0, 200]], dtype=float)
    pupil_evoked_times = np.arange(times[1, 0], times[1, 1] + 1)

    beep_rows: List[Dict] = []
    fix_rows: List[Dict] = []

    with NWBHDF5IO(str(nwb_path), "r", load_namespaces=True) as io:
        nwb = io.read()

        monkey = str(nwb.subject.subject_id)
        session_file = f"{nwb.session_id}.mat"

        trials_df = nwb.trials.to_dataframe()
        n_trials = len(trials_df)

        # Recover trial metadata fields used by the MATLAB pipeline.
        correct = trials_df["correct"].to_numpy(dtype=float) if "correct" in trials_df else np.full(n_trials, np.nan)
        beep_ms = trials_df["beep_time_ms"].to_numpy(dtype=float) if "beep_time_ms" in trials_df else np.full(n_trials, np.nan)
        trial_time_idx = (
            trials_df["trial_time_index"].to_numpy(dtype=float)
            if "trial_time_index" in trials_df
            else np.full(n_trials, np.nan)
        )
        stim = (
            trials_df["stimulation_marker"].to_numpy(dtype=float)
            if "stimulation_marker" in trials_df
            else np.full(n_trials, np.nan)
        )

        # Col2 equivalent can be recovered from stop-start in seconds.
        start_t = trials_df["start_time"].to_numpy(dtype=float)
        stop_t = trials_df["stop_time"].to_numpy(dtype=float)
        end_ms = (stop_t - start_t) * 1000.0

        # Reconstruct pupil trial matrix from flattened storage.
        if "pupil_value_channel4" not in nwb.acquisition:
            return beep_rows, fix_rows
        pupil_flat = np.asarray(nwb.acquisition["pupil_value_channel4"].data[:], dtype=float)
        if n_trials == 0 or pupil_flat.size % n_trials != 0:
            return beep_rows, fix_rows
        ncol = pupil_flat.size // n_trials
        pupil_mat = pupil_flat.reshape((n_trials, ncol))

        # Legacy trial selection criteria.
        fbeep = np.where((correct == 1) & (beep_ms > abs(np.min(times[:, 0]))) & (beep_ms < (ncol - np.max(times[:, 1]))))[0]
        ffix = np.where((correct == 1) & np.isnan(beep_ms) & np.isnan(stim))[0]

        if len(fbeep) == 0 and len(ffix) == 0:
            return beep_rows, fix_rows

        if nwb.units is None:
            return beep_rows, fix_rows

        units_df = nwb.units.to_dataframe()
        if "source_unit_index" not in units_df.columns:
            return beep_rows, fix_rows

        # Process units in source unit order to preserve deterministic IDs.
        units_df = units_df.sort_values("source_unit_index")

        for _, urow in units_df.iterrows():
            source_unit_index = int(urow["source_unit_index"])
            local_unit = source_unit_index - 1
            spike_times = np.asarray(urow["spike_times"], dtype=float)

            nb = len(fbeep)
            nf = len(ffix)
            pupil_data = np.full((nb, 2), np.nan, dtype=float)
            pupil_fix_data = np.full(nf, np.nan, dtype=float)
            spike_data = np.full((nb, 2), np.nan, dtype=float)
            spike_fix_data = np.full(nf, np.nan, dtype=float)
            trial_times = np.full(nb, np.nan, dtype=float)
            trial_fix_times = np.full(nf, np.nan, dtype=float)
            baseline_times = np.full(nb, np.nan, dtype=float)

            # Beep trials.
            for i, tr in enumerate(fbeep):
                bt = int(tr)
                trial_anchor = float(start_t[bt])
                bt_ms = beep_ms[bt]
                trial_times[i] = trial_time_idx[bt]
                bi = int(round(bt_ms))

                pd = pupil_mat[bt, :]
                bi_idx = min(len(pd), bi + 1)
                if bi_idx >= 1:
                    pupil_data[i, 0] = np.nanmean(pd[:bi_idx])

                ev_idx = (bi + pupil_evoked_times).astype(int)
                ev_idx = ev_idx[(ev_idx >= 0) & (ev_idx < len(pd))]
                if ev_idx.size > 0 and np.isfinite(pupil_data[i, 0]):
                    ev = pd[ev_idx] - pupil_data[i, 0]
                    if ev.size > 0:
                        sm = _movmean_omitnan(ev, 50)
                        max_ev = np.nanmax(sm)
                        min_ev = np.nanmin(sm)
                        pupil_data[i, 1] = max_ev if abs(max_ev) > abs(min_ev) else min_ev

                # Spikes for this trial computed from anchored absolute times.
                baseline_count = np.sum((spike_times >= trial_anchor) & (spike_times < trial_anchor + (bt_ms / 1000.0)))
                evoked_count = np.sum(
                    (spike_times >= trial_anchor + ((bt_ms + times[3, 0]) / 1000.0))
                    & (spike_times <= trial_anchor + ((bt_ms + times[3, 1]) / 1000.0))
                )
                spike_data[i, 0] = baseline_count
                spike_data[i, 1] = evoked_count
                baseline_times[i] = bt_ms

            # Fix trials.
            for i, tr in enumerate(ffix):
                ft = int(tr)
                trial_anchor = float(start_t[ft])
                t_end = end_ms[ft]
                trial_fix_times[i] = trial_time_idx[ft]

                pd = pupil_mat[ft, :]
                fix_times = np.arange(0, int(round(t_end)) + 1)
                idx = fix_times[(fix_times >= 0) & (fix_times < len(pd))]
                if idx.size > 0:
                    pupil_fix_data[i] = np.nanmean(pd[idx])

                baseline_count = np.sum(
                    (spike_times >= trial_anchor)
                    & (spike_times <= trial_anchor + (t_end / 1000.0))
                )
                spike_fix_data[i] = baseline_count

            # Convert counts to rates.
            spike_rate_baseline = np.full(nb, np.nan, dtype=float)
            spike_rate_evoked = np.full(nb, np.nan, dtype=float)
            spike_rate_fix = np.full(nf, np.nan, dtype=float)

            valid_base = (baseline_times > 0) & np.isfinite(spike_data[:, 0])
            spike_rate_baseline[valid_base] = spike_data[valid_base, 0] / baseline_times[valid_base] * 1000.0

            ev_dur = float(times[3, 1] - times[3, 0])
            valid_ev = np.isfinite(spike_data[:, 1])
            spike_rate_evoked[valid_ev] = spike_data[valid_ev, 1] / ev_dur * 1000.0

            for i, tr in enumerate(ffix):
                ft = int(tr)
                if np.isfinite(spike_fix_data[i]) and np.isfinite(end_ms[ft]) and end_ms[ft] > 0:
                    spike_rate_fix[i] = spike_fix_data[i] / end_ms[ft] * 1000.0

            # Legacy z-threshold filter on evoked z-score within unit.
            all_fr = np.concatenate([spike_rate_baseline, spike_rate_evoked, spike_rate_fix])
            all_fr_z = _zscore(all_fr)
            n_b = len(spike_rate_baseline)
            evoked_z = all_fr_z[n_b : 2 * n_b]

            lg = np.isfinite(spike_rate_baseline) & np.isfinite(pupil_data[:, 0]) & np.isfinite(pupil_data[:, 1]) & np.isfinite(evoked_z) & (np.abs(evoked_z) < 8)
            lg_fix = np.isfinite(spike_rate_fix) & np.isfinite(pupil_fix_data)

            # Baseline-subtract evoked firing rate.
            valid_ev2 = np.isfinite(spike_rate_evoked) & np.isfinite(spike_rate_baseline)
            spike_rate_evoked[valid_ev2] = spike_rate_evoked[valid_ev2] - spike_rate_baseline[valid_ev2]

            n_lg = int(np.sum(lg))
            n_lg_fix = int(np.sum(lg_fix))
            if n_lg == 0 and n_lg_fix == 0:
                continue

            all_times = np.concatenate([trial_times[lg], trial_fix_times[lg_fix]])
            all_pd = np.concatenate([pupil_data[lg, 0], pupil_fix_data[lg_fix]])
            all_fr2 = np.concatenate([spike_rate_baseline[lg], spike_rate_fix[lg_fix]])

            pd_res = _fit_residuals(all_times, all_pd)
            fr_res = _fit_residuals(all_times, all_fr2)

            # Beep rows.
            if n_lg > 0:
                b_pd_base = pupil_data[lg, 0]
                b_pd_ev = pupil_data[lg, 1]
                b_fr_base = spike_rate_baseline[lg]
                b_fr_ev = spike_rate_evoked[lg]
                b_tt = trial_times[lg]

                for i in range(n_lg):
                    beep_rows.append(
                        {
                            "monkey": monkey,
                            "session_file": session_file,
                            "unit": local_unit,
                            "trial_time": _safe_float(b_tt[i]),
                            "pupil_baseline": _safe_float(b_pd_base[i]),
                            "pupil_evoked": _safe_float(b_pd_ev[i]),
                            "spike_baseline": _safe_float(b_fr_base[i]),
                            "spike_evoked": _safe_float(b_fr_ev[i]),
                            "pupil_drift_residuals": _safe_float(pd_res[i]) if i < len(pd_res) else float("nan"),
                            "spike_drift_residuals": _safe_float(fr_res[i]) if i < len(fr_res) else float("nan"),
                            "raw_pupil_evoked": _safe_float(b_pd_base[i] + b_pd_ev[i]),
                            "raw_spike_evoked": _safe_float(b_fr_base[i] + b_fr_ev[i]),
                        }
                    )

            # Fix rows.
            if n_lg_fix > 0:
                f_pd = pupil_fix_data[lg_fix]
                f_fr = spike_rate_fix[lg_fix]
                f_tt = trial_fix_times[lg_fix]
                for i in range(n_lg_fix):
                    fix_rows.append(
                        {
                            "monkey": monkey,
                            "session_file": session_file,
                            "unit": local_unit,
                            "pupil_fix_baseline": _safe_float(f_pd[i]),
                            "spike_fix_baseline": _safe_float(f_fr[i]),
                            "trial_time": _safe_float(f_tt[i]),
                            "pupil_drift_residuals": _safe_float(pd_res[n_lg + i]) if (n_lg + i) < len(pd_res) else float("nan"),
                            "spike_drift_residuals": _safe_float(fr_res[n_lg + i]) if (n_lg + i) < len(fr_res) else float("nan"),
                        }
                    )

    return beep_rows, fix_rows


def write_csv(rows: List[Dict], out_path: Path, fieldnames: List[str]) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for row in rows:
            w.writerow(row)


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract analysis tables from NWB files")
    parser.add_argument("--nwb-root", type=Path, required=True, help="Root folder containing NWB files")
    parser.add_argument("--beep-csv", type=Path, required=True, help="Output CSV for beep table")
    parser.add_argument("--fix-csv", type=Path, required=True, help="Output CSV for fix table")
    args = parser.parse_args()

    nwb_files = sorted(args.nwb_root.rglob("*.nwb"))
    beep_rows_all: List[Dict] = []
    fix_rows_all: List[Dict] = []

    for nwb_path in nwb_files:
        b, f = process_nwb_file(nwb_path)
        beep_rows_all.extend(b)
        fix_rows_all.extend(f)

    beep_fields = [
        "monkey",
        "session_file",
        "unit",
        "trial_time",
        "pupil_baseline",
        "pupil_evoked",
        "spike_baseline",
        "spike_evoked",
        "pupil_drift_residuals",
        "spike_drift_residuals",
        "raw_pupil_evoked",
        "raw_spike_evoked",
    ]
    fix_fields = [
        "monkey",
        "session_file",
        "unit",
        "pupil_fix_baseline",
        "spike_fix_baseline",
        "trial_time",
        "pupil_drift_residuals",
        "spike_drift_residuals",
    ]

    write_csv(beep_rows_all, args.beep_csv, beep_fields)
    write_csv(fix_rows_all, args.fix_csv, fix_fields)

    print(f"NWB files processed: {len(nwb_files)}")
    print(f"Beep rows: {len(beep_rows_all)}")
    print(f"Fix rows: {len(fix_rows_all)}")
    print(f"Wrote: {args.beep_csv}")
    print(f"Wrote: {args.fix_csv}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
