LCPupil Joshi Analysis: Reproducibility Guide

This repository generates the manuscript figure/statistics outputs from cleaned LC-pupil session files.

Core regeneration workflow

1. Copy [Code/config_paths_example.m](config_paths_example.m) to [Code/config_paths.m](config_paths.m).
2. Edit `paths.data_root` in [Code/config_paths.m](config_paths.m) so it points to the cleaned dataset root.
3. Keep defaults for `paths.output_figures` and `paths.results_dir` unless you need custom output locations.
4. Run [Code/main.m](main.m) from MATLAB (or `matlab -batch`).
5. Regenerate publication table from cached LOOCV metrics (automatic in `main`):
  - [Code/Results/Figure2_CV_publication_table_superheader_loocv.xlsx](Results/Figure2_CV_publication_table_superheader_loocv.xlsx)
6. Verify generated outputs in:
  - [Code/Results](Results/)
  - [Code/Figures/Paper](Figures/Paper/)

Command-line regeneration example

1. From repository root:
  - `/Applications/MATLAB_R2023b.app/bin/matlab -batch "cd('Code'); addpath(genpath(pwd)); main;"`

Current publication CV profile in main

- Method: LOOCV
- Permutations: 100
- Output tag: loocv
- Publication table export: automatic after CV run

Publication-grade CV rerun profile

- Method: LOOCV
- Permutations: 1000 (or higher)
- Output tag: loocv_final
- Run this profile only when generating final paper numbers.

Expected primary outputs

- [Code/Results/LC_data_raw.mat](Results/LC_data_raw.mat)
- [Code/Results/LC_data_zscored.mat](Results/LC_data_zscored.mat)
- [Code/Results/Figure2_cv_metrics_loocv_final.mat](Results/Figure2_cv_metrics_loocv_final.mat)
- [Code/Results/Figure2_cv_metrics_loocv_final.csv](Results/Figure2_cv_metrics_loocv_final.csv)
- [Code/Results/Figure2_CV_publication_table_superheader_loocv_final.xlsx](Results/Figure2_CV_publication_table_superheader_loocv_final.xlsx)
- [Code/Figures/Paper/Figure_S5_Figure2_CV_summary_loocv_final.pdf](Figures/Paper/Figure_S5_Figure2_CV_summary_loocv_final.pdf)
- [Code/Figures/Paper/Figure_S5b_Figure2_CV_R2_summary_loocv_final.pdf](Figures/Paper/Figure_S5b_Figure2_CV_R2_summary_loocv_final.pdf)

Publication reproducibility audit summary

Status: runnable now for the active pipeline and substantially cleaned for external users.

High-priority blockers

1. Final source release should avoid shipping generated artifacts from:
  - [Code/Results](Results/)
  - [Code/Figures/Paper](Figures/Paper/)
2. Ensure local [Code/config_paths.m](config_paths.m) is not committed in release snapshots.

Folder roles (important)

1. [Code/PaperFigures](PaperFigures/): source code that generates manuscript/supplement figures.
2. [Code/Figures/Paper](Figures/Paper/): generated outputs from the code pipeline (build artifacts).
3. [Figures/Paper/Submitted](../Figures/Paper/Submitted/) and [Figures/Paper/Revised](../Figures/Paper/Revised/): curated manuscript deliverables.

Recommended keep list for a publication release

- Entrypoints and core pipeline:
  - [Code/main.m](main.m)
  - [Code/compute_manuscript_stats.m](compute_manuscript_stats.m)
  - [Code/run_figure2_cv_analysis.m](run_figure2_cv_analysis.m)
  - [Code/print_figure2_cv_table.m](print_figure2_cv_table.m)
  - [Code/make_all_figures.m](make_all_figures.m)
- Core helpers in [Code/helpers](helpers/)
- Active figure wrappers in [Code/PaperFigures](PaperFigures/)

Recommended remove or archive list before publication release

1. Any temporary inspection directories under [Code/Results](Results/)
2. Non-LOOCV comparative outputs not used in final manuscript reporting

Minimal data package required to reproduce results

To reproduce from source, external users need cleaned per-session MAT files with the structure expected by [Code/helpers/process_site_file.m](helpers/process_site_file.m).

Directory layout

1. Data root configured in [Code/config_paths.m](config_paths.m) as paths.data_root.
2. Under data root, per-monkey cleaned LC files in:
  - data_root/Oz/LC/clean/*.mat
  - data_root/Cicero/LC/clean/*.mat

Required content inside each MAT file

1. Variable named siteData.
2. siteData must be a cell array with at least 3 elements.
3. siteData element requirements:
  - siteData{1}: trial metadata matrix, with columns used by pipeline:
    - col 2: fixation/trial end time (used for fixation baseline rate)
    - col 3: trial correctness flag
    - col 4: beep time
    - col 7: trial time index
    - col 9: stimulation marker
  - siteData{2}: pupil signal array where a trial pupil vector can be extracted for field index 4.
  - siteData{3}: trial-by-unit spike-time cell array where rows are trials and columns are units (column 1 may be non-single-unit metadata; code reads columns 2:end).

Optional but strongly recommended files in data package

1. dataset_manifest.csv: one row per session file with monkey, session filename, trial counts, unit counts.
2. checksums_sha256.txt: checksum of every MAT file.
3. data_dictionary.md: concise explanation of siteData columns and units.

Where to upload the minimal data package for free

Recommended primary host (best for publication reproducibility)

1. Zenodo
2. Why: free, stable DOI minting, strong citation workflow, good for frozen publication snapshots.
3. Best use here: upload versioned ZIP archives of cleaned MAT files plus manifest/checksums.

Recommended companion host (best for collaboration)

1. OSF (Open Science Framework)
2. Why: free project storage, easy team permissions, supports mirrors/links to external resources.
3. Best use here: host a project landing page and mirror the same release package.

Also viable if dataset is large

1. Figshare free tier: good discoverability, but free storage limits may be restrictive for large MAT datasets.
2. Dryad: widely used in publishing but often not free for all journals/users.
3. Institutional repository: often free for affiliated labs and may satisfy long-term retention rules.

Recommended deployment pattern for this repository

1. Put the canonical frozen data package on Zenodo and mint a DOI.
2. Mirror or link the same package from OSF.
3. Keep a lightweight sample dataset in-repo only if needed for smoke tests.
4. In [Code/config_paths_example.m](config_paths_example.m), document the expected post-download folder layout.
5. In this README, include:
  - DOI URL
  - version tag mapping (code release tag <-> data DOI version)
  - checksum file location

What users need to run code after downloading data

1. Unzip data to a local folder.
2. Ensure this structure exists:
  - `<data_root>/Oz/LC/clean/*.mat`
  - `<data_root>/Cicero/LC/clean/*.mat`
3. Set `paths.data_root` in [Code/config_paths.m](config_paths.m).
4. Run [Code/main.m](main.m).

MATLAB path note

1. Helper functions are added via `addpath(genpath(pwd))` and are called by function name (example: `load_site_list()`), not as package-qualified names (for example, not `helpers.load_site_list()`).

Practical strategy

1. Upload a frozen release data package to Zenodo and mint a DOI.
2. Mirror the same package on OSF.
3. Put DOI and checksum file location in this README and manuscript methods.
4. Tag source code release in git to match the DOI version.

Suggested release artifacts

1. Source release archive (code only).
2. Data release archive (minimal cleaned MAT dataset + manifest + checksums).
3. Optional outputs archive (precomputed Results and PDFs for quick inspection).

Quick start for external users

1. Clone repository.
2. Install MATLAB R2023b or compatible release with required toolboxes used by fitlm, fitlme, and signrank.
3. Set data_root in [Code/config_paths.m](config_paths.m) to the unpacked minimal data package.
4. Run [Code/main.m](main.m).
5. Confirm expected output files listed above are generated.

Notes on runtime

1. LOOCV with 100 permutations is suitable for routine reproducibility checks.
2. LOOCV with 1000+ permutations is computationally expensive and may take many hours.
3. The publication table is generated from saved CV metrics and does not require rerunning CV once metrics exist.

Immediate pre-publication cleanup checklist

1. Confirm `.gitignore` excludes generated outputs and local configs.
2. Re-run [Code/main.m](main.m) on a clean clone and verify expected outputs.
3. For final release numbers, run the publication-grade LOOCV profile and archive tagged outputs.
