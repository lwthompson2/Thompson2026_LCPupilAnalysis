function fig = plot_S1_summary(beep_tbl, fix_tbl)
% PLOT_S1_SUMMARY  Figure S1 summary row: 6 population-level scatter panels
% using baseline values as predictors (not drift residuals).
%
% Panel layout (1 row x 6 columns):
%   1. Baseline Pupil    vs  Evoked Pupil      (session-level)
%   2. Baseline FR       vs  Evoked FR         (unit-level)
%   3. Baseline Pupil    vs  Baseline FR       (unit-level, partial corr)
%   4. Evoked Pupil      vs  Evoked FR         (unit-level)
%   5. Baseline Pupil    vs  Evoked FR         (unit-level)
%   6. Evoked Pupil      vs  Baseline FR       (unit-level)

COL_BLUE  = [0 174 239] ./ 255;
COL_RED   = [237 28 36] ./ 255;
COL_GREY  = [0.5 0.5 0.5];
MARKER_SIZE = 50;
AXIS_FONT  = 12;
LABEL_FONT = 18;
TITLE_FONT = 14;

panel_colors = {COL_BLUE, COL_RED, COL_GREY, COL_GREY, COL_GREY, COL_GREY};

ylabels = {
    'Spearman Correlation', ...
    'Spearman Correlation', ...
    {'Spearman Partial','Correlation'}, ...
    'Spearman Correlation', ...
    'Spearman Correlation', ...
    'Spearman Correlation' ...
    };

summary_tbls = build_summary_tables(beep_tbl, fix_tbl);

titles = {
    {'Baseline vs.','Evoked Pupil'}, ...
    {'Baseline vs.','Evoked FR'}, ...
    {'Baseline vs.','Baseline FR'}, ...
    {'Evoked vs.','Evoked FR'}, ...
    {'Baseline vs.','Evoked FR'}, ...
    {'Evoked vs.','Baseline FR'} ...
    };

fig = figure('Name','Figure_S1_summary');
fig.Units   = 'inches';
fig.Position = [1 1 17.9483 3.6000];

T = tiledlayout(1, 6, 'TileSpacing', 'compact', 'Padding', 'compact');

for pp = 1:6
    ax = nexttile(T, pp);
    plot_summary_panel(ax, summary_tbls{pp}, panel_colors{pp}, pp, MARKER_SIZE);
    xlabel(ax, '');
    hy = ylabel(ax, ylabels{pp});
    set(hy, 'FontSize', LABEL_FONT);
    set(ax, 'FontSize', AXIS_FONT);
    title(ax, titles{pp}, 'FontSize', TITLE_FONT, 'FontWeight', 'normal');
    box(ax, 'off');
    yticks(ax, [-1, -0.5, 0.5, 1]);
end

end

% -------------------------------------------------------------------------
function summary_tbls = build_summary_tables(beep_tbl, fix_tbl)
summary_tbls = cell(6,1);

% Panel 1: session-level, baseline pupil vs evoked pupil
summary_tbls{1} = build_session_summary(beep_tbl, 'pupil_baseline', 'pupil_bs_evoked');

% Panels 2-6: unit-level
summary_tbls{2} = build_unit_summary(beep_tbl, fix_tbl, 2);
summary_tbls{3} = build_unit_summary(beep_tbl, fix_tbl, 3);
summary_tbls{4} = build_unit_summary(beep_tbl, fix_tbl, 4);
summary_tbls{5} = build_unit_summary(beep_tbl, fix_tbl, 5);
summary_tbls{6} = build_unit_summary(beep_tbl, fix_tbl, 6);
end

function tbl = build_session_summary(beep_tbl, x_var, y_var)
tbl = table('Size',[0 4], ...
    'VariableTypes', {'double','double','double','double'}, ...
    'VariableNames', {'session_id','monkey_id','r','p'});
if ~ismember('session_id', beep_tbl.Properties.VariableNames)
    return
end
session_ids = unique(beep_tbl.session_id);
for si = 1:numel(session_ids)
    sid = session_ids(si);
    rows = beep_tbl(beep_tbl.session_id == sid, :);
    if isempty(rows), continue; end
    if ismember('fix_global_start_time', rows.Properties.VariableNames)
        [~, first] = unique(rows.fix_global_start_time, 'stable');
        rows = rows(first, :);
    end
    try
        [r,p] = corr(rows.(x_var), rows.(y_var), 'type', 'Spearman', 'rows', 'complete');
    catch
        r = NaN; p = NaN;
    end
    tbl = [tbl; {sid, rows.monkey_id(1), r, p}]; %#ok<AGROW>
end
end

function tbl = build_unit_summary(beep_tbl, fix_tbl, panel_num)
tbl = table('Size',[0 4], ...
    'VariableTypes', {'double','double','double','double'}, ...
    'VariableNames', {'unit_id','monkey_id','r','p'});
unit_ids = unique(beep_tbl.unit_id);
for ui = 1:numel(unit_ids)
    uid = unit_ids(ui);
    b = beep_tbl(beep_tbl.unit_id == uid, :);
    f = fix_tbl(fix_tbl.unit_id == uid, :);
    if isempty(b), continue; end
    r = NaN; p = NaN;
    try
        switch panel_num
            case 2
                [r,p] = corr(b.spike_baseline, b.spike_bs_evoked, 'type','Spearman','rows','complete');
            case 3
                all_t  = [b.fix_global_start_time; f.fix_global_start_time];
                all_pd = [b.pupil_baseline; f.pupil_baseline];
                all_fr = [b.spike_baseline; f.spike_fix_baseline];
                [r,p]  = partialcorr(all_fr, all_pd, all_t, 'Type','Spearman','Rows','complete');
            case 4
                [r,p] = corr(b.pupil_bs_evoked, b.spike_bs_evoked, 'type','Spearman','rows','complete');
            case 5
                [r,p] = corr(b.pupil_baseline, b.spike_bs_evoked, 'type','Spearman','rows','complete');
            case 6
                [r,p] = corr(b.pupil_bs_evoked, b.spike_baseline, 'type','Spearman','rows','complete');
        end
    catch
        r = NaN; p = NaN;
    end
    tbl = [tbl; {uid, b.monkey_id(1), r, p}]; %#ok<AGROW>
end
end

% -------------------------------------------------------------------------
function plot_summary_panel(ax, tbl, point_color, panel_num, marker_sz)
x_start = [1, 5];
monkey_symbols = {'o','d'};
hold(ax, 'on');

for mm = 1:2
    m_rows  = tbl.monkey_id == mm;
    sig_idx    = m_rows & (tbl.p < 0.05);
    nonsig_idx = m_rows & ~(tbl.p < 0.05);

    scatter(ax, x_start(mm) + 2.*rand(sum(sig_idx),1),    tbl.r(sig_idx),    marker_sz, monkey_symbols{mm}, ...
        'MarkerFaceColor', point_color, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 1);
    scatter(ax, x_start(mm) + 2.*rand(sum(nonsig_idx),1), tbl.r(nonsig_idx), marker_sz, monkey_symbols{mm}, ...
        'MarkerFaceColor', point_color, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.25);

    vals = tbl.r(m_rows);
    if isempty(vals), continue; end

    try
        p_med = signrank(vals);
    catch
        p_med = NaN;
    end

    lw = 3;
    if ~isnan(p_med) && p_med < 0.05
        lw = 6;
    end

    med_col = 'k';
    if panel_num <= 2
        med_col = point_color;
    end

    med_val = median(vals, 'omitnan');
    plot(ax, x_start(mm) + [-0.5, 2.5], [med_val, med_val], '-', 'Color', med_col, 'LineWidth', lw);
end

plot(ax, [0,8], [0 0], ':k', 'LineWidth', 1.5);
xlim(ax, [0,8]);
ylim(ax, [-1,1]);
xticks(ax, [2, 6]);
xticklabels(ax, {'Oz', 'Ci'});
end
