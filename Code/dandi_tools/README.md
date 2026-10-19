DANDI NWB Conversion Tools

This folder contains scripts to convert the cleaned LC-pupil MAT files into NWB files and validate them for DANDI upload.

Quick start

1. Activate the Python environment.
2. Install dependencies:
   pip install -r Code/dandi_tools/requirements.txt
3. Pull your draft Dandiset locally:
   dandi download https://dandiarchive.org/dandiset/002034/draft
4. Convert MAT files to NWB directly inside the local Dandiset folder:
   python Code/dandi_tools/mat_to_nwb.py --output-dir 002034 --manuscript-filter
5. Run NWB Inspector with DANDI checks:
   nwbinspector --config dandi 002034
6. Run DANDI validator from inside the Dandiset root:
   dandi validate 002034
7. Upload when validation is clean:
   dandi upload 002034

Notes

- The converter expects source data at config_paths().data_root with layout:
  <data_root>/Oz/LC/clean/*.mat
  <data_root>/Cicero/LC/clean/*.mat
- Current converter writes one NWB file per input MAT session.
- Metadata currently written into NWB files:
   - experimenter: Siddhartha Joshi
   - institution: University of Pennsylvania
   - lab: Joshua Gold
   - subject species: Macaca mulatta
   - subject sex: M
   - subject age: placeholder P0D (source age is currently unknown)

Spike time policy

- Spike times are not suppressed.
- Raw per-trial spike times (ms) are converted to seconds and anchored by trial index (`+ trial_number_seconds`) to create a monotonic absolute session timeline.
- If a unit still has negative times after anchoring, a non-negative global shift is applied to that unit only; this is recorded in `spike_time_policy` and counted in the conversion manifest.

Validation expectations

- DANDI requires subject metadata fields in each NWB file: subject_id, species, sex, and age/date_of_birth.
- Only CRITICAL NWB Inspector issues block DANDI upload, but best-practice warnings should still be reviewed before publication.

Manuscript subset enforcement

- This repo can enforce conversion to only the manuscript subset (83 sessions, 105 units).
- Include lists are generated from the analysis cache and saved to:
   - Code/dandi_tools/manuscript_session_include.csv
   - Code/dandi_tools/manuscript_unit_include.csv
- To enforce this subset during conversion, add `--manuscript-filter`.
