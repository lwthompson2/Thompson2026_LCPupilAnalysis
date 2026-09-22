function fig = Figure_S3_sig_baseline_subset(paths)
% Figure_S3_sig_baseline_subset  Summary-style subset analysis figure.
% Uses only units with significant baseline LC-vs-pupil partial Spearman.

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
    raw_mat = fullfile(paths.results_dir, 'LC_data_raw.mat');
    if ~exist(raw_mat, 'file')
        error('Raw data mat not found. Run compute_data(paths) first.');
    end
    s = load(raw_mat, 'LC_Beep_table', 'LC_Fix_table');
    fig = plot_S3_sig_baseline_subset(s.LC_Beep_table, s.LC_Fix_table);
catch ME
    if ~isempty(fig) && isgraphics(fig)
        close(fig);
    end
    rethrow(ME);
end

opts = export_settings();
opts.paper_position = [0 0 8.0 4.2];
outdir = paths.output_figures;
if ~exist(outdir,'dir')
    mkdir(outdir);
end
outpath = fullfile(outdir, 'Figure_S3_sig_baseline_subset.pdf');

set(fig, 'Units', opts.units, 'Position', opts.paper_position);
set(fig, 'PaperUnits', opts.units);
set(fig, 'PaperPositionMode', 'manual');
set(fig, 'PaperPosition', opts.paper_position);
set(fig, 'PaperSize', opts.paper_position(3:4));
print(fig, outpath, '-dpdf', '-painters', sprintf('-r%d', opts.dpi));
end
