function fig = plot_S4_range_impact(LC_Beep_table, LC_Fix_table)
% PLOT_S4_RANGE_IMPACT  Supplemental panel for range-impact relationships.
% Panel 1: range of evoked LC vs rho(baseline pupil, evoked LC)
% Panel 2: range of evoked pupil vs rho(baseline LC, evoked pupil)

if nargin < 2
    error('Provide LC_Beep_table and LC_Fix_table');
end

row5_tbl = build_unit_summary(LC_Beep_table, LC_Fix_table, 5);
row6_tbl = build_unit_summary(LC_Beep_table, LC_Fix_table, 6);
range_tbl = build_evoked_range_by_unit(LC_Beep_table);

data5 = innerjoin(row5_tbl(:, {'unit_id','monkey_id','r'}), ...
    range_tbl(:, {'unit_id','monkey_id','range_spike_evoked'}), ...
    'Keys', {'unit_id','monkey_id'});
data6 = innerjoin(row6_tbl(:, {'unit_id','monkey_id','r'}), ...
    range_tbl(:, {'unit_id','monkey_id','range_pupil_evoked'}), ...
    'Keys', {'unit_id','monkey_id'});

fig = figure('Name', 'Figure_S4_range_impact');
t = tiledlayout(1,2, 'TileSpacing', 'compact', 'Padding', 'compact');
t.Title.String = 'Range-Impact Analyses';
t.Title.FontWeight = 'bold';

ax1 = nexttile;
plot_range_panel(ax1, data5, 'range_spike_evoked', ...
    {'Evoked LC FR Range'}, ...
    {'Baseline Pupil vs Evoked LC'}, true);

ax2 = nexttile;
plot_range_panel(ax2, data6, 'range_pupil_evoked', ...
    {'Evoked Pupil Range'}, ...
    {'Baseline LC vs Evoked Pupil'}, false);

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

function summary_tbl = build_unit_summary(LC_Beep_table, LC_Fix_table, row_num)
unit_ids = unique(LC_Beep_table.unit_id);
summary_tbl = table('Size',[0 4], ...
    'VariableTypes', {'double','double','double','double'}, ...
    'VariableNames', {'unit_id','monkey_id','r','p'});

for ui = 1:numel(unit_ids)
    uid = unit_ids(ui);
    beep = LC_Beep_table(LC_Beep_table.unit_id == uid, :);
    fixx = LC_Fix_table(LC_Fix_table.unit_id == uid, :);
    if isempty(beep)
        continue;
    end

    r = NaN;
    p = NaN;
    try
        switch row_num
            case 5
                [r,p] = corr(beep.pupil_drift_residuals, beep.spike_bs_evoked, ...
                    'type', 'Spearman', 'rows', 'complete');
            case 6
                [r,p] = corr(beep.pupil_bs_evoked, beep.spike_drift_residuals, ...
                    'type', 'Spearman', 'rows', 'complete');
            otherwise
                continue
        end
    catch
        r = NaN;
        p = NaN;
    end

    summary_tbl = [summary_tbl; {uid, beep.monkey_id(1), r, p}]; %#ok<AGROW>
end
end

function plot_range_panel(ax, tbl, range_var, x_label_lines, title_lines, put_stats_right)
axes(ax); %#ok<LAXES>
hold(ax, 'on');

colors = [0.50 0.30 0.75; 0.48 0.78 0.46];
markers = {'o', 'd'};
labels = {'Oz', 'Ci'};

for mm = 1:2
    idx = tbl.monkey_id == mm & isfinite(tbl.(range_var)) & isfinite(tbl.r);
    xs = tbl.(range_var)(idx);
    ys = tbl.r(idx);

    scatter(ax, xs, ys, 46, markers{mm}, ...
        'MarkerFaceColor', colors(mm,:), ...
        'MarkerEdgeColor', 'k', ...
        'MarkerFaceAlpha', 0.7, ...
        'DisplayName', labels{mm});

    if numel(xs) >= 3
        pfit = polyfit(xs, ys, 1);
        xline = linspace(min(xs), max(xs), 100);
        yline = polyval(pfit, xline);
        plot(ax, xline, yline, '-', 'Color', colors(mm,:), 'LineWidth', 2, ...
            'HandleVisibility', 'off');

        [rho, p] = corr(xs, ys, 'type', 'Spearman', 'rows', 'complete');
        txt = sprintf('%s: rho = %.2f, p = %.3g', labels{mm}, rho, p);
        if put_stats_right
            x_pos = 0.98;
            h_align = 'right';
        else
            x_pos = 0.02;
            h_align = 'left';
        end
        text(ax, x_pos, 0.96 - 0.09*(mm-1), txt, 'Units', 'normalized', ...
            'Color', colors(mm,:), 'FontSize', 9, 'FontWeight', 'bold', ...
            'HorizontalAlignment', h_align, 'VerticalAlignment', 'top');
    end
end

xl = xlim(ax);
plot(ax, xl, [0 0], ':k', 'LineWidth', 1.2, 'HandleVisibility', 'off');
box(ax, 'on');
set(ax, 'FontName', 'Arial', 'FontSize', 12, 'LineWidth', 1.5);
xlabel(ax, x_label_lines);
ylabel(ax, {'Spearman Correlation'});
title(ax, title_lines, 'FontWeight', 'normal');
end
