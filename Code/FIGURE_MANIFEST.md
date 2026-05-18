# Figure Manifest — provisional mapping

This file maps existing scripts in `Code/Updated/` to the manuscript figures/panels (provisional). It is intended to help reorganize figure-generation into `Code/PaperFigures/` functions like `Figure_01.m`.

Notes:
- All mappings are provisional and should be validated against the manuscript PDF/Word (`Manuscript/2025_Thompson_LC_Pupil_v5_wRefs.pdf`).
- Data dependencies: scripts expect precomputed tables/variables produced by `getData.m` (or `getData_slope.m`) and `getUnitSummary.m`. Data live externally (Box); see `config_paths.example.m` to point to your Box path.
- Output format: PDF, 7 in width, 300 DPI (as agreed).

## Provisional mappings (scripts in `Code/Updated/`)

- `getData.m` / `getData_slope.m`
  - Purpose: load and preprocess raw `.mat` data into workspace variables/tables (`LC_Beep_data`, `LC_Fix_data`, or tables `LC_Beep_table`, `LC_Fix_table`).
  - Dependency: MUST run before per-unit or population plotting scripts.

- `getLCP_cleanDataDir.m`
  - Purpose: helper to locate/collect clean data directories for animals.

- `getUnitSummary.m`
  - Purpose: iterates over units and calls `unitSummaryPlot` (and variants). Produces per-unit figures and a `stats` table.
  - Possible paper mapping: per-unit supplement figures or panels showing single-unit summary.
  - Candidate new file: `Code/PaperFigures/Figure_S_unitSummary.m` (supplemental).

- `unitSummaryPlot.m`, `unitSummaryPlot_slope.m`, `unitSummaryPlotRaw.m`
  - Purpose: create 3x4 tiled unit summary plots (baseline drift, residual relationships, linear/quadratic fits, etc.).
  - These are core per-unit plotting utilities called by `getUnitSummary.m` and should remain as helpers under `Code/helpers/`.

- `exampleNeuronPlots.m`
  - Purpose: create a multi-example tiled figure of example neurons across animals.
  - Candidate paper mapping: Figure 2 (example units) and Figure 1B (example session inset) → `Code/PaperFigures/Figure_02_examples.m` and `Code/PaperFigures/Figure_01_population.m` (panel B).

- `populationBaseEvoked.m`
  - Purpose: population-level scatter panels comparing baseline/residuals/evoked metrics across monkeys and units. Produces large multi-subplot figure.
  - Candidate paper mapping: Figure 2 (population summary column) and Figure 3 (pooled across-session comparisons) → `Code/PaperFigures/Figure_01_population.m` and `Code/PaperFigures/Figure_03_pooled.m`.

- `partialCorrDist.m`, `partialCorrDistRaw.m`, `FR_partialCorrDist.m`, `Pupil_partialCorrDist.m`
  - Purpose: create distribution/scatter summary plots of correlation/partial-correlation statistics across units (likely used for Figure panels showing R distributions).
  - Candidate mapping: panels in Figure 2 summary column, Figure 3 pooled comparisons, and supplemental statistic panels → `Code/PaperFigures/Figure_02_distributions.m` / `Figure_03_pooled.m`.

- `correlationsEvokedMag.m`, `correlationsVRange.m` (empty), `FR_partialCorrDist.m`
  - Purpose: checking relationships between evoked magnitude/range and correlations; produces scatterplots and LLR analyses.
  - Candidate mapping: methods/results supplementary figures.

- `getCorrelations.m`
  - Purpose: likely computes unit-level correlations and populates `stats` (investigate further).

- `Linear_v_Quadratic_LLR.m`
  - Purpose: runs linear vs quadratic model comparisons and plots subplots (1x4 layout). Candidate panel for Supplemental Figure 2 (LLR comparisons) → `Code/PaperFigures/Figure_S2_LLR.m`.

- `correlationsVRange.m` (empty)
  - Needs review — either remove or fill.

## Mapping derived from manuscript text

I parsed `Manuscript/2025_Thompson_LC_Pupil_v5_wRefs.pdf` and found explicit mentions of Figures 1–3 and Supplemental Figure 2. Based on the manuscript descriptions and the code in `Code/Updated/`, here's a provisional figure→script mapping to guide refactoring:

- Figure 1
  - 1A: schematic (inverted-U) — typically created in a vector editor (not produced by code).
  - 1B: example session showing pupil (top) and single-unit LC activity (bottom) and insets — likely produced from per-session/unit plotting code (`unitSummaryPlot.m` or `exampleNeuronPlots.m`).

- Figure 2
  - Four example units/sessions (first four columns) and a population summary (last column) — produced by `exampleNeuronPlots.m` (example columns) and `partialCorrDist.m` / `partialCorrDistRaw.m` / `populationBaseEvoked.m` for the summary column.

- Figure 3
  - Across-session (pooled) comparisons — produced by `populationBaseEvoked.m` and `partialCorrDist*.m` variants.

- Supplemental Figure 1
  - Raw baseline vs residual comparisons — `unitSummaryPlotRaw.m` (per-unit supplemental)

- Supplemental Figure 2
  - Log-likelihood ratio (LLR) comparisons of linear vs quadratic fits — `Linear_v_Quadratic_LLR.m` and `FR_partialCorrDist.m`.

These mappings are intentionally conservative — I'll update them after generating the first pass of each figure and comparing to the manuscript PDF images.


## Recommended next steps (short term)

1. Validate mappings against the manuscript figures (I will map precisely after reading the PDF).
2. Create `Code/PaperFigures/` and implement functions `Figure_01_population.m`, `Figure_02_distributions.m`, etc., each:
   - Accept a `paths` struct (points to data & output dirs) and `options` (recompute or use cached stats).
   - Call helpers in `Code/helpers/` (data loading, stats extraction, plotting helpers).
3. Add `Code/config_paths.example.m` and `Code/helpers/export_settings.m` to centralize export/format options.
4. Add small README at `Code/README.md` describing how to reproduce figures and the order: `getData` → `getUnitSummary` → `Code/PaperFigures/Figure_##.m`.

## Flags / Questions for validation
- Which manuscript figures correspond to: `populationBaseEvoked.m`, `partialCorrDist*.m`, `exampleNeuronPlots.m`, `Linear_v_Quadratic_LLR.m`? (I will map precisely after reading the PDF)
- Confirm whether supplemental per-unit PDF outputs from `getUnitSummary.m` should be kept in the repository or archived externally.

---
Created: provisional manifest for refactor work.
