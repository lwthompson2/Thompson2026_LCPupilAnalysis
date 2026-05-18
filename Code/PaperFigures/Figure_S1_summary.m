function fig = Figure_S1_summary(paths)
% Figure_S1_summary  Produce Supplemental Figure S1 (summary row only).
% Contains the 6 population-summary scatter panels using baseline values
% (equivalent to the top row of Figure_S1_combined).

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
    if ~exist(raw_mat,'file')
        error('Raw cache not found: %s', raw_mat);
    end

    s_raw = load(raw_mat);
    [beep_raw, fix_raw, ~] = prepare_figure_analysis_tables( ...
        s_raw.LC_Beep_table, s_raw.LC_Fix_table, 'baseline');

    fig = plot_S1_summary(beep_raw, fix_raw);
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
outpath = fullfile(outdir, 'Figure_S1_summary.pdf');
set(fig, 'PaperUnits', 'inches', ...
         'PaperSize',     [17.9483 3.6000], ...
         'PaperPosition', [0 0 17.9483 3.6000]);
print(fig, outpath, '-dpdf', '-painters');
end
