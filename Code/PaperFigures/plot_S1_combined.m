function fig = plot_S1_combined(beep_raw, fix_raw, stats_raw, beep_z, fix_z, stats_z)
% PLOT_S1_COMBINED  Supplemental Figure S1 with baseline-value relationships.
% Layout:
%   Row 1: Figure 2-style summary panels (6 relationships)
%   Row 2: S2-style LLR histograms aligned to columns 1,2,5,6
%   Row 3: Figure 3-style pooled panels for Oz (6 panels)
%   Row 4: Figure 3-style pooled panels for Cicero (6 panels)

if nargin < 6
    error('plot_S1_combined requires raw/z tables and stats.');
end

COL_GREY = [0.5 0.5 0.5];
COL_POS = [22 153 81] ./ 255;
COL_NEG = [242 121 0] ./ 255;
COL_BLUE = [0 174 239] ./ 255;
COL_RED = [237 28 36] ./ 255;
COL_BLACK = [0 0 0];

fig = figure('Name', 'Figure_S1_combined');
fig.Units = 'inches';
fig.Position = [1 1 17.9483 11.2000];

T = tiledlayout(4, 6, 'TileSpacing', 'compact', 'Padding', 'compact');

% ---------------------------------------------------------------------
% Row 1: Figure 2 summary-style panels using baseline-value relationships.
% ---------------------------------------------------------------------
summary_tbl = build_s1_summary_tables(beep_raw, fix_raw);
panel_colors = {COL_BLUE, COL_RED, COL_GREY, COL_GREY, COL_GREY, COL_GREY};
row1_xlabels = {
    {'Baseline Pupil','(value)'}, ...
    {'Baseline FR','(value)'}, ...
    {'Baseline Pupil','(value)'}, ...
    {'Evoked Pupil','(baseline subtracted)'}, ...
    {'Baseline Pupil','(value)'}, ...
    {'Evoked Pupil','(baseline subtracted)'} ...
    };
row1_ylabels = {
    {'Spearman','Correlation'}, ...
    {'Spearman','Correlation'}, ...
    {'Spearman Partial','Correlation'}, ...
    {'Spearman','Correlation'}, ...
    {'Spearman','Correlation'}, ...
    {'Spearman','Correlation'} ...
    };

for pp = 1:6
    ax = nexttile(T, pp);
    plot_population_summary_panel(ax, summary_tbl{pp}, panel_colors{pp}, pp);
    xlabel(ax, row1_xlabels{pp});
    ylabel(ax, row1_ylabels{pp});
    title(ax, '');
end

% ---------------------------------------------------------------------
% Row 2: S2 LLR panels aligned to corresponding summary relationships.
%   Cols 1,2,5,6 map to pEvoked~pBase, sEvoked~sBase, sEvoked~pBase,
%   and pEvoked~sBase respectively. Cols 3-4 intentionally blank.
% ---------------------------------------------------------------------
crit = 3.841;
for pp = 1:6
    tile_idx = 6 + pp;
    ax = nexttile(T, tile_idx);
    switch pp
        case 1
            plot_llr_hist_panel(ax, stats_raw.pEvoked_v_pBase_LLR, stats_raw.monkey_id, crit, 'pEvoked vs pBase LLR');
            xlabel(ax, 'LLR');
            ylabel(ax, 'Number of Sessions');
        case 2
            plot_llr_hist_panel(ax, stats_raw.sEvoked_v_sBase_LLR, stats_raw.monkey_id, crit, 'sEvoked vs sBase LLR');
            xlabel(ax, 'LLR');
            ylabel(ax, 'Number of Units');
        case 5
            plot_llr_hist_panel(ax, stats_raw.sEvoked_v_pBase_LLR, stats_raw.monkey_id, crit, 'sEvoked vs pBase LLR');
            xlabel(ax, 'LLR');
            ylabel(ax, 'Number of Units');
        case 6
            plot_llr_hist_panel(ax, stats_raw.pEvoked_v_sBase_LLR, stats_raw.monkey_id, crit, 'pEvoked vs sBase LLR');
            xlabel(ax, 'LLR');
            ylabel(ax, 'Number of Units');
        otherwise
            axis(ax, 'off');
    end
end

% ---------------------------------------------------------------------
% Rows 3-4: Figure 3 pooled-style panels using baseline values.
% ---------------------------------------------------------------------
uid_all = stats_z.unit_id;
p_all = stats_z.p;
rho_all = stats_z.base_p_base_FR;
sig_pos_uid = uid_all(isfinite(p_all) & p_all < 0.05 & isfinite(rho_all) & rho_all > 0);
sig_neg_uid = uid_all(isfinite(p_all) & p_all < 0.05 & isfinite(rho_all) & rho_all < 0);

monkey_names = {'Oz', 'Cicero'};
monkey_markers = {'o', 'd'};

for mm = 1:2
    Lm_b = beep_z.monkey_id == mm;
    Lm_f = fix_z.monkey_id == mm;

    Lm_sig_pos_b = Lm_b & ismember(beep_z.unit_id, sig_pos_uid);
    Lm_sig_neg_b = Lm_b & ismember(beep_z.unit_id, sig_neg_uid);
    Lm_sig_pos_f = Lm_f & ismember(fix_z.unit_id, sig_pos_uid);
    Lm_sig_neg_f = Lm_f & ismember(fix_z.unit_id, sig_neg_uid);

    for pp = 1:6
        tile_idx = 12 + (mm-1)*6 + pp;
        ax = nexttile(T, tile_idx);
        hold(ax, 'on');

        [xs, ys, xs_pos, ys_pos, xs_neg, ys_neg, xl, yl] = pooled_panel_data_baseline( ...
            beep_z, fix_z, pp, Lm_b, Lm_f, Lm_sig_pos_b, Lm_sig_neg_b, Lm_sig_pos_f, Lm_sig_neg_f);

        Lg = isfinite(xs) & isfinite(ys);
        scatter(ax, xs(Lg), ys(Lg), 30, monkey_markers{mm}, ...
            'MarkerFaceColor', COL_GREY, 'MarkerEdgeColor', 'k', ...
            'MarkerFaceAlpha', 0.2, 'MarkerEdgeAlpha', 0.3);

        if pp ~= 1
            Lg_pos = isfinite(xs_pos) & isfinite(ys_pos);
            Lg_neg = isfinite(xs_neg) & isfinite(ys_neg);

            scatter(ax, xs_pos(Lg_pos), ys_pos(Lg_pos), 30, monkey_markers{mm}, ...
                'MarkerFaceColor', COL_POS, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 1);
            scatter(ax, xs_neg(Lg_neg), ys_neg(Lg_neg), 30, monkey_markers{mm}, ...
                'MarkerFaceColor', COL_NEG, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 1);

            draw_lsline(ax, xs(Lg), ys(Lg), COL_GREY, 1.4);
            draw_lsline(ax, xs_pos(Lg_pos), ys_pos(Lg_pos), COL_POS, 1.4);
            draw_lsline(ax, xs_neg(Lg_neg), ys_neg(Lg_neg), COL_NEG, 1.4);

            annotate_group_corrs(ax, ...
                {xs(Lg), xs_pos(Lg_pos), xs_neg(Lg_neg)}, ...
                {ys(Lg), ys_pos(Lg_pos), ys_neg(Lg_neg)}, ...
                {'All', 'Pos', 'Neg'}, ...
                {COL_BLACK, COL_POS, COL_NEG}, 9, 0.03, 0.98, 'left');
        else
            draw_lsline(ax, xs(Lg), ys(Lg), COL_BLACK, 1.4);
            annotate_group_corrs(ax, {xs(Lg)}, {ys(Lg)}, {'All'}, {COL_BLACK}, 9, 0.97, 0.98, 'right');
            text(ax, 0.03, 0.98, monkey_names{mm}, ...
                'Units', 'normalized', ...
                'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'top', ...
                'FontSize', 9, ...
                'Color', COL_BLACK, ...
                'BackgroundColor', 'w', ...
                'Margin', 1);
        end

        if mm == 2
            xlabel(ax, xl);
        else
            xlabel(ax, '');
        end
        ylabel(ax, yl);
        set(ax, 'FontSize', 8);
        axis(ax, 'square');
        box(ax, 'on');

        if pp == 1
            text(ax, -0.48, 0.5, monkey_names{mm}, 'Units', 'normalized', ...
                'Rotation', 90, 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', 'FontSize', 11);
        end
    end
end

fig = gcf;
end

function summary_tbl = build_s1_summary_tables(beep_tbl, fix_tbl)
summary_tbl = cell(6,1);
summary_tbl{1} = build_session_summary(beep_tbl, 'pupil_baseline', 'pupil_bs_evoked');
summary_tbl{2} = build_unit_summary_s1(beep_tbl, fix_tbl, 2);
summary_tbl{3} = build_unit_summary_s1(beep_tbl, fix_tbl, 3);
summary_tbl{4} = build_unit_summary_s1(beep_tbl, fix_tbl, 4);
summary_tbl{5} = build_unit_summary_s1(beep_tbl, fix_tbl, 5);
summary_tbl{6} = build_unit_summary_s1(beep_tbl, fix_tbl, 6);
end

function summary_tbl = build_session_summary(beep_tbl, x_var, y_var)
if ~ismember('session_id', beep_tbl.Properties.VariableNames)
    summary_tbl = table('Size',[0 4], ...
        'VariableTypes', {'double','double','double','double'}, ...
        'VariableNames', {'session_id','monkey_id','r','p'});
    return
end

session_ids = unique(beep_tbl.session_id);
summary_tbl = table('Size',[0 4], ...
    'VariableTypes', {'double','double','double','double'}, ...
    'VariableNames', {'session_id','monkey_id','r','p'});

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
    summary_tbl = [summary_tbl; {sid, rows.monkey_id(1), r, p}]; %#ok<AGROW>
end
end

function summary_tbl = build_unit_summary_s1(beep_tbl, fix_tbl, panel_num)
unit_ids = unique(beep_tbl.unit_id);
summary_tbl = table('Size',[0 4], ...
    'VariableTypes', {'double','double','double','double'}, ...
    'VariableNames', {'unit_id','monkey_id','r','p'});

for ui = 1:numel(unit_ids)
    uid = unit_ids(ui);
    b = beep_tbl(beep_tbl.unit_id == uid, :);
    f = fix_tbl(fix_tbl.unit_id == uid, :);
    if isempty(b)
        continue
    end

    r = NaN;
    p = NaN;
    try
        switch panel_num
            case 2
                [r,p] = corr(b.spike_baseline, b.spike_bs_evoked, 'type', 'Spearman', 'rows', 'complete');
            case 3
                all_t = [b.fix_global_start_time; f.fix_global_start_time];
                all_pd = [b.pupil_baseline; f.pupil_baseline];
                all_fr = [b.spike_baseline; f.spike_fix_baseline];
                [r,p] = partialcorr(all_fr, all_pd, all_t, 'Type', 'Spearman', 'Rows', 'complete');
            case 4
                [r,p] = corr(b.pupil_bs_evoked, b.spike_bs_evoked, 'type', 'Spearman', 'rows', 'complete');
            case 5
                [r,p] = corr(b.pupil_baseline, b.spike_bs_evoked, 'type', 'Spearman', 'rows', 'complete');
            case 6
                [r,p] = corr(b.pupil_bs_evoked, b.spike_baseline, 'type', 'Spearman', 'rows', 'complete');
        end
    catch
        r = NaN;
        p = NaN;
    end

    summary_tbl = [summary_tbl; {uid, b.monkey_id(1), r, p}]; %#ok<AGROW>
end
end

function plot_population_summary_panel(ax, summary_tbl, point_color, panel_num)
scatter_m_sz = 45;
plot_options.monkey_symbols = {'o','d'};
x_start = [1,5];

hold(ax, 'on');
for mm = 1:2
    m_rows = summary_tbl.monkey_id == mm;
    sig_idx = summary_tbl.p < 0.05 & m_rows;
    nonsig_idx = ~(summary_tbl.p < 0.05) & m_rows;

    scatter(ax, x_start(mm) + (3-1).*rand(sum(sig_idx),1), summary_tbl.r(sig_idx), scatter_m_sz, plot_options.monkey_symbols{mm}, ...
        'MarkerFaceColor', point_color, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 1);
    scatter(ax, x_start(mm) + (3-1).*rand(sum(nonsig_idx),1), summary_tbl.r(nonsig_idx), scatter_m_sz, plot_options.monkey_symbols{mm}, ...
        'MarkerFaceColor', point_color, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.25);

    vals = summary_tbl.r(m_rows);
    if isempty(vals)
        continue
    end

    try
        p_med = signrank(vals);
    catch
        p_med = NaN;
    end

    line_width = 3;
    if ~isnan(p_med) && p_med < 0.05
        line_width = 6;
    end

    med_line_color = 'k';
    if panel_num <= 2
        med_line_color = point_color;
    end

    med_val = median(vals, 'omitnan');
    plot(ax, x_start(mm) + [-0.5, 2.5], [med_val, med_val], '-', 'Color', med_line_color, 'LineWidth', line_width);
end

plot(ax, [0,8], [0 0], ':k', 'LineWidth', 1.5);
xlim(ax, [0,8]);
ylim(ax, [-1,1]);
xticks(ax, []);
box(ax, 'on');
axis(ax, 'square');
end

function plot_llr_hist_panel(ax, values, monkey_ids, crit, ttl)
histogram(ax, values, 'BinWidth', 1, 'FaceColor', [0.5 0.5 0.5]);
hold(ax, 'on');
xline(ax, crit, 'k-');
title(ax, ttl);

panel_filter = true(size(values));
if contains(ttl, 'pEvoked vs pBase')
    % Session-level (one per unique session id) is already precomputed in stats table.
    panel_filter = isfinite(values);
end
annotate_counts_by_monkey(ax, values, monkey_ids, panel_filter, crit);
end

function annotate_counts_by_monkey(ax, values, monkey_ids, panel_filter, crit)
oz_mask = panel_filter & (monkey_ids == 1);
ci_mask = panel_filter & (monkey_ids == 2);

oz_total = sum(oz_mask);
oz_inc = sum(isfinite(values(oz_mask)));
oz_sig = sum(values(oz_mask) > crit, 'omitnan');

ci_total = sum(ci_mask);
ci_inc = sum(isfinite(values(ci_mask)));
ci_sig = sum(values(ci_mask) > crit, 'omitnan');

txt = sprintf(['Oz Inc N = %d/%d\n' ...
               'Oz >3.841 N = %d/%d\n' ...
               'Ci Inc N = %d/%d\n' ...
               'Ci >3.841 N = %d/%d'], ...
               oz_inc, oz_total, oz_sig, max(oz_inc,1), ci_inc, ci_total, ci_sig, max(ci_inc,1));

text(ax, 0.97, 0.97, txt, ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'top', ...
    'FontSize', 8, ...
    'BackgroundColor', 'w', ...
    'Margin', 1);
end

function [xs, ys, xs_pos, ys_pos, xs_neg, ys_neg, xl, yl] = pooled_panel_data_baseline( ...
    beep_tbl, fix_tbl, panel_num, Lm_b, Lm_f, Lm_sig_pos_b, Lm_sig_neg_b, Lm_sig_pos_f, Lm_sig_neg_f)

switch panel_num
    case 1
        session_rows = unique_session_rows(beep_tbl(Lm_b,:));
        xs = session_rows.pupil_baseline;
        ys = session_rows.pupil_bs_evoked;
        xs_pos = [];
        ys_pos = [];
        xs_neg = [];
        ys_neg = [];
        xl = {'Baseline Pupil'; '(Z-scored value)'};
        yl = {'Evoked Pupil'; '(baseline subtracted)'};

    case 2
        [xs, ys] = get_xy(beep_tbl, Lm_b, 'spike_baseline', 'spike_bs_evoked');
        [xs_pos, ys_pos] = get_xy(beep_tbl, Lm_sig_pos_b, 'spike_baseline', 'spike_bs_evoked');
        [xs_neg, ys_neg] = get_xy(beep_tbl, Lm_sig_neg_b, 'spike_baseline', 'spike_bs_evoked');
        xl = {'Baseline FR'; '(Z-scored value)'};
        yl = {'Evoked FR'; '(baseline subtracted)'};

    case 3
        xs = [beep_tbl.pupil_baseline(Lm_b); fix_tbl.pupil_baseline(Lm_f)];
        ys = [beep_tbl.spike_baseline(Lm_b); fix_tbl.spike_fix_baseline(Lm_f)];

        xs_pos = [beep_tbl.pupil_baseline(Lm_sig_pos_b); fix_tbl.pupil_baseline(Lm_sig_pos_f)];
        ys_pos = [beep_tbl.spike_baseline(Lm_sig_pos_b); fix_tbl.spike_fix_baseline(Lm_sig_pos_f)];
        xs_neg = [beep_tbl.pupil_baseline(Lm_sig_neg_b); fix_tbl.pupil_baseline(Lm_sig_neg_f)];
        ys_neg = [beep_tbl.spike_baseline(Lm_sig_neg_b); fix_tbl.spike_fix_baseline(Lm_sig_neg_f)];

        xl = {'Baseline Pupil'; '(Z-scored value)'};
        yl = {'Baseline FR'; '(Z-scored value)'};

    case 4
        [xs, ys] = get_xy(beep_tbl, Lm_b, 'pupil_bs_evoked', 'spike_bs_evoked');
        [xs_pos, ys_pos] = get_xy(beep_tbl, Lm_sig_pos_b, 'pupil_bs_evoked', 'spike_bs_evoked');
        [xs_neg, ys_neg] = get_xy(beep_tbl, Lm_sig_neg_b, 'pupil_bs_evoked', 'spike_bs_evoked');
        xl = {'Evoked Pupil'; '(baseline subtracted)'};
        yl = {'Evoked FR'; '(baseline subtracted)'};

    case 5
        [xs, ys] = get_xy(beep_tbl, Lm_b, 'pupil_baseline', 'spike_bs_evoked');
        [xs_pos, ys_pos] = get_xy(beep_tbl, Lm_sig_pos_b, 'pupil_baseline', 'spike_bs_evoked');
        [xs_neg, ys_neg] = get_xy(beep_tbl, Lm_sig_neg_b, 'pupil_baseline', 'spike_bs_evoked');
        xl = {'Baseline Pupil'; '(Z-scored value)'};
        yl = {'Evoked FR'; '(baseline subtracted)'};

    case 6
        [xs, ys] = get_xy(beep_tbl, Lm_b, 'pupil_bs_evoked', 'spike_baseline');
        [xs_pos, ys_pos] = get_xy(beep_tbl, Lm_sig_pos_b, 'pupil_bs_evoked', 'spike_baseline');
        [xs_neg, ys_neg] = get_xy(beep_tbl, Lm_sig_neg_b, 'pupil_bs_evoked', 'spike_baseline');
        xl = {'Evoked Pupil'; '(baseline subtracted)'};
        yl = {'Baseline FR'; '(Z-scored value)'};

    otherwise
        xs = []; ys = []; xs_pos = []; ys_pos = []; xs_neg = []; ys_neg = [];
        xl = ''; yl = '';
end
end

function [xs, ys] = get_xy(tbl, mask, xvar, yvar)
if ismember(xvar, tbl.Properties.VariableNames)
    xs = tbl.(xvar)(mask);
else
    xs = nan(sum(mask), 1);
end
if ismember(yvar, tbl.Properties.VariableNames)
    ys = tbl.(yvar)(mask);
else
    ys = nan(sum(mask), 1);
end
end

function draw_lsline(ax, xs, ys, col, line_width)
Lg = isfinite(xs) & isfinite(ys);
if sum(Lg) < 2
    return
end
p = polyfit(xs(Lg), ys(Lg), 1);
xl = xlim(ax);
line(ax, xl, polyval(p, xl), 'Color', col, 'LineWidth', line_width, 'HandleVisibility', 'off');
end

function tbl_out = unique_session_rows(tbl_in)
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

function annotate_group_corrs(ax, xs_groups, ys_groups, labels, colors, font_size, x_anchor, y_top, h_align)
if nargin < 7 || isempty(x_anchor), x_anchor = 0.03; end
if nargin < 8 || isempty(y_top), y_top = 0.99; end
if nargin < 9 || isempty(h_align), h_align = 'left'; end

dy = 0.10;
for ii = numel(labels):-1:1
    xs = xs_groups{ii};
    ys = ys_groups{ii};
    if numel(xs) >= 3 && numel(ys) >= 3
        try
            [rho, p] = corr(xs, ys, 'type', 'Spearman', 'rows', 'complete');
        catch
            rho = NaN;
            p = NaN;
        end
    else
        rho = NaN;
        p = NaN;
    end

    if isnan(p)
        pstr = 'p=n/a';
    elseif p < 0.001
        pstr = 'p<0.001';
    else
        pstr = sprintf('p=%.3f', p);
    end

    if isnan(rho)
        txt = sprintf('%s', pstr);
    else
        txt = sprintf('rho=%.2f, %s', rho, pstr);
    end

    text(ax, x_anchor, y_top - (ii-1)*dy, txt, ...
        'Units', 'normalized', ...
        'HorizontalAlignment', h_align, ...
        'VerticalAlignment', 'top', ...
        'FontSize', font_size, ...
        'Color', colors{ii}, ...
        'BackgroundColor', 'w', ...
        'Margin', 1);
end
end
