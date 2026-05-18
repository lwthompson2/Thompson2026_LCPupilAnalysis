function fig = plot_03_population_new(LC_Beep_table, LC_Fix_table, stats_table, predictor_mode)
% PLOT_03_POPULATION_NEW  Figure 3: pooled across-session scatter plots.
%
% Layout: 2 rows (Oz, Cicero) x 6 columns.
% From left to right (per manuscript caption):
%   1. Baseline pupil  vs  Evoked pupil       (residuals / bs-subtracted)
%   2. Baseline LC     vs  Evoked LC           (residuals / bs-subtracted)
%   3. Baseline pupil  vs  Baseline LC         (drift residuals, beep+fix)
%   4. Evoked pupil    vs  Evoked LC           (bs-subtracted)
%   5. Baseline pupil  vs  Evoked LC           (residuals / bs-subtracted)
%   6. Evoked pupil    vs  Baseline LC         (bs-subtracted / residuals)
%
% Points colored by within-unit significance of baseline pupil ~ baseline LC:
%   green  = significant positive (p<0.05, rho>0)
%   orange = significant negative (p<0.05, rho<0)
%   grey   = all other data
%
% Regression lines drawn per colour group.

if nargin < 3 || isempty(stats_table)
    error('stats_table is required (run prepare_figure_analysis_tables first)');
end
if nargin < 4 || isempty(predictor_mode)
    predictor_mode = 'residual';
end

predictor_mode = lower(string(predictor_mode));
if predictor_mode == "baseline"
    p_base_var = 'pupil_baseline';
    s_base_beep_var = 'spike_baseline';
    s_base_fix_var = 'spike_fix_baseline';
    p_base_lbl = '(Z-scored value)';
    s_base_lbl = '(Z-scored value)';
else
    p_base_var = 'pupil_drift_residuals';
    s_base_beep_var = 'spike_drift_residuals';
    s_base_fix_var = 'spike_drift_residuals';
    p_base_lbl = '(Z-scored residuals)';
    s_base_lbl = '(Z-scored residuals)';
end

% -------------------------------------------------------------------------
% Colour definitions
% -------------------------------------------------------------------------
COL_GREY = [0.5  0.5  0.5];
COL_POS  = [22   153  81 ] ./ 255;   % green
COL_NEG  = [242  121  0  ] ./ 255;   % orange
COL_BLACK = [0 0 0];

MARKER_SIZE = 32;
AXIS_FONT = 11;
LABEL_FONT = 15;
ANNOT_FONT = 10;
LINE_WIDTH = 1.4;

% -------------------------------------------------------------------------
% Significance masks from stats_table (per unit_id)
% -------------------------------------------------------------------------
uid_all  = stats_table.unit_id;
p_all    = stats_table.p;
rho_all  = stats_table.base_p_base_FR;

sig_pos_uid = uid_all(isfinite(p_all) & p_all < 0.05 & isfinite(rho_all) & rho_all > 0);
sig_neg_uid = uid_all(isfinite(p_all) & p_all < 0.05 & isfinite(rho_all) & rho_all < 0);

% -------------------------------------------------------------------------
% Figure layout  (2 rows x 6 columns)
% -------------------------------------------------------------------------
num_monkeys = 2;
num_panels  = 6;
fig = figure('Name', 'Figure_03_pooled');
fig.Units    = 'inches';
fig.Position = [1 1 17.9483 5.7952];

t = tiledlayout(num_monkeys, num_panels, ...
    'TileSpacing', 'compact', 'Padding', 'compact');

monkey_marker = {'o', 'd'};   % Oz = circle, Cicero = diamond
monkey_name   = {'Oz', 'Cicero'};

for mm = 1:num_monkeys

    Lm_b = LC_Beep_table.monkey_id == mm;
    Lm_f = LC_Fix_table.monkey_id  == mm;

    Lm_sig_pos_b = Lm_b & ismember(LC_Beep_table.unit_id, sig_pos_uid);
    Lm_sig_neg_b = Lm_b & ismember(LC_Beep_table.unit_id, sig_neg_uid);
    Lm_sig_pos_f = Lm_f & ismember(LC_Fix_table.unit_id,  sig_pos_uid);
    Lm_sig_neg_f = Lm_f & ismember(LC_Fix_table.unit_id,  sig_neg_uid);

    for pp = 1:num_panels

        ax = nexttile(t, (mm-1)*num_panels + pp);
        hold(ax, 'on');

        % -----------------------------------------------------------------
        % Data extraction
        % -----------------------------------------------------------------
        switch pp
            case 1
                session_rows = unique_session_rows(LC_Beep_table(Lm_b,:));
                xs = session_rows.(p_base_var);
                ys = session_rows.pupil_bs_evoked;
                xs_pos = [];
                ys_pos = [];
                xs_neg = [];
                ys_neg = [];
                xl = {'Baseline Pupil'; p_base_lbl};
                yl = {'Evoked Pupil'; '(baseline subtracted)'};

            case 2
                [xs,     ys    ] = get_xy(LC_Beep_table, Lm_b,         s_base_beep_var, 'spike_bs_evoked');
                [xs_pos, ys_pos] = get_xy(LC_Beep_table, Lm_sig_pos_b, s_base_beep_var, 'spike_bs_evoked');
                [xs_neg, ys_neg] = get_xy(LC_Beep_table, Lm_sig_neg_b, s_base_beep_var, 'spike_bs_evoked');
                xl = {'Baseline FR'; s_base_lbl};
                yl = {'Evoked FR'; '(baseline subtracted)'};

            case 3
                % Includes beep+fix trials
                xs_b = LC_Beep_table.(p_base_var)(Lm_b);
                ys_b = LC_Beep_table.(s_base_beep_var)(Lm_b);
                xs_f = LC_Fix_table.(p_base_var)(Lm_f);
                ys_f = LC_Fix_table.(s_base_fix_var)(Lm_f);
                xs = [xs_b; xs_f];
                ys = [ys_b; ys_f];

                xs_pos = [LC_Beep_table.(p_base_var)(Lm_sig_pos_b); LC_Fix_table.(p_base_var)(Lm_sig_pos_f)];
                ys_pos = [LC_Beep_table.(s_base_beep_var)(Lm_sig_pos_b); LC_Fix_table.(s_base_fix_var)(Lm_sig_pos_f)];
                xs_neg = [LC_Beep_table.(p_base_var)(Lm_sig_neg_b); LC_Fix_table.(p_base_var)(Lm_sig_neg_f)];
                ys_neg = [LC_Beep_table.(s_base_beep_var)(Lm_sig_neg_b); LC_Fix_table.(s_base_fix_var)(Lm_sig_neg_f)];

                xl = {'Baseline Pupil'; p_base_lbl};
                yl = {'Baseline FR'; s_base_lbl};

            case 4
                [xs,     ys    ] = get_xy(LC_Beep_table, Lm_b,         'pupil_bs_evoked', 'spike_bs_evoked');
                [xs_pos, ys_pos] = get_xy(LC_Beep_table, Lm_sig_pos_b, 'pupil_bs_evoked', 'spike_bs_evoked');
                [xs_neg, ys_neg] = get_xy(LC_Beep_table, Lm_sig_neg_b, 'pupil_bs_evoked', 'spike_bs_evoked');
                xl = {'Evoked Pupil'; '(baseline subtracted)'};
                yl = {'Evoked FR'; '(baseline subtracted)'};

            case 5
                [xs,     ys    ] = get_xy(LC_Beep_table, Lm_b,         p_base_var, 'spike_bs_evoked');
                [xs_pos, ys_pos] = get_xy(LC_Beep_table, Lm_sig_pos_b, p_base_var, 'spike_bs_evoked');
                [xs_neg, ys_neg] = get_xy(LC_Beep_table, Lm_sig_neg_b, p_base_var, 'spike_bs_evoked');
                xl = {'Baseline Pupil'; p_base_lbl};
                yl = {'Evoked FR'; '(baseline subtracted)'};

            case 6
                [xs,     ys    ] = get_xy(LC_Beep_table, Lm_b,         'pupil_bs_evoked', s_base_beep_var);
                [xs_pos, ys_pos] = get_xy(LC_Beep_table, Lm_sig_pos_b, 'pupil_bs_evoked', s_base_beep_var);
                [xs_neg, ys_neg] = get_xy(LC_Beep_table, Lm_sig_neg_b, 'pupil_bs_evoked', s_base_beep_var);
                xl = {'Evoked Pupil'; '(baseline subtracted)'};
                yl = {'Baseline FR'; s_base_lbl};
        end

        mk = monkey_marker{mm};
        sz = MARKER_SIZE;

        % All data (grey, behind)
        Lg = isfinite(xs) & isfinite(ys);
        scatter(ax, xs(Lg), ys(Lg), sz, mk, ...
            'MarkerFaceColor', COL_GREY, 'MarkerEdgeColor', 'k', ...
            'MarkerFaceAlpha', 0.2, 'MarkerEdgeAlpha', 0.3);

        Lg_pos = isfinite(xs_pos) & isfinite(ys_pos);
        Lg_neg = isfinite(xs_neg) & isfinite(ys_neg);

        if pp ~= 1
            % Positive (green)
            scatter(ax, xs_pos(Lg_pos), ys_pos(Lg_pos), sz, mk, ...
                'MarkerFaceColor', COL_POS, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 1);

            % Negative (orange)
            scatter(ax, xs_neg(Lg_neg), ys_neg(Lg_neg), sz, mk, ...
                'MarkerFaceColor', COL_NEG, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 1);

            % Regression lines
            draw_lsline(ax, xs(Lg),          ys(Lg),          COL_GREY, LINE_WIDTH);
            draw_lsline(ax, xs_pos(Lg_pos),  ys_pos(Lg_pos),  COL_POS,  LINE_WIDTH);
            draw_lsline(ax, xs_neg(Lg_neg),  ys_neg(Lg_neg),  COL_NEG,  LINE_WIDTH);

            annotate_group_corrs(ax, ...
                {xs(Lg), xs_pos(Lg_pos), xs_neg(Lg_neg)}, ...
                {ys(Lg), ys_pos(Lg_pos), ys_neg(Lg_neg)}, ...
                {'All', 'Pos', 'Neg'}, ...
                {COL_BLACK, COL_POS, COL_NEG}, ...
                ANNOT_FONT, 0.03, 0.99, 'left');
        else
            draw_lsline(ax, xs(Lg), ys(Lg), COL_BLACK, LINE_WIDTH);
            annotate_group_corrs(ax, ...
                {xs(Lg)}, ...
                {ys(Lg)}, ...
                {'All'}, ...
                {COL_BLACK}, ...
                ANNOT_FONT, 0.97, 0.99, 'right');

            % Column 1: add monkey label in NW corner.
            if mm == 1
                monk_txt = 'Oz';
            else
                monk_txt = 'Ci';
            end
            text(ax, 0.03, 0.99, monk_txt, ...
                'Units', 'normalized', ...
                'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'top', ...
                'FontSize', ANNOT_FONT, ...
                'Color', COL_BLACK, ...
                'BackgroundColor', 'w', ...
                'Margin', 1);
        end

        set(ax, 'FontSize', AXIS_FONT);

        % Labels: x-labels only on bottom row, y-labels on all panels
        if mm == num_monkeys
            hx = xlabel(ax, xl);
            set(hx, 'FontSize', LABEL_FONT);
        else
            hx = xlabel(ax, '');
            set(hx, 'FontSize', LABEL_FONT);
        end
        hy = ylabel(ax, yl);
        set(hy, 'FontSize', LABEL_FONT);

        if pp == 1
            text(ax, -0.55, 0.5, monkey_name{mm}, 'Units', 'normalized', ...
                'Rotation', 90, 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', 'FontSize', LABEL_FONT);
        end

        axis(ax, 'square');
        box(ax, 'on');

        % Per-column axis adjustments for annotation fit
        xl_cur = xlim(ax);
        yl_cur = ylim(ax);
        xr = xl_cur(2) - xl_cur(1);
        yr = yl_cur(2) - yl_cur(1);
        if ~isfinite(xr) || xr <= 0, xr = 1; end
        if ~isfinite(yr) || yr <= 0, yr = 1; end

        switch pp
            case 1
                % NE + NW text in this panel: add both top and lateral room.
                xpad = max(0.6, 0.08*xr);
                ypad = max(2.0, 0.22*yr);
                xlim(ax, [xl_cur(1)-xpad, xl_cur(2)+xpad]);
                ylim(ax, [yl_cur(1), yl_cur(2)+ypad-1]);
            case 3
                % NW annotation plus denser point cloud: give extra left/top room.
                xpad_left = max(1.0, 0.10*xr);
                ypad = max(2.0, 0.18*yr);
                xlim(ax, [xl_cur(1)-xpad_left, xl_cur(2)]);
                ylim(ax, [yl_cur(1), yl_cur(2)+ypad]);
            case {2,4,5,6}
                % Top-left annotation stack in these panels.
                ypad = max(2.0, 0.18*yr);
                ylim(ax, [yl_cur(1), yl_cur(2)+ypad]);
        end

        % Targeted panel-specific tweaks requested by user:
        % row 2 col 2, row 2 col 5, and both rows col 6.
        yl_tuned = ylim(ax);
        if (mm == 2 && pp == 2)
            ylim(ax, [yl_tuned(1), yl_tuned(2) + max(1.5, 0.10*yr)]);
        end
        yl_tuned = ylim(ax);
        if (mm == 2 && pp == 5)
            ylim(ax, [yl_tuned(1), yl_tuned(2) + max(1.5, 0.10*yr)]);
        end
        yl_tuned = ylim(ax);
        if (pp == 6)
            ylim(ax, [yl_tuned(1), yl_tuned(2) + max(1.2, 0.08*yr) - 1]);
        end
    end
end

end

% -------------------------------------------------------------------------
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

% -------------------------------------------------------------------------
function draw_lsline(ax, xs, ys, col, line_width)
Lg = isfinite(xs) & isfinite(ys);
if sum(Lg) < 2
    return
end
p = polyfit(xs(Lg), ys(Lg), 1);
xl = xlim(ax);
line(ax, xl, polyval(p, xl), 'Color', col, 'LineWidth', line_width, 'HandleVisibility', 'off');
end

% -------------------------------------------------------------------------
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

% -------------------------------------------------------------------------
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
        pstr = '\itp\rm = n/a';
    elseif p < 0.001
        pstr = '\itp\rm < 0.001';
    else
        pstr = sprintf('\\itp\\rm = %.3f', p);
    end

    if isnan(rho)
        txt = sprintf('%s', pstr);
    else
        txt = sprintf('rho = %.2f, %s', rho, pstr);
    end

    text(ax, x_anchor, y_top - (ii-1)*dy, txt, ...
        'Units', 'normalized', ...
        'HorizontalAlignment', h_align, ...
        'VerticalAlignment', 'top', ...
        'FontSize', font_size, ...
        'Interpreter', 'tex', ...
        'Color', colors{ii}, ...
        'BackgroundColor', 'w', ...
        'Margin', 1);
end
end
