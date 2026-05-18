function compute_manuscript_stats(paths)
% COMPUTE_MANUSCRIPT_STATS  Print manuscript-style statistics with current values.
% Usage: compute_manuscript_stats()

if nargin < 1 || isempty(paths)
    if exist('config_paths.m','file')
        paths = config_paths();
    else
        error('Please create config_paths.m or pass paths struct');
    end
end

results_dir = paths.results_dir;
raw_mat = fullfile(results_dir, 'LC_data_raw.mat');
z_mat = fullfile(results_dir, 'LC_data_zscored.mat');
if ~exist(raw_mat,'file')
    error('Raw data mat not found. Run compute_data(paths) first.');
end
s = load(raw_mat);
LC_Beep_table = s.LC_Beep_table;
LC_Fix_table = s.LC_Fix_table;
if ~exist(z_mat,'file')
    error('Z-scored data mat not found. Run compute_data(paths) first.');
end
s_z = load(z_mat);
LC_Beep_z = s_z.LC_Beep_table;
LC_Fix_z = s_z.LC_Fix_table;

% Build per-unit stats via the new helper path (no legacy plotting scripts)
[beep_raw, fix_raw, stats_table] = prepare_figure_analysis_tables(LC_Beep_table, LC_Fix_table);
[beep_z, fix_z] = prepare_figure_analysis_tables(LC_Beep_z, LC_Fix_z);

fprintf('\n================ Manuscript-Style Statistical Summary ================\n\n');

% ---------------------------------------------------------------------
% Basic quantifications (sessions/units/trials)
% ---------------------------------------------------------------------
units_all = unique(stats_table.unit_id);
units_oz = unique(stats_table.unit_id(stats_table.monkey_id == 1));
units_ci = unique(stats_table.unit_id(stats_table.monkey_id == 2));

sid_all = get_relevant_sessions_from_stats(stats_table);

n_sess_oz = sum(sid_all.monkey_id == 1);
n_sess_ci = sum(sid_all.monkey_id == 2);

fprintf('Data were pooled across %d sessions (%d Oz, %d Ci) and %d units (%d Oz, %d Ci).\n', ...
    height(sid_all), n_sess_oz, n_sess_ci, numel(units_all), numel(units_oz), numel(units_ci));
fprintf('The analyzed dataset included %d beep trials and %d non-beep fixation trials.\n\n', ...
    height(LC_Beep_table), height(LC_Fix_table));

% ---------------------------------------------------------------------
% Baseline relationship quantification used for positive/negative grouping
% ---------------------------------------------------------------------
if ismember('p', stats_table.Properties.VariableNames) && ismember('base_p_base_FR', stats_table.Properties.VariableNames)
    sig = stats_table.p < 0.05 & isfinite(stats_table.base_p_base_FR);
    sig_pos = sig & stats_table.base_p_base_FR > 0;
    sig_neg = sig & stats_table.base_p_base_FR < 0;
    fprintf(['Baseline pupil and baseline FR (partial Spearman, controlling time) ' ...
             'were significant in %d/%d units, with %d positive and %d negative relationships.\n'], ...
             sum(sig), height(stats_table), sum(sig_pos), sum(sig_neg));
    fprintf('By monkey: Oz %d/%d significant; Ci %d/%d significant.\n\n', ...
        sum(sig & stats_table.monkey_id==1), sum(stats_table.monkey_id==1), ...
        sum(sig & stats_table.monkey_id==2), sum(stats_table.monkey_id==2));
end

% ---------------------------------------------------------------------
% Figure 2 summary-column median tests (Wilcoxon signed-rank vs 0)
% ---------------------------------------------------------------------
fprintf('Figure 2 summary-column median tests (Wilcoxon signed-rank vs median = 0):\n');

% Build the per-session / per-unit correlation summaries used in the last
% column population summaries of Figure 2.
fig2_row1 = build_session_summary_local(beep_raw, 'pupil_drift_residuals', 'pupil_bs_evoked', sid_all);
fig2_row2 = build_unit_summary_local(beep_raw, fix_raw, 2);
fig2_row3 = build_unit_summary_local(beep_raw, fix_raw, 3);
fig2_row4 = build_unit_summary_local(beep_raw, fix_raw, 4);
fig2_row5 = build_unit_summary_local(beep_raw, fix_raw, 5);
fig2_row6 = build_unit_summary_local(beep_raw, fix_raw, 6);

report_signedrank_by_monkey(fig2_row3, ...
    ['Baseline LC activity vs baseline pupil diameter (partial Spearman; residuals)']);
report_signedrank_by_monkey(fig2_row4, ...
    ['Baseline-subtracted evoked LC responses vs baseline-subtracted evoked pupil responses']);
report_signedrank_by_monkey(fig2_row2, ...
    ['Baseline-subtracted evoked LC responses vs baseline LC activity (residuals)']);
report_signedrank_by_monkey(fig2_row1, ...
    ['Baseline-subtracted evoked pupil responses vs baseline pupil diameter (residuals)']);
report_signedrank_by_monkey(fig2_row5, ...
    ['Baseline pupil diameter vs baseline-subtracted evoked LC responses']);
report_signedrank_by_monkey(fig2_row6, ...
    ['Baseline LC activity vs baseline-subtracted evoked pupil responses']);

fprintf('Across-epoch range-impact analyses (legacy correlationsEvokedMag logic):\n');

range_tbl = build_evoked_range_by_unit(beep_raw);

tbl_row5 = innerjoin(fig2_row5(:, {'unit_id','monkey_id','r'}), ...
    range_tbl(:, {'unit_id','monkey_id','range_spike_evoked'}), ...
    'Keys', {'unit_id','monkey_id'});
tbl_row6 = innerjoin(fig2_row6(:, {'unit_id','monkey_id','r'}), ...
    range_tbl(:, {'unit_id','monkey_id','range_pupil_evoked'}), ...
    'Keys', {'unit_id','monkey_id'});

for mm = 1:2
    L5 = tbl_row5.monkey_id == mm;
    [rho5, p5] = corr_pair(tbl_row5.range_spike_evoked(L5), tbl_row5.r(L5));
    fprintf(['Baseline pupil diameter vs evoked LC relationship as a function of evoked LC range ' ...
             '(Spearman rho = %.2f, p = %s for monkey %s).\n'], ...
             rho5, p_to_sci_str(p5), monkey_short(mm));

    L6 = tbl_row6.monkey_id == mm;
    [rho6, p6] = corr_pair(tbl_row6.range_pupil_evoked(L6), tbl_row6.r(L6));
    fprintf(['Baseline LC activity vs evoked pupil relationship as a function of evoked pupil range ' ...
             '(Spearman rho = %.2f, p = %s for monkey %s).\n'], ...
             rho6, p_to_sci_str(p6), monkey_short(mm));
end

fprintf('\n');

% ---------------------------------------------------------------------
% Figure 3 pooled correlations (z-scored pathway)
% ---------------------------------------------------------------------
fprintf('Figure 3 pooled relationships (Spearman, by monkey):\n');

% Col 1: baseline pupil residual vs evoked pupil, one value per unique session-trial
for mm = 1:2
    b = beep_z(beep_z.monkey_id==mm,:);
    b = unique_session_rows_local(b);
    [rho, p] = corr_pair(b.pupil_drift_residuals, b.pupil_bs_evoked);
    monkey_name = monkey_short(mm);
    fprintf(['Baseline-subtracted evoked pupil responses were correlated with baseline pupil ' ...
             '(Z-scored residuals; rho = %.3f, p = %s for monkey %s).\n'], ...
             rho, p_to_str(p), monkey_name);
end

% Col 2
report_pair_by_monkey(beep_z, [], 'spike_drift_residuals', 'spike_bs_evoked', ...
    'Baseline-subtracted evoked FR responses were correlated with baseline FR (Z-scored residuals)');

% Col 3 (beep + fix)
for mm = 1:2
    b = beep_z(beep_z.monkey_id==mm,:);
    f = fix_z(fix_z.monkey_id==mm,:);
    xs = [b.pupil_drift_residuals; f.pupil_drift_residuals];
    ys = [b.spike_drift_residuals; f.spike_drift_residuals];
    [rho, p] = corr_pair(xs, ys);
    fprintf(['Baseline FR (Z-scored residuals) was correlated with baseline pupil (Z-scored residuals) ' ...
             '(rho = %.3f, p = %s for monkey %s).\n'], rho, p_to_str(p), monkey_short(mm));
end

% Col 4
report_pair_by_monkey(beep_z, [], 'pupil_bs_evoked', 'spike_bs_evoked', ...
    'Baseline-subtracted evoked FR responses were correlated with baseline-subtracted evoked pupil responses');

% Col 5
report_pair_by_monkey(beep_z, [], 'pupil_drift_residuals', 'spike_bs_evoked', ...
    'Baseline-subtracted evoked FR responses were correlated with baseline pupil (Z-scored residuals)');

% Col 6
report_pair_by_monkey(beep_z, [], 'pupil_bs_evoked', 'spike_drift_residuals', ...
    'Baseline FR (Z-scored residuals) was correlated with baseline-subtracted evoked pupil responses');

fprintf('\n');

% LLR counts if available
if ismember('pEvoked_v_pBase_LLR', stats_table.Properties.VariableNames)
    thr = 3.841; % chi2(1) 0.05 threshold
    fprintf('Supplementary LLR comparisons (threshold %.3f):\n', thr);

    % Legacy intent for this comparison is session-level (not unit-level).
    sess_llr_tbl = build_session_llr_pEvoked_v_pBase(beep_raw, sid_all);
    n_sess_inc = height(sess_llr_tbl);
    n_sess_sig = sum(sess_llr_tbl.llr > thr, 'omitnan');
    fprintf('For evoked pupil vs baseline pupil, %d/%d sessions exceeded the LLR threshold (%.3f).\n', ...
        n_sess_sig, n_sess_inc, thr);
    for mm = 1:2
        vm = sess_llr_tbl.llr(sess_llr_tbl.monkey_id==mm);
        fprintf('  %s: %d/%d\n', monkey_short(mm), sum(vm>thr,'omitnan'), numel(vm));
    end

    fields = {'pEvoked_v_pBase_LLR','sEvoked_v_sBase_LLR','pEvoked_v_sBase_LLR','sEvoked_v_pBase_LLR'};
    labels = {
        'evoked pupil vs baseline pupil', ...
        'evoked FR vs baseline FR', ...
        'evoked pupil vs baseline FR', ...
        'evoked FR vs baseline pupil' ...
        };
    for i = 2:numel(fields)
        f = fields{i};
        if ismember(f, stats_table.Properties.VariableNames)
            vals = stats_table.(f);
            n_inc = sum(~isnan(vals));
            n_sig = sum(vals>thr,'omitnan');
            fprintf('For %s, %d/%d units exceeded the LLR threshold (%.3f).\n', labels{i}, n_sig, n_inc, thr);
            for mm = 1:2
                vm = vals(stats_table.monkey_id==mm);
                fprintf('  %s: %d/%d\n', monkey_short(mm), sum(vm>thr,'omitnan'), sum(~isnan(vm)));
            end
        end
    end
end

fprintf('\nDone.\n\n');
end

function report_pair_by_monkey(beep_tbl, ~, xvar, yvar, sentence)
for mm = 1:2
    b = beep_tbl(beep_tbl.monkey_id==mm,:);
    [rho, p] = corr_pair(b.(xvar), b.(yvar));
    fprintf('%s (rho = %.3f, p = %s for monkey %s).\n', ...
        sentence, rho, p_to_str(p), monkey_short(mm));
end
end

function [rho, p] = corr_pair(x, y)
rho = NaN; p = NaN;
try
    valid = isfinite(x) & isfinite(y);
    if sum(valid) >= 3
        [rho, p] = corr(x(valid), y(valid), 'Type', 'Spearman');
    end
catch
end
end

function s = p_to_str(p)
if ~isfinite(p)
    s = 'n/a';
elseif p < 0.001
    s = '<0.001';
else
    s = sprintf('%.4f', p);
end
end

function m = monkey_short(mm)
if mm == 1
    m = 'Oz';
else
    m = 'Ci';
end
end

function tbl_out = unique_session_rows_local(tbl_in)
tbl_out = tbl_in;
if isempty(tbl_in)
    return
end
if ismember('session_id', tbl_in.Properties.VariableNames) && ismember('fix_global_start_time', tbl_in.Properties.VariableNames)
    key = [tbl_in.session_id, tbl_in.fix_global_start_time];
    [~, first_idx] = unique(key, 'rows', 'stable');
    tbl_out = tbl_in(first_idx,:);
end
end

function tbl = build_session_summary_local(beep_tbl, x_var, y_var, relevant_sessions)
tbl = table('Size',[0 4], ...
    'VariableTypes', {'double','double','double','double'}, ...
    'VariableNames', {'session_id','monkey_id','r','p'});

if ~ismember('session_id', beep_tbl.Properties.VariableNames)
    return
end
if nargin >= 4 && ~isempty(relevant_sessions)
    if ismember('monkey_id', beep_tbl.Properties.VariableNames)
        beep_tbl = innerjoin(beep_tbl, relevant_sessions(:, {'session_id','monkey_id'}), ...
            'Keys', {'session_id','monkey_id'});
    end
end

session_ids = unique(beep_tbl.session_id);
for si = 1:numel(session_ids)
    sid = session_ids(si);
    rows = beep_tbl(beep_tbl.session_id == sid, :);
    if isempty(rows)
        continue
    end
    if ismember('fix_global_start_time', rows.Properties.VariableNames)
        [~, first_idx] = unique(rows.fix_global_start_time, 'stable');
        rows = rows(first_idx, :);
    end
    try
        [r,p] = corr(rows.(x_var), rows.(y_var), 'type', 'Spearman', 'rows', 'complete');
    catch
        r = NaN;
        p = NaN;
    end
    tbl = [tbl; {sid, rows.monkey_id(1), r, p}]; %#ok<AGROW>
end
end

function tbl = build_unit_summary_local(beep_tbl, fix_tbl, row_num)
tbl = table('Size',[0 4], ...
    'VariableTypes', {'double','double','double','double'}, ...
    'VariableNames', {'unit_id','monkey_id','r','p'});

unit_ids = unique(beep_tbl.unit_id);
for ui = 1:numel(unit_ids)
    uid = unit_ids(ui);
    b = beep_tbl(beep_tbl.unit_id == uid, :);
    f = fix_tbl(fix_tbl.unit_id == uid, :);
    if isempty(b)
        continue
    end

    try
        switch row_num
            case 2
                [r,p] = corr(b.spike_drift_residuals, b.spike_bs_evoked, 'type', 'Spearman', 'rows', 'complete');
            case 3
                all_t = [b.fix_global_start_time; f.fix_global_start_time];
                all_pd = [b.pupil_baseline; f.pupil_baseline];
                all_fr = [b.spike_baseline; f.spike_fix_baseline];
                [r,p] = partialcorr(all_fr, all_pd, all_t, 'Type', 'Spearman', 'Rows', 'complete');
            case 4
                [r,p] = corr(b.pupil_bs_evoked, b.spike_bs_evoked, 'type', 'Spearman', 'rows', 'complete');
            case 5
                [r,p] = corr(b.pupil_drift_residuals, b.spike_bs_evoked, 'type', 'Spearman', 'rows', 'complete');
            case 6
                [r,p] = corr(b.pupil_bs_evoked, b.spike_drift_residuals, 'type', 'Spearman', 'rows', 'complete');
            otherwise
                continue
        end
    catch
        r = NaN;
        p = NaN;
    end

    tbl = [tbl; {uid, b.monkey_id(1), r, p}]; %#ok<AGROW>
end
end

function report_signedrank_by_monkey(summary_tbl, label)
if isempty(summary_tbl)
    fprintf('%s: no data available.\n', label);
    return
end

for mm = 1:2
    vals = summary_tbl.r(summary_tbl.monkey_id == mm);
    vals = vals(isfinite(vals));
    n = numel(vals);
    if n == 0
        p = NaN;
        med_val = NaN;
    else
        med_val = median(vals, 'omitnan');
        try
            p = signrank(vals);
        catch
            p = NaN;
        end
    end

    fprintf('%s: %s p = %s (N = %d, median rho = %.3f).\n', ...
        label, monkey_short(mm), p_to_sci_str(p), n, med_val);
end
end

function s = p_to_sci_str(p)
if ~isfinite(p)
    s = 'n/a';
else
    s = sprintf('%.3g', p);
end
end

function tbl = build_session_llr_pEvoked_v_pBase(beep_tbl, relevant_sessions)
tbl = table('Size',[0 3], ...
    'VariableTypes', {'double','double','double'}, ...
    'VariableNames', {'session_id','monkey_id','llr'});

if ~ismember('session_id', beep_tbl.Properties.VariableNames)
    return
end
if nargin >= 2 && ~isempty(relevant_sessions)
    if ismember('monkey_id', beep_tbl.Properties.VariableNames)
        beep_tbl = innerjoin(beep_tbl, relevant_sessions(:, {'session_id','monkey_id'}), ...
            'Keys', {'session_id','monkey_id'});
    end
end

session_ids = unique(beep_tbl.session_id);
for si = 1:numel(session_ids)
    sid = session_ids(si);
    rows = beep_tbl(beep_tbl.session_id == sid, :);
    if isempty(rows)
        continue
    end

    if ismember('fix_global_start_time', rows.Properties.VariableNames)
        [~, first_idx] = unique(rows.fix_global_start_time, 'stable');
        rows = rows(first_idx, :);
    end

    llr = compute_llr_local(rows, 'pupil_bs_evoked', 'pupil_drift_residuals');
    tbl = [tbl; {sid, rows.monkey_id(1), llr}]; %#ok<AGROW>
end
end

function llr = compute_llr_local(tbl, response_var, predictor_var)
llr = NaN;
if ~ismember(response_var, tbl.Properties.VariableNames) || ~ismember(predictor_var, tbl.Properties.VariableNames)
    return
end

resp = tbl.(response_var);
pred = tbl.(predictor_var);
valid = isfinite(resp) & isfinite(pred);
if sum(valid) < 4 || numel(unique(pred(valid))) < 3
    return
end

sub = tbl(valid,:);
f1 = sprintf('%s ~ %s', response_var, predictor_var);
f2 = sprintf('%s ~ %s*%s', response_var, predictor_var, predictor_var);

try
    lme1 = fitlme(sub, f1);
    lme2 = fitlme(sub, f2);
    cmp = compare(lme1, lme2);
    if ismember('LogLik', cmp.Properties.VariableNames) && height(cmp) >= 2
        llr = 2*(cmp.LogLik(2) - cmp.LogLik(1));
        return
    end
catch
end

try
    lm1 = fitlm(sub, f1);
    lm2 = fitlm(sub, f2);
    if isprop(lm1,'LogLikelihood') && isprop(lm2,'LogLikelihood')
        llr = 2*(lm2.LogLikelihood - lm1.LogLikelihood);
    end
catch
end
end

function tbl = build_evoked_range_by_unit(beep_tbl)
tbl = table('Size',[0 4], ...
    'VariableTypes', {'double','double','double','double'}, ...
    'VariableNames', {'unit_id','monkey_id','range_spike_evoked','range_pupil_evoked'});

unit_ids = unique(beep_tbl.unit_id);
for ui = 1:numel(unit_ids)
    uid = unit_ids(ui);
    b = beep_tbl(beep_tbl.unit_id == uid, :);
    if isempty(b)
        continue
    end
    spike_vals = b.spike_bs_evoked(isfinite(b.spike_bs_evoked));
    pupil_vals = b.pupil_bs_evoked(isfinite(b.pupil_bs_evoked));
    if isempty(spike_vals)
        range_spike = NaN;
    else
        range_spike = max(spike_vals) - min(spike_vals);
    end
    if isempty(pupil_vals)
        range_pupil = NaN;
    else
        range_pupil = max(pupil_vals) - min(pupil_vals);
    end
    tbl = [tbl; {uid, b.monkey_id(1), range_spike, range_pupil}]; %#ok<AGROW>
end
end

function sid_all = get_relevant_sessions_from_stats(stats_table)
sid_all = table('Size',[0 2], ...
    'VariableTypes', {'double','double'}, ...
    'VariableNames', {'session_id','monkey_id'});

required = ismember({'session_id','monkey_id'}, stats_table.Properties.VariableNames);
if ~all(required)
    return
end

sid_all = unique(stats_table(:, {'session_id','monkey_id'}), 'rows');
valid = isfinite(sid_all.session_id) & isfinite(sid_all.monkey_id);
sid_all = sid_all(valid,:);
end
