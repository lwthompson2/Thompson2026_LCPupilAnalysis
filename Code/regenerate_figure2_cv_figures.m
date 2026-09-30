function regenerate_figure2_cv_figures(paths)
% REGENERATE_FIGURE2_CV_FIGURES
% Re-export Figure 2 CV summary figures from cached Results/Figure2_cv_metrics.mat.
% This avoids rerunning the full CV analysis.

if nargin < 1 || isempty(paths)
    paths = config_paths();
end

cv_mat = fullfile(paths.results_dir, 'Figure2_cv_metrics.mat');
if ~exist(cv_mat, 'file')
    error('Cached CV metrics not found at %s', cv_mat);
end

s = load(cv_mat, 'cv_tbl');
if ~isfield(s, 'cv_tbl') || isempty(s.cv_tbl)
    error('cv_tbl missing or empty in %s', cv_mat);
end
cv_tbl = s.cv_tbl;

export_cv_summary_figure_local(cv_tbl, paths, 'cv_rho', ...
    'CV Spearman Correlation', [-1, 1], 'Figure_S5_Figure2_CV_summary.pdf', ...
    'Figure_S5_Figure2_CV_summary');
export_cv_summary_figure_local(cv_tbl, paths, 'cv_r2', ...
    'CV R^2', [-1, 1], 'Figure_S5b_Figure2_CV_R2_summary.pdf', ...
    'Figure_S5b_Figure2_CV_R2_summary');

fprintf('Regenerated CV figure: %s\n', fullfile(paths.output_figures, 'Figure_S5_Figure2_CV_summary.pdf'));
fprintf('Regenerated CV figure: %s\n', fullfile(paths.output_figures, 'Figure_S5b_Figure2_CV_R2_summary.pdf'));
end

function export_cv_summary_figure_local(cv_tbl, paths, metric_name, y_label_text, y_lims, out_file, fig_name)
fig = figure('Name', fig_name);
fig.Units = 'inches';
fig.Position = [1 1 10.5 7.5];

panel_titles = {
    'Baseline Pupil -> Evoked Pupil', ...
    'Baseline LC -> Evoked LC', ...
    'Baseline Pupil -> Baseline LC', ...
    'Evoked Pupil -> Evoked LC', ...
    'Baseline Pupil -> Evoked LC', ...
    'Evoked Pupil -> Baseline LC' ...
    };

tiledlayout(2,3, 'TileSpacing','compact', 'Padding','compact');
symbols = {'o','d'};
colors = [0.35 0.35 0.35; 0.35 0.35 0.35];
x_start = [1 5];

for row_num = 1:6
    nexttile(row_num); hold on;
    row_tbl = cv_tbl(cv_tbl.row_num == row_num, :);

    for mm = 1:2
        idx = row_tbl.monkey_id == mm;
        vals = row_tbl.(metric_name)(idx);
        vals = vals(isfinite(vals));
        if isempty(vals)
            continue
        end

        scatter(x_start(mm) + (3-1).*rand(numel(vals),1), vals, 45, symbols{mm}, ...
            'MarkerFaceColor', colors(mm,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.30);

        p_med = NaN;
        try
            p_med = signrank(vals);
        catch
        end
        lw = 3;
        if isfinite(p_med) && p_med < 0.05
            lw = 6;
        end
        med_val = median(vals, 'omitnan');
        plot(x_start(mm) + [-0.5, 2.5], [med_val, med_val], '-', 'Color', 'k', 'LineWidth', lw);
    end

    plot([0,8], [0 0], ':k', 'LineWidth', 1.2);
    xlim([0,8]);
    ylim(y_lims);
    xticks([2,6]);
    xticklabels({'Oz','Ci'});
    ylabel(y_label_text);
    xlabel('Monkey');
    title(panel_titles{row_num}, 'FontWeight', 'normal', 'FontSize', 10);
    box on;
    set(gca, 'FontSize', 10, 'LineWidth', 1.3);
end

outdir = paths.output_figures;
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
outpath = fullfile(outdir, out_file);
opts = export_settings();
set(fig, 'PaperUnits', opts.units);
set(fig, 'PaperPositionMode', 'manual');
set(fig, 'PaperPosition', fig.Position);
set(fig, 'PaperSize', fig.Position(3:4));
print(fig, outpath, '-dpdf', '-painters', sprintf('-r%d', opts.dpi));
close(fig);
end