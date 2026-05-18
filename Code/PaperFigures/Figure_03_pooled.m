function fig = Figure_03_pooled(paths, options)
% Figure_03_pooled  Produce Figure 3 (pooled across-session comparisons).

if nargin < 1 || isempty(paths)
    if exist('config_paths.m','file')
        paths = config_paths();
    else
        paths = config_paths_example();
    end
end
if nargin < 2 || isempty(options)
    options = struct();
end
if ~isfield(options, 'render_mode') || isempty(options.render_mode)
    options.render_mode = 'image'; % default: raster for faster rendering
end
if ~isfield(options, 'dpi') || isempty(options.dpi)
    options.dpi = 300;
end
if ~isfield(options, 'predictor_mode') || isempty(options.predictor_mode)
    options.predictor_mode = 'residual';
end

fig = [];
try
    compute_data(paths);
    results_dir = paths.results_dir;

    % Figure 3 uses the z-scored cache directly.
    z_mat = fullfile(results_dir, 'LC_data_zscored.mat');
    if ~exist(z_mat,'file')
        error('Z-scored cache not found: %s', z_mat);
    end
    s_raw = load(z_mat);
    [LC_Beep_table, LC_Fix_table, stats_table] = prepare_figure_analysis_tables( ...
        s_raw.LC_Beep_table, s_raw.LC_Fix_table, options.predictor_mode);

    % Call new population plotting function
    fig = plot_03_population_new(LC_Beep_table, LC_Fix_table, stats_table, options.predictor_mode);
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
outpath = fullfile(outdir, 'Figure_03_pooled.pdf');
set(fig, 'PaperUnits', 'inches', ...
         'PaperSize',     [17.9483 5.7952], ...
         'PaperPosition', [0 0 17.9483 5.7952]);

switch lower(string(options.render_mode))
    case "vector"
        print(fig, outpath, '-dpdf', '-painters');
    otherwise
        % Default: rasterize for faster downstream rendering with dense point clouds.
        try
            exportgraphics(fig, outpath, 'ContentType', 'image', 'Resolution', options.dpi);
        catch
            % Fallback for older MATLAB versions without exportgraphics options.
            out_png = fullfile(outdir, 'Figure_03_pooled.png');
            print(fig, out_png, '-dpng', sprintf('-r%d', options.dpi));
        end
end
end
