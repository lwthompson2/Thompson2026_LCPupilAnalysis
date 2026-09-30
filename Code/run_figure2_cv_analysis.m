function cv_tbl = run_figure2_cv_analysis(paths, opts)
% RUN_FIGURE2_CV_ANALYSIS
% Repeated Monte Carlo k-fold or LOOCV prediction analysis aligned to Figure 2 row definitions.
% Uses simple linear models (fitlm) and held-out prediction metrics.
%
% Outputs:
%   Results/Figure2_cv_metrics.mat
%   Results/Figure2_cv_metrics.csv
%   Figures/Paper/Figure_S5_Figure2_CV_summary.pdf
%   Figures/Paper/Figure_S5b_Figure2_CV_R2_summary.pdf

if nargin < 1 || isempty(paths)
    paths = config_paths();
end
if nargin < 2
    opts = struct();
end
if ~isfield(opts, 'cv_method') || isempty(opts.cv_method)
    opts.cv_method = 'kfold';
end
opts.cv_method = lower(string(opts.cv_method));
if ~ismember(opts.cv_method, ["kfold", "loocv"])
    error('opts.cv_method must be ''kfold'' or ''loocv''');
end
if ~isfield(opts, 'kfold') || isempty(opts.kfold)
    opts.kfold = 5;
end
if ~isfield(opts, 'cv_repeats') || isempty(opts.cv_repeats)
    % Repeats used for the primary CV point estimate.
    opts.cv_repeats = 20;
end
if ~isfield(opts, 'rng_seed') || isempty(opts.rng_seed)
    opts.rng_seed = 12345;
end
if ~isfield(opts, 'make_figure') || isempty(opts.make_figure)
    opts.make_figure = true;
end
if ~isfield(opts, 'run_permutation') || isempty(opts.run_permutation)
    opts.run_permutation = true;
end
if ~isfield(opts, 'n_perms') || isempty(opts.n_perms)
    opts.n_perms = 100;
end
if ~isfield(opts, 'perm_cv_repeats') || isempty(opts.perm_cv_repeats)
    % Keep permutation computation lightweight by default.
    opts.perm_cv_repeats = 1;
end
if ~isfield(opts, 'perm_alpha') || isempty(opts.perm_alpha)
    opts.perm_alpha = 0.05;
end
if ~isfield(opts, 'show_progress') || isempty(opts.show_progress)
    opts.show_progress = true;
end
if ~isfield(opts, 'output_tag') || isempty(opts.output_tag)
    opts.output_tag = '';
end
suffix = output_suffix_local(opts.output_tag);

raw_mat = fullfile(paths.results_dir, 'LC_data_raw.mat');
if ~exist(raw_mat, 'file')
    error('Raw data mat not found. Run compute_data(paths) first.');
end
s = load(raw_mat, 'LC_Beep_table', 'LC_Fix_table');
[beep_tbl, fix_tbl] = prepare_figure_analysis_tables(s.LC_Beep_table, s.LC_Fix_table);

row_labels = {
    'Baseline Pupil -> Evoked Pupil', ...
    'Baseline LC -> Evoked LC', ...
    'Baseline Pupil -> Baseline LC', ...
    'Evoked Pupil -> Evoked LC', ...
    'Baseline Pupil -> Evoked LC', ...
    'Evoked Pupil -> Baseline LC' ...
    };

cv_tbl = table('Size',[0 12], ...
    'VariableTypes', {'double','string','string','double','double','double','double','double','double','double','double','double'}, ...
    'VariableNames', {'row_num','row_label','entity_type','entity_id','monkey_id','cv_rho','cv_r2','cv_mae','n_trials','cv_r2_perm_p','perm_sig','n_perms'});

rng(opts.rng_seed);

% LOOCV executes a single deterministic pass; k-fold may use repeated random splits.
if opts.cv_method == "loocv"
    main_cv_repeats = 1;
    perm_cv_repeats = 1;
else
    main_cv_repeats = opts.cv_repeats;
    perm_cv_repeats = opts.perm_cv_repeats;
end

% Row 1: session-level
session_ids = unique(beep_tbl.session_id);
if opts.show_progress
    fprintf('CV/permutation progress - row 1 (%s, CV repeats=%d, perm repeats=%d):\n', ...
        upper(char(opts.cv_method)), main_cv_repeats, perm_cv_repeats);
    row1_progress = init_progress_bar_local('Row 1 sessions', numel(session_ids));
end
for i = 1:numel(session_ids)
    sid = session_ids(i);
    rows = beep_tbl(beep_tbl.session_id == sid, :);
    if isempty(rows)
        continue
    end
    [~, keep_idx] = unique(rows.fix_global_start_time, 'stable');
    rows = rows(keep_idx, :);

    x = rows.pupil_drift_residuals;
    y = rows.pupil_bs_evoked;
    monkey_id = rows.monkey_id(1);
    [rho, r2, mae, n_used] = run_cv_linear_local(x, y, opts.cv_method, opts.kfold, opts.cv_repeats);
    if opts.run_permutation
        [perm_p, perm_sig] = run_r2_permutation_local(x, y, opts.cv_method, opts.kfold, opts.perm_cv_repeats, r2, opts.n_perms, opts.perm_alpha);
    else
        perm_p = NaN;
        perm_sig = NaN;
    end

    if opts.show_progress
        row1_progress = update_progress_bar_local(row1_progress, i);
    end

    cv_tbl = [cv_tbl; {1, string(row_labels{1}), "session", sid, monkey_id, rho, r2, mae, n_used, perm_p, perm_sig, opts.n_perms}]; %#ok<AGROW>
end

% Rows 2-6: unit-level
unit_ids = unique(beep_tbl.unit_id);
% Match legacy unit-removal behavior used in prepare_figure_analysis_tables.
unit_ids = unit_ids(~ismember(unit_ids, [43, 65]));
if opts.show_progress
    fprintf('CV/permutation progress - rows 2-6 (%s, CV repeats=%d, perm repeats=%d):\n', ...
        upper(char(opts.cv_method)), main_cv_repeats, perm_cv_repeats);
    total_unit_steps = numel(unit_ids) * 5;
    unit_progress = init_progress_bar_local('Rows 2-6 units', total_unit_steps);
end
step_idx = 0;
for i = 1:numel(unit_ids)
    uid = unit_ids(i);
    b = beep_tbl(beep_tbl.unit_id == uid, :);
    f = fix_tbl(fix_tbl.unit_id == uid, :);
    if isempty(b)
        continue
    end
    monkey_id = b.monkey_id(1);

    for row_num = 2:6
        switch row_num
            case 2
                x = b.spike_drift_residuals;
                y = b.spike_bs_evoked;
            case 3
                x = [b.pupil_drift_residuals; f.pupil_drift_residuals];
                y = [b.spike_drift_residuals; f.spike_drift_residuals];
            case 4
                x = b.pupil_bs_evoked;
                y = b.spike_bs_evoked;
            case 5
                x = b.pupil_drift_residuals;
                y = b.spike_bs_evoked;
            case 6
                x = b.pupil_bs_evoked;
                y = b.spike_drift_residuals;
        end

        [rho, r2, mae, n_used] = run_cv_linear_local(x, y, opts.cv_method, opts.kfold, opts.cv_repeats);
        if opts.run_permutation
            [perm_p, perm_sig] = run_r2_permutation_local(x, y, opts.cv_method, opts.kfold, opts.perm_cv_repeats, r2, opts.n_perms, opts.perm_alpha);
        else
            perm_p = NaN;
            perm_sig = NaN;
        end
        cv_tbl = [cv_tbl; {row_num, string(row_labels{row_num}), "unit", uid, monkey_id, rho, r2, mae, n_used, perm_p, perm_sig, opts.n_perms}]; %#ok<AGROW>

        if opts.show_progress
            step_idx = step_idx + 1;
            unit_progress = update_progress_bar_local(unit_progress, step_idx);
        end
    end
end

% Keep only rows with enough valid data for CV
if opts.cv_method == "loocv"
    min_n = 2;
else
    min_n = opts.kfold;
end
valid_rows = isfinite(cv_tbl.cv_rho) & isfinite(cv_tbl.cv_r2) & cv_tbl.n_trials >= min_n;
cv_tbl = cv_tbl(valid_rows, :);

% Save outputs
if ~exist(paths.results_dir, 'dir')
    mkdir(paths.results_dir);
end
mat_path = fullfile(paths.results_dir, sprintf('Figure2_cv_metrics%s.mat', suffix));
csv_path = fullfile(paths.results_dir, sprintf('Figure2_cv_metrics%s.csv', suffix));
save(mat_path, 'cv_tbl', 'row_labels', 'opts');
writetable(cv_tbl, csv_path);

if opts.make_figure
    rho_file = sprintf('Figure_S5_Figure2_CV_summary%s.pdf', suffix);
    r2_file = sprintf('Figure_S5b_Figure2_CV_R2_summary%s.pdf', suffix);
    export_cv_summary_figure_local(cv_tbl, paths, 'cv_rho', ...
        'CV Spearman Correlation', [-1, 1], rho_file, ...
        sprintf('Figure_S5_Figure2_CV_summary%s', suffix));
    export_cv_summary_figure_local(cv_tbl, paths, 'cv_r2', ...
        'CV R^2', [-1, 1], r2_file, ...
        sprintf('Figure_S5b_Figure2_CV_R2_summary%s', suffix));
end

fprintf('Saved CV metrics: %s\n', mat_path);
fprintf('Saved CV metrics CSV: %s\n', csv_path);
if opts.make_figure
    fprintf('Saved CV figure: %s\n', fullfile(paths.output_figures, sprintf('Figure_S5_Figure2_CV_summary%s.pdf', suffix)));
    fprintf('Saved CV figure: %s\n', fullfile(paths.output_figures, sprintf('Figure_S5b_Figure2_CV_R2_summary%s.pdf', suffix)));
end
end

function [cv_rho, cv_r2, cv_mae, n_used] = run_cv_linear_local(x, y, cv_method, kfold, n_repeats)
cv_rho = NaN;
cv_r2 = NaN;
cv_mae = NaN;
n_used = 0;

valid = isfinite(x) & isfinite(y);
x = x(valid);
y = y(valid);
n = numel(y);
if cv_method == "loocv"
    min_n = 2;
else
    min_n = kfold;
end
if n < min_n
    return
end

if cv_method == "loocv"
    n_repeats = 1;
end

rho_rep = nan(n_repeats, 1);
r2_rep = nan(n_repeats, 1);
mae_rep = nan(n_repeats, 1);
n_used_rep = nan(n_repeats, 1);

for rr = 1:n_repeats
    if cv_method == "loocv"
        fold_id = (1:n)';
        n_folds = n;
    else
        perm = randperm(n);
        fold_id = mod(0:n-1, kfold) + 1;
        fold_id(perm) = fold_id;
        n_folds = kfold;
    end

    y_pred = nan(n,1);
    for ff = 1:n_folds
        test_idx = fold_id == ff;
        train_idx = ~test_idx;
        if sum(train_idx) < 3 || sum(test_idx) < 1
            continue
        end
        try
            mdl = fitlm(x(train_idx), y(train_idx));
            y_pred(test_idx) = predict(mdl, x(test_idx));
        catch
        end
    end

    keep = isfinite(y_pred) & isfinite(y);
    n_keep = sum(keep);
    n_used_rep(rr) = n_keep;
    if n_keep < min_n
        continue
    end

    try
        rho_rep(rr) = corr(y_pred(keep), y(keep), 'Type', 'Spearman');
    catch
    end

    sse = sum((y(keep) - y_pred(keep)).^2);
    sst = sum((y(keep) - mean(y(keep))).^2);
    if sst > 0
        r2_rep(rr) = 1 - (sse / sst);
    end
    mae_rep(rr) = mean(abs(y(keep) - y_pred(keep)));
end

if any(isfinite(rho_rep))
    cv_rho = median(rho_rep(isfinite(rho_rep)), 'omitnan');
end
if any(isfinite(r2_rep))
    cv_r2 = median(r2_rep(isfinite(r2_rep)), 'omitnan');
end
if any(isfinite(mae_rep))
    cv_mae = median(mae_rep(isfinite(mae_rep)), 'omitnan');
end
if any(isfinite(n_used_rep))
    n_used = round(median(n_used_rep(isfinite(n_used_rep)), 'omitnan'));
end
end

function [perm_p, perm_sig] = run_r2_permutation_local(x, y, cv_method, kfold, cv_repeats, true_r2, n_perms, alpha)
perm_p = NaN;
perm_sig = NaN;

if ~isfinite(true_r2) || n_perms < 1
    return
end

perm_r2 = nan(n_perms, 1);
for pp = 1:n_perms
    y_perm = y(randperm(numel(y)));
    [~, r2_perm, ~, n_used_perm] = run_cv_linear_local(x, y_perm, cv_method, kfold, cv_repeats);
    if cv_method == "loocv"
        min_n = 2;
    else
        min_n = kfold;
    end
    if n_used_perm >= min_n
        perm_r2(pp) = r2_perm;
    end
end

valid_perm = isfinite(perm_r2);
if ~any(valid_perm)
    return
end

perm_p = mean(perm_r2(valid_perm) >= true_r2);
perm_sig = double(perm_p < alpha);
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

T = tiledlayout(2,3, 'TileSpacing','compact', 'Padding','compact'); %#ok<NASGU>
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

function state = init_progress_bar_local(label, total)
state = struct();
state.label = label;
state.total = max(total, 1);
state.last_pct = -1;
fprintf('  %s: %s\n', label, format_progress_bar_local(0));
end

function state = update_progress_bar_local(state, current)
pct = floor((100 * current) / state.total);
if pct <= state.last_pct && current < state.total
    return
end
state.last_pct = pct;
fprintf('  %s: %s\n', state.label, format_progress_bar_local(min(current, state.total) / state.total));
end

function s = format_progress_bar_local(frac)
bar_width = 30;
frac = max(0, min(1, frac));
n_fill = round(bar_width * frac);
bar = [repmat('=', 1, n_fill), repmat('.', 1, bar_width - n_fill)];
s = sprintf('[%s] %5.1f%%%%', bar, 100 * frac);
end

function suffix = output_suffix_local(output_tag)
tag = strtrim(char(output_tag));
if isempty(tag)
    suffix = '';
    return
end
tag = regexprep(tag, '[^A-Za-z0-9_\-]', '_');
if startsWith(tag, '_')
    suffix = tag;
else
    suffix = ['_' tag];
end
end
