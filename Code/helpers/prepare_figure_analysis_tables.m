function [beep_tbl, fix_tbl, stats_table] = prepare_figure_analysis_tables(raw_beep, raw_fix, predictor_mode)
% PREPARE_FIGURE_ANALYSIS_TABLES
% Build figure-ready LC tables and per-unit stats from raw cached tables.
% - Ensures legacy-compatible column aliases
% - Expects caller to pass either raw or z-scored tables from cache
% - Recomputes drift residuals from baseline values
% - Builds stats_table via direct per-unit computations (no legacy plots)

if nargin < 3 || isempty(predictor_mode)
    predictor_mode = 'residual';
end

predictor_mode = lower(string(predictor_mode));
if ~ismember(predictor_mode, ["residual", "baseline"])
    error('predictor_mode must be ''residual'' or ''baseline''');
end

beep_tbl = raw_beep;
fix_tbl = raw_fix;

if isempty(beep_tbl) || isempty(fix_tbl)
    stats_table = table();
    return
end

% Ensure compatibility aliases expected by stats computations
if ismember('pupil_fix_baseline', fix_tbl.Properties.VariableNames) && ~ismember('pupil_baseline', fix_tbl.Properties.VariableNames)
    fix_tbl.pupil_baseline = fix_tbl.pupil_fix_baseline;
end
if ismember('spike_fix_baseline', fix_tbl.Properties.VariableNames) && ~ismember('spike_baseline', fix_tbl.Properties.VariableNames)
    fix_tbl.spike_baseline = fix_tbl.spike_fix_baseline;
end
if ismember('spike_evoked', beep_tbl.Properties.VariableNames) && ~ismember('spike_bs_evoked', beep_tbl.Properties.VariableNames)
    beep_tbl.spike_bs_evoked = beep_tbl.spike_evoked;
end
if ismember('pupil_evoked', beep_tbl.Properties.VariableNames) && ~ismember('pupil_bs_evoked', beep_tbl.Properties.VariableNames)
    beep_tbl.pupil_bs_evoked = beep_tbl.pupil_evoked;
end
if ismember('trial_time', beep_tbl.Properties.VariableNames) && ~ismember('fix_global_start_time', beep_tbl.Properties.VariableNames)
    beep_tbl.fix_global_start_time = beep_tbl.trial_time;
end
if ismember('trial_time', fix_tbl.Properties.VariableNames) && ~ismember('fix_global_start_time', fix_tbl.Properties.VariableNames)
    fix_tbl.fix_global_start_time = fix_tbl.trial_time;
end

[beep_tbl, fix_tbl] = recompute_drift_residuals(beep_tbl, fix_tbl);

stats_table = build_stats(beep_tbl, fix_tbl, predictor_mode);

end

function [beep_tbl, fix_tbl] = recompute_drift_residuals(beep_tbl, fix_tbl)
if ~ismember('pupil_drift_residuals', beep_tbl.Properties.VariableNames)
    beep_tbl.pupil_drift_residuals = nan(height(beep_tbl),1);
end
if ~ismember('spike_drift_residuals', beep_tbl.Properties.VariableNames)
    beep_tbl.spike_drift_residuals = nan(height(beep_tbl),1);
end
if ~ismember('pupil_drift_residuals', fix_tbl.Properties.VariableNames)
    fix_tbl.pupil_drift_residuals = nan(height(fix_tbl),1);
end
if ~ismember('spike_drift_residuals', fix_tbl.Properties.VariableNames)
    fix_tbl.spike_drift_residuals = nan(height(fix_tbl),1);
end

unit_ids = unique(beep_tbl.unit_id);
for i = 1:numel(unit_ids)
    uid = unit_ids(i);
    idx_b = beep_tbl.unit_id == uid;
    idx_f = fix_tbl.unit_id == uid;

    if ~any(idx_b) && ~any(idx_f)
        continue
    end

    t_b = beep_tbl.fix_global_start_time(idx_b);
    t_f = fix_tbl.fix_global_start_time(idx_f);
    pd_b = beep_tbl.pupil_baseline(idx_b);
    pd_f = fix_tbl.pupil_baseline(idx_f);
    fr_b = beep_tbl.spike_baseline(idx_b);
    if ismember('spike_fix_baseline', fix_tbl.Properties.VariableNames)
        fr_f = fix_tbl.spike_fix_baseline(idx_f);
    else
        fr_f = fix_tbl.spike_baseline(idx_f);
    end

    all_t = [t_b; t_f];
    all_pd = [pd_b; pd_f];
    all_fr = [fr_b; fr_f];

    if numel(all_t) >= 2 && any(isfinite(all_pd))
        try
            mdl_pd = fitlm(all_t, all_pd);
            res_pd = mdl_pd.Residuals.Raw;
            beep_tbl.pupil_drift_residuals(idx_b) = res_pd(1:sum(idx_b));
            fix_tbl.pupil_drift_residuals(idx_f) = res_pd(sum(idx_b)+(1:sum(idx_f)));
        catch
        end
    end

    if numel(all_t) >= 2 && any(isfinite(all_fr))
        try
            mdl_fr = fitlm(all_t, all_fr);
            res_fr = mdl_fr.Residuals.Raw;
            beep_tbl.spike_drift_residuals(idx_b) = res_fr(1:sum(idx_b));
            fix_tbl.spike_drift_residuals(idx_f) = res_fr(sum(idx_b)+(1:sum(idx_f)));
        catch
        end
    end
end
end

function stats_table = build_stats(beep_tbl, fix_tbl, predictor_mode)
unit_ids = unique(beep_tbl.unit_id);
template = struct( ...
    'unit_id', NaN, ...
    'session_id', NaN, ...
    'monkey_id', NaN, ...
    'p', NaN, ...
    'base_p_base_FR', NaN, ...
    'pEvoked_v_pBase_LLR', NaN, ...
    'sEvoked_v_sBase_LLR', NaN, ...
    'pEvoked_v_sBase_LLR', NaN, ...
    'sEvoked_v_pBase_LLR', NaN);
stats_arr = repmat(template, numel(unit_ids), 1);

for i = 1:numel(unit_ids)
    uid = unit_ids(i);
    b = beep_tbl(beep_tbl.unit_id==uid,:);
    f = fix_tbl(fix_tbl.unit_id==uid,:);
    if isempty(b) || isempty(f)
        continue
    end
    base = template;
    base.unit_id = uid;
    if ismember('session_id', b.Properties.VariableNames) && ~isempty(b.session_id)
        base.session_id = b.session_id(1);
    end
    base.monkey_id = infer_monkey_id(b);

    s = compute_unit_stats_new(base, b, f, predictor_mode);

    if ~isfield(s,'monkey_id') || ~isfinite(s.monkey_id)
        s.monkey_id = infer_monkey_id(b);
    end

    s.unit_id = uid;
    stats_arr(i) = s;
end

function s = compute_unit_stats_new(base, b, f, predictor_mode)
% Direct per-unit stats used by Figure 3 / S2 (no legacy plotting calls).
s = base;

% Baseline pupil vs baseline FR partial Spearman controlling for time.
[rho_val, p_val] = compute_partial_base_corr(b, f);
s.base_p_base_FR = rho_val;
s.p = p_val;

% LLR comparisons used in S2 and grouping logic.
if predictor_mode == "baseline"
    p_base_var = 'pupil_baseline';
    s_base_var = 'spike_baseline';
else
    p_base_var = 'pupil_drift_residuals';
    s_base_var = 'spike_drift_residuals';
end

s.pEvoked_v_pBase_LLR = compute_llr(b, 'pupil_bs_evoked', p_base_var);
s.sEvoked_v_sBase_LLR = compute_llr(b, 'spike_bs_evoked', s_base_var);
s.pEvoked_v_sBase_LLR = compute_llr(b, 'pupil_bs_evoked', s_base_var);
s.sEvoked_v_pBase_LLR = compute_llr(b, 'spike_bs_evoked', p_base_var);
end

if isempty(stats_arr)
    stats_table = table();
    return
end

stats_table = struct2table(stats_arr);

% Match legacy getUnitSummary removal behavior
to_remove = [43, 65];
valid_remove = to_remove(to_remove <= height(stats_table));
if ~isempty(valid_remove)
    stats_table(valid_remove,:) = [];
end
end

function mm = infer_monkey_id(b)
mm = NaN;
if ismember('monkey_id', b.Properties.VariableNames) && ~isempty(b.monkey_id)
    mm = b.monkey_id(1);
    return
end
if ismember('monkey', b.Properties.VariableNames) && ~isempty(b.monkey)
    m = b.monkey{1};
    if strcmpi(m,'Oz')
        mm = 1;
    elseif strcmpi(m,'Cicero')
        mm = 2;
    end
end
end

function llr = compute_llr(tbl, response_var, predictor_var)
llr = NaN;
if ~ismember(response_var, tbl.Properties.VariableNames) || ~ismember(predictor_var, tbl.Properties.VariableNames)
    return
end

resp = tbl.(response_var);
pred = tbl.(predictor_var);
valid = isfinite(resp) & isfinite(pred);
% Minimum requirements for fitting and comparing linear vs quadratic
% (with intercept terms):
%   - at least 4 valid points total (n >= 4)
%   - at least 3 unique predictor values for quadratic identifiability
if sum(valid) < 4 || numel(unique(pred(valid))) < 3
    return
end

sub = tbl(valid,:);
f1 = sprintf('%s ~ %s', response_var, predictor_var);
f2 = sprintf('%s ~ %s*%s', response_var, predictor_var, predictor_var);

% Primary path: match legacy use of fitlme/compare.
try
    lme1 = fitlme(sub, f1);
    lme2 = fitlme(sub, f2);
    cmp = compare(lme1, lme2);
    if ismember('LogLik', cmp.Properties.VariableNames) && height(cmp) >= 2
        llr = 2*(cmp.LogLik(2) - cmp.LogLik(1));
        return
    end
catch %#ok<CTCH>
end

% Fallback path: use fitlm log-likelihood if mixed-effects model is unavailable.
try
    lm1 = fitlm(sub, f1);
    lm2 = fitlm(sub, f2);
    if isprop(lm1,'LogLikelihood') && isprop(lm2,'LogLikelihood')
        llr = 2*(lm2.LogLikelihood - lm1.LogLikelihood);
    end
catch %#ok<CTCH>
end
end

function [rho, p] = compute_partial_base_corr(b, f)
% Compute partial Spearman correlation between baseline pupil and baseline
% FR controlling for trial time (mirrors unitSummaryPlot Section 1).
rho = NaN; p = NaN;
try
    t_b = b.fix_global_start_time;
    t_f = f.fix_global_start_time;
    pd_b = b.pupil_baseline;
    pd_f = f.pupil_baseline;
    fr_b = b.spike_baseline;
    if ismember('spike_fix_baseline', f.Properties.VariableNames)
        fr_f = f.spike_fix_baseline;
    elseif ismember('spike_baseline', f.Properties.VariableNames)
        fr_f = f.spike_baseline;
    else
        fr_f = nan(height(f),1);
    end
    all_t  = [t_b; t_f];
    all_pd = [pd_b; pd_f];
    all_fr = [fr_b; fr_f];
    valid  = isfinite(all_t) & isfinite(all_pd) & isfinite(all_fr);
    if sum(valid) < 4
        return
    end
    [rho, p] = partialcorr(all_fr(valid), all_pd(valid), all_t(valid), 'Type', 'Spearman');
catch %#ok<CTCH>
end
end
