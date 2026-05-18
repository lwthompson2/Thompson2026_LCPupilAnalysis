Code/ README — Reproduce paper figures

Quick start

- Copy `Code/config_paths_example.m` to `Code/config_paths.m` and edit `paths.data_root` to point to your Box data root.
- In MATLAB, run the data-prep and summary steps (example order):

  1) Open MATLAB and set the working directory to the repo root.
  2) Run `Code/Updated/getData.m` to load/prepare `LC_Beep_data`, `LC_Fix_data`, and tables.
  3) Run `Code/Updated/getUnitSummary.m` to compute `stats` (per-unit table).
  4) Run figure wrappers in `Code/PaperFigures/` to generate the paper PDFs. Example:

     fig = Code.PaperFigures.Figure_01_population();

Notes
- Figure wrappers in `Code/PaperFigures/` are thin wrappers around existing scripts in `Code/Updated/` and will call those scripts (they assume variables are present in the workspace).
- Use `Code/helpers/export_settings.m` and `Code/helpers/save_figure.m` to centralize export options.
- Keep originals in `Code/Updated/` — new wrappers and helpers live in `Code/PaperFigures/` and `Code/helpers/` respectively.
