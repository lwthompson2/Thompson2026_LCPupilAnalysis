function fig = Figure_S1_combined(paths)
% Figure_S1_combined  Produce Supplemental Figure S1 baseline-value analysis.

if nargin < 1 || isempty(paths)
    if exist('config_paths.m','file')
        paths = config_paths();
    else
        paths = config_paths_example();
    end
end

fig = [];
try
    compute_data(paths);
    results_dir = paths.results_dir;

    raw_mat = fullfile(results_dir, 'LC_data_raw.mat');
    z_mat = fullfile(results_dir, 'LC_data_zscored.mat');
    if ~exist(raw_mat,'file')
        error('Raw cache not found: %s', raw_mat);
    end
    if ~exist(z_mat,'file')
        error('Z-scored cache not found: %s', z_mat);
    end

    s_raw = load(raw_mat);
    s_z = load(z_mat);

    [beep_raw, fix_raw, stats_raw] = prepare_figure_analysis_tables( ...
        s_raw.LC_Beep_table, s_raw.LC_Fix_table, 'baseline');
    [beep_z, fix_z, stats_z] = prepare_figure_analysis_tables( ...
        s_z.LC_Beep_table, s_z.LC_Fix_table, 'baseline');

    fig = plot_S1_combined(beep_raw, fix_raw, stats_raw, beep_z, fix_z, stats_z);
catch ME
    if ~isempty(fig) && isgraphics(fig)
        close(fig);
    end
    rethrow(ME);
end

outdir = paths.output_figures;
if ~exist(outdir,'dir')
    mkdir(outdir);
end
outpath = fullfile(outdir, 'Figure_S1_combined.pdf');

set(fig, 'PaperUnits', 'inches', ...
         'PaperSize',     [17.9483 11.2000], ...
         'PaperPosition', [0 0 17.9483 11.2000]);
print(fig, outpath, '-dpdf', '-painters');
end
