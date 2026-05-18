function fig = plot_02_examples_new(LC_Beep_table, LC_Fix_table, example_neurons)
% PLOT_02_EXAMPLES_NEW  New, self-contained plotting function for Figure 2 examples.
%   fig = plot_02_examples_new(LC_Beep_table, LC_Fix_table, example_neurons)
% example_neurons: n x 3 matrix [monkey_id, session_id?, unit_id]

if nargin < 3 || isempty(example_neurons)
    % default examples (unit ids taken from legacy script)
    example_neurons = [1, 18, 10; 1, 19, 25; 2, 5, 60; 2, 27, 97];
end

n_examples = size(example_neurons,1);
fig = figure('Name','Figure_02_examples_new');
fig.Units = 'inches';
fig.Position = [1 1 10.5233 12.5313];
TITLE_FONT = 9;

row_xlabels = {
    'Baseline Pupil (residuals)', ...
    'Baseline FR (residuals)', ...
    'Baseline Pupil (residuals)', ...
    'Evoked Pupil (baseline subtracted)', ...
    'Baseline Pupil (residuals)', ...
    'Evoked Pupil (baseline subtracted)' ...
    };

row_ylabels = {
    {'Evoked Pupil','(baseline subtracted)'}, ...
    {'Evoked FR','(baseline subtracted)'}, ...
    {'Baseline FR','(residuals)'}, ...
    {'Evoked FR','(baseline subtracted)'}, ...
    {'Evoked FR','(baseline subtracted)'}, ...
    {'Baseline FR','(residuals)'} ...
    };

row_colors = {
    [0 174 239]./255, ...
    [237 28 36]./255, ...
    [0.5 0.5 0.5], ...
    [0.5 0.5 0.5], ...
    [0.5 0.5 0.5], ...
    [0.5 0.5 0.5] ...
    };

% Layout: 6 rows x (n_examples + 1) columns (last column reserved)
T = tiledlayout(6, n_examples+1, 'TileSpacing','compact','Padding','compact'); %#ok<NASGU>

for ex = 1:n_examples
    unit_id = example_neurons(ex,3);
    % select rows for this unit
    beep_rows = LC_Beep_table(LC_Beep_table.unit_id==unit_id,:);
    fix_rows = LC_Fix_table(LC_Fix_table.unit_id==unit_id,:);
    all_trial_times = [beep_rows.fix_global_start_time; fix_rows.fix_global_start_time];
    all_baseline_pd = [beep_rows.pupil_baseline; fix_rows.pupil_fix_baseline];
    all_baseline_FR = [beep_rows.spike_baseline; fix_rows.spike_fix_baseline];

    % Fit drifts across all trials for this unit
    spike_drift = fitlm(all_trial_times, all_baseline_FR);
    pupil_drift = fitlm(all_trial_times, all_baseline_pd);

    % Evoked / baseline-subtracted values (beep trials)
    if ismember('pupil_bs_evoked', beep_rows.Properties.VariableNames)
        sub_p_evoked = beep_rows.pupil_bs_evoked;
    elseif ismember('pupil_evoked', beep_rows.Properties.VariableNames) && ismember('pupil_baseline', beep_rows.Properties.VariableNames)
        sub_p_evoked = beep_rows.pupil_evoked - beep_rows.pupil_baseline;
    else
        sub_p_evoked = [];
    end

    if ismember('spike_bs_evoked', beep_rows.Properties.VariableNames)
        sub_FR_evoked = beep_rows.spike_bs_evoked;
    elseif ismember('spike_evoked', beep_rows.Properties.VariableNames) && ismember('spike_baseline', beep_rows.Properties.VariableNames)
        sub_FR_evoked = beep_rows.spike_evoked - beep_rows.spike_baseline;
    else
        sub_FR_evoked = [];
    end

    % Row 1: Evoked pupil (y) vs baseline pupil residuals (x)
    nexttile((0)*(n_examples+1) + ex); hold off;
    if ~isempty(sub_p_evoked)
        x = pupil_drift.Residuals.Raw(1:height(beep_rows));
        y = sub_p_evoked;
        point_color = row_colors{1};
        plot(x, y, 'ok','MarkerFaceColor',point_color); hold on;
        lm = fitlm(x, y);
        h = plot(lm);
        h(1).Marker = 'o'; h(1).MarkerFaceColor = point_color; h(1).MarkerEdgeColor = 'k';
        h(2).Color = point_color; h(2).LineWidth = 1.5;
        h(3).Color = point_color; h(3).LineStyle = '--';
        h(4).Color = point_color; h(4).LineStyle = '--';
        [rho1, p1] = corr_spearman_local(x, y);
        xlabel('');
        if ex == 1
            ylabel(row_ylabels{1});
        else
            ylabel('');
        end
        if ex == 3
            add_row_xlabel(gca, row_xlabels{1});
        end
        title(format_corr_title_local(rho1, p1), 'FontWeight', 'normal', 'FontSize', TITLE_FONT);
        pbaspect([1 1 1]);
        legend('off');
    end

    % Row 2: Evoked LC FR (y) vs baseline LC residuals (x)
    nexttile((1)*(n_examples+1) + ex); hold off;
    if ~isempty(sub_FR_evoked)
        x2 = spike_drift.Residuals.Raw(1:height(beep_rows));
        y2 = sub_FR_evoked;
        point_color = row_colors{2};
        plot(x2, y2, 'ok','MarkerFaceColor',point_color); hold on;
        lm2 = fitlm(x2, y2);
        h2 = plot(lm2);
        h2(1).Marker = 'o'; h2(1).MarkerFaceColor = point_color; h2(1).MarkerEdgeColor = 'k';
        h2(2).Color = point_color; h2(2).LineWidth = 1.5;
        h2(3).Color = point_color; h2(3).LineStyle = '--';
        h2(4).Color = point_color; h2(4).LineStyle = '--';
        [rho2, p2] = corr_spearman_local(x2, y2);
        xlabel('');
        if ex == 1
            ylabel(row_ylabels{2});
        else
            ylabel('');
        end
        if ex == 3
            add_row_xlabel(gca, row_xlabels{2});
        end
        title(format_corr_title_local(rho2, p2), 'FontWeight', 'normal', 'FontSize', TITLE_FONT);
        pbaspect([1 1 1]);
        legend('off');
    end

    % Row 3: Baseline LC vs baseline pupil (both residuals)
    nexttile((2)*(n_examples+1) + ex); hold off;
    point_color = row_colors{3};
    xb = pupil_drift.Residuals.Raw;
    yb = spike_drift.Residuals.Raw;
    plot(xb, yb, 'ok','MarkerFaceColor',point_color); hold on;
    lm3 = fitlm(xb, yb); h3 = plot(lm3);
    h3(1).Marker = 'o'; h3(1).MarkerFaceColor = point_color; h3(1).MarkerEdgeColor = 'k';
    h3(2).Color = 'k'; h3(2).LineWidth = 1.5;
    h3(3).Color = 'k'; h3(3).LineStyle = '--';
    h3(4).Color = 'k'; h3(4).LineStyle = '--';
    [rho3, p3] = corr_partial_spearman_local(all_baseline_FR, all_baseline_pd, all_trial_times);
    xlabel('');
    if ex == 1
        ylabel(row_ylabels{3});
    else
        ylabel('');
    end
    if ex == 3
        add_row_xlabel(gca, row_xlabels{3});
    end
    title(format_corr_title_local(rho3, p3), 'FontWeight', 'normal', 'FontSize', TITLE_FONT);
    pbaspect([1 1 1]);
    legend('off');

    % Row 4: Evoked LC vs evoked pupil
    nexttile((3)*(n_examples+1) + ex); hold off;
    if ~isempty(sub_p_evoked) && ~isempty(sub_FR_evoked)
        point_color = row_colors{4};
        plot(sub_p_evoked, sub_FR_evoked, 'ok','MarkerFaceColor',point_color); hold on;
        lm4 = fitlm(sub_p_evoked, sub_FR_evoked); h4 = plot(lm4);
        h4(1).Marker = 'o'; h4(1).MarkerFaceColor = point_color; h4(1).MarkerEdgeColor = 'k';
        h4(2).Color = 'k'; h4(2).LineWidth = 1.5;
        h4(3).Color = 'k'; h4(3).LineStyle = '--';
        h4(4).Color = 'k'; h4(4).LineStyle = '--';
        [rho4, p4] = corr_spearman_local(sub_p_evoked, sub_FR_evoked);
        xlabel('');
        if ex == 1
            ylabel(row_ylabels{4});
        else
            ylabel('');
        end
        if ex == 3
            add_row_xlabel(gca, row_xlabels{4});
        end
        title(format_corr_title_local(rho4, p4), 'FontWeight', 'normal', 'FontSize', TITLE_FONT);
        pbaspect([1 1 1]);
        legend('off');
    end

    % Row 5: Evoked LC (y) vs baseline pupil (x)
    nexttile((4)*(n_examples+1) + ex); hold off;
    if ~isempty(sub_FR_evoked) && ~isempty(sub_p_evoked)
        x5 = pupil_drift.Residuals.Raw(1:height(beep_rows));
        y5 = sub_FR_evoked;
        point_color = row_colors{5};
        plot(x5, y5, 'ok','MarkerFaceColor',point_color); hold on;
        lm5 = fitlm(x5, y5); h5 = plot(lm5);
        h5(1).Marker = 'o'; h5(1).MarkerFaceColor = point_color; h5(1).MarkerEdgeColor = 'k';
        h5(2).Color = 'k'; h5(2).LineWidth = 1.5;
        h5(3).Color = 'k'; h5(3).LineStyle = '--';
        h5(4).Color = 'k'; h5(4).LineStyle = '--';
        [rho5, p5] = corr_spearman_local(x5, y5);
        xlabel('');
        if ex == 1
            ylabel(row_ylabels{5});
        else
            ylabel('');
        end
        if ex == 3
            add_row_xlabel(gca, row_xlabels{5});
        end
        title(format_corr_title_local(rho5, p5), 'FontWeight', 'normal', 'FontSize', TITLE_FONT);
        pbaspect([1 1 1]);
        legend('off');
    end

    % Row 6: Baseline FR (y) vs evoked pupil (x)
    nexttile((5)*(n_examples+1) + ex); hold off;
    if ~isempty(sub_p_evoked) && ~isempty(spike_drift)
        x6 = sub_p_evoked;
        y6 = spike_drift.Residuals.Raw(1:height(beep_rows));
        point_color = row_colors{6};
        plot(x6, y6, 'ok','MarkerFaceColor',point_color); hold on;
        lm6 = fitlm(x6, y6); h6 = plot(lm6);
        h6(1).Marker = 'o'; h6(1).MarkerFaceColor = point_color; h6(1).MarkerEdgeColor = 'k';
        h6(2).Color = 'k'; h6(2).LineWidth = 1.5;
        h6(3).Color = 'k'; h6(3).LineStyle = '--';
        h6(4).Color = 'k'; h6(4).LineStyle = '--';
        [rho6, p6] = corr_spearman_local(x6, y6);
        xlabel('');
        if ex == 1
            ylabel(row_ylabels{6});
        else
            ylabel('');
        end
        if ex == 3
            add_row_xlabel(gca, row_xlabels{6});
        end
        title(format_corr_title_local(rho6, p6), 'FontWeight', 'normal', 'FontSize', TITLE_FONT);
        pbaspect([1 1 1]);
        legend('off');
    end
end

% Summary column: row-specific population summaries
row_summaries = cell(6,1);
row_summaries{1} = build_session_summary(LC_Beep_table, 'pupil_drift_residuals', 'pupil_bs_evoked');
row_summaries{2} = build_unit_summary(LC_Beep_table, LC_Fix_table, 2);
row_summaries{3} = build_unit_summary(LC_Beep_table, LC_Fix_table, 3);
row_summaries{4} = build_unit_summary(LC_Beep_table, LC_Fix_table, 4);
row_summaries{5} = build_unit_summary(LC_Beep_table, LC_Fix_table, 5);
row_summaries{6} = build_unit_summary(LC_Beep_table, LC_Fix_table, 6);

for row = 1:6
    tile_idx = (row-1)*(n_examples+1) + (n_examples+1);
    nexttile(tile_idx); hold off;
    plot_population_summary(row_summaries{row}, row_colors{row}, row);
end

fig = gcf;
end

function summary_tbl = build_session_summary(LC_Beep_table, x_var, y_var)
session_ids = unique(LC_Beep_table.session_id);
summary_tbl = table('Size',[0 4], ...
    'VariableTypes', {'double','double','double','double'}, ...
    'VariableNames', {'session_id','monkey_id','r','p'});
for si = 1:numel(session_ids)
    sid = session_ids(si);
    session_rows = LC_Beep_table(LC_Beep_table.session_id == sid, :);
    if isempty(session_rows)
        continue;
    end
    [~, first_idx] = unique(session_rows.fix_global_start_time, 'stable');
    session_rows = session_rows(first_idx, :);
    try
        [r,p] = corr(session_rows.(x_var), session_rows.(y_var), 'type', 'Spearman', 'rows', 'complete');
    catch
        r = NaN;
        p = NaN;
    end
    summary_tbl = [summary_tbl; {sid, session_rows.monkey_id(1), r, p}]; %#ok<AGROW>
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
            case 2
                [r,p] = corr(beep.spike_drift_residuals, beep.spike_bs_evoked, 'type', 'Spearman', 'rows', 'complete');
            case 3
                all_trial_times = [beep.fix_global_start_time; fixx.fix_global_start_time];
                all_baseline_pd = [beep.pupil_baseline; fixx.pupil_fix_baseline];
                all_baseline_FR = [beep.spike_baseline; fixx.spike_fix_baseline];
                [r,p] = partialcorr(all_baseline_FR, all_baseline_pd, all_trial_times, 'Type', 'Spearman', 'Rows', 'complete');
            case 4
                [r,p] = corr(beep.pupil_bs_evoked, beep.spike_bs_evoked, 'type', 'Spearman', 'rows', 'complete');
            case 5
                [r,p] = corr(beep.pupil_drift_residuals, beep.spike_bs_evoked, 'type', 'Spearman', 'rows', 'complete');
            case 6
                [r,p] = corr(beep.pupil_bs_evoked, beep.spike_drift_residuals, 'type', 'Spearman', 'rows', 'complete');
        end
    catch
        r = NaN;
        p = NaN;
    end
    summary_tbl = [summary_tbl; {uid, beep.monkey_id(1), r, p}]; %#ok<AGROW>
end
end

function plot_population_summary(summary_tbl, point_color, row_num)
scatter_m_sz = 50;
plot_options.monkey_symbols = {'o','d'};
x_start = [1,5];
light_alpha = 0.3;
if row_num == 1 || row_num == 2
    light_alpha = 0.2;
end
for mm = 1:2
    m_rows = summary_tbl.monkey_id == mm;
    sig_idx = summary_tbl.p < 0.05 & m_rows;
    nonsig_idx = ~(summary_tbl.p < 0.05) & m_rows;
    hold on;
    scatter(x_start(mm) + (3-1).*rand(sum(sig_idx),1), summary_tbl.r(sig_idx), scatter_m_sz, plot_options.monkey_symbols{mm}, ...
        'MarkerFaceColor', point_color, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 1);
    scatter(x_start(mm) + (3-1).*rand(sum(nonsig_idx),1), summary_tbl.r(nonsig_idx), scatter_m_sz, plot_options.monkey_symbols{mm}, ...
        'MarkerFaceColor', point_color, 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', light_alpha);
    vals = summary_tbl.r(m_rows);
    if isempty(vals)
        continue;
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
    if row_num <= 2
        med_line_color = point_color;
    end
    plot(x_start(mm) + [-0.5, 2.5], [median(vals,'omitnan'), median(vals,'omitnan')], '-', 'Color', med_line_color, 'LineWidth', line_width);
end
plot([0,8], [0 0], ':k', 'LineWidth', 1.5);
xlim([0,8]);
ylim([-1,1]);
xticks([]);
    xlabel('');
switch row_num
    case 3
        ylabel({'Spearman Partial','Correlation'});
    otherwise
        ylabel({'Spearman','Correlation'});
end
title('');
end

function add_row_xlabel(ax, label_text)
% Add a compact per-row x label without expanding tiledlayout spacing.
text(ax, 0.5, -0.26, label_text, ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', ...
    'Clipping', 'off');
end

function [rho, p] = corr_spearman_local(x, y)
rho = NaN;
p = NaN;
try
    [rho, p] = corr(x, y, 'type', 'Spearman', 'rows', 'complete');
catch
end
end

function [rho, p] = corr_partial_spearman_local(x, y, z)
rho = NaN;
p = NaN;
try
    [rho, p] = partialcorr(x, y, z, 'Type', 'Spearman', 'Rows', 'complete');
catch
end
end

function txt = format_corr_title_local(rho, p)
if ~isfinite(rho)
    rtxt = 'rho=n/a';
else
    rtxt = sprintf('rho=%.2f', rho);
end

if ~isfinite(p)
    ptxt = 'p=n/a';
elseif p < 0.001
    ptxt = 'p<0.001';
else
    ptxt = sprintf('p=%.3f', p);
end

txt = sprintf('%s, %s', rtxt, ptxt);
end
