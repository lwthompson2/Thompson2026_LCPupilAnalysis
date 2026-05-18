function fig = Figure_02_examples(paths)
% Figure_02_examples  Produce Figure 2 (example units + summary column).
% Usage:
%   fig = Figure_02_examples();

if nargin < 1 || isempty(paths)
    if exist('config_paths.m','file')
        paths = config_paths();
    else
        paths = config_paths_example();
    end
end

fig = [];
try
    % Ensure data are computed and available
    compute_data(paths);
    results_dir = paths.results_dir;
    raw_mat = fullfile(results_dir, 'LC_data_raw.mat');
    if exist(raw_mat,'file')
        load(raw_mat, 'LC_Beep_table', 'LC_Fix_table'); %#ok<NASGU>
    end

    % Call new plotting function with loaded tables
    fig = plot_02_examples_new(LC_Beep_table, LC_Fix_table);
catch ME
    if ~isempty(fig) && isgraphics(fig)
        close(fig);
    end
    rethrow(ME);
end

% Export
opts = export_settings();
% Figure 2 has a 6x5 panel layout and should be taller than default.
% Match manuscript reference Figure_2.pdf page size (inches).
opts.paper_position = [0 0 10.5233 12.5313];
outdir = paths.output_figures;
if ~exist(outdir,'dir')
    mkdir(outdir);
end
outpath = fullfile(outdir, 'Figure_02_examples.pdf');
% Use print with explicit PaperSize for exact output dimensions.
set(fig, 'Units', opts.units, 'Position', opts.paper_position);
set(fig, 'PaperUnits', opts.units);
set(fig, 'PaperPositionMode', 'manual');
set(fig, 'PaperPosition', opts.paper_position);
set(fig, 'PaperSize', opts.paper_position(3:4));
print(fig, outpath, '-dpdf', '-painters', sprintf('-r%d', opts.dpi));
end
