function fig = Figure_S2_LLR(paths)
% Figure_S2_LLR  Produce Supplemental Figure 2 (LLR comparisons).

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
    % Figure S2 should use non z-scored firing-rate data for LLR model
    % comparison (legacy do_zscore=false workflow).
    [~, ~, stats_table] = prepare_figure_analysis_tables( ...
        s_raw.LC_Beep_table, s_raw.LC_Fix_table);
    if isempty(stats_table)
        error('Could not build stats table required for LLR figure.');
    end
    fig = plot_S2_LLR_new(stats_table);
catch ME
    if ~isempty(fig) && isgraphics(fig)
        close(fig);
    end
    rethrow(ME);
end

% Export
outdir = paths.output_figures;
if ~exist(outdir,'dir')
    mkdir(outdir);
end
outpath = fullfile(outdir, 'Figure_S2_LLR.pdf');
set(fig, 'PaperUnits', 'inches', ...
         'PaperSize',     [13.0302 4.6272], ...
         'PaperPosition', [0 0 13.0302 4.6272]);
print(fig, outpath, '-dpdf', '-painters');
end
