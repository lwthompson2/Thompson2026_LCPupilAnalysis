function fig = plot_S3_sig_baseline_subset(LC_Beep_table, LC_Fix_table)
% PLOT_S3_SIG_BASELINE_SUBSET  Figure 2-style summary plots for subset units.
% Panel 1: baseline pupil vs baseline-subtracted evoked LC.
% Panel 2: baseline LC vs baseline-subtracted evoked pupil.

if nargin < 2
    error('Provide LC_Beep_table and LC_Fix_table');
end

tbl_row3 = build_unit_summary(LC_Beep_table, LC_Fix_table, 3);
sig_units = tbl_row3.unit_id(tbl_row3.p < 0.05 & isfinite(tbl_row3.p));

tbl_row5 = build_unit_summary(LC_Beep_table, LC_Fix_table, 5);
tbl_row6 = build_unit_summary(LC_Beep_table, LC_Fix_table, 6);

tbl_row5 = tbl_row5(ismember(tbl_row5.unit_id, sig_units), :);
tbl_row6 = tbl_row6(ismember(tbl_row6.unit_id, sig_units), :);

fig = figure('Name', 'Figure_S3_sig_baseline_subset');
t = tiledlayout(1,2, 'TileSpacing', 'compact', 'Padding', 'compact');
t.Title.String = 'Subset: Significant Baseline LC-Pupil Units';
t.Title.FontWeight = 'bold';

nexttile;
plot_population_summary(tbl_row5, [0.10 0.35 0.85]);
title({'Baseline pupil vs', 'baseline-subtracted evoked LC'});
ylabel({'Spearman','Correlation'});

nexttile;
plot_population_summary(tbl_row6, [0.85 0.10 0.20]);
title({'Baseline LC vs', 'baseline-subtracted evoked pupil'});
ylabel({'Spearman','Correlation'});

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
            case 3
                all_trial_times = [beep.fix_global_start_time; fixx.fix_global_start_time];
                all_baseline_pd = [beep.pupil_baseline; fixx.pupil_fix_baseline];
                all_baseline_FR = [beep.spike_baseline; fixx.spike_fix_baseline];
                [r,p] = partialcorr(all_baseline_FR, all_baseline_pd, all_trial_times, 'Type', 'Spearman', 'Rows', 'complete');
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

function plot_population_summary(summary_tbl, point_color)
scatter_m_sz = 55;
plot_options.monkey_symbols = {'o','d'};
x_start = [1,5];

for mm = 1:2
    m_rows = summary_tbl.monkey_id == mm;
    sig_idx = summary_tbl.p < 0.05 & m_rows;
    nonsig_idx = ~(summary_tbl.p < 0.05) & m_rows;

    hold on;
    scatter(x_start(mm) + (3-1).*rand(sum(sig_idx),1), summary_tbl.r(sig_idx), scatter_m_sz, ...
        plot_options.monkey_symbols{mm}, 'MarkerFaceColor', point_color, ...
        'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 1);
    scatter(x_start(mm) + (3-1).*rand(sum(nonsig_idx),1), summary_tbl.r(nonsig_idx), scatter_m_sz, ...
        plot_options.monkey_symbols{mm}, 'MarkerFaceColor', point_color, ...
        'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.30);

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
    med_val = median(vals, 'omitnan');
    plot(x_start(mm) + [-0.5, 2.5], [med_val, med_val], '-', 'Color', 'k', 'LineWidth', line_width);
end

plot([0,8], [0 0], ':k', 'LineWidth', 1.5);
xlim([0,8]);
ylim([-1,1]);
xticks([2,6]);
xticklabels({'Oz','Ci'});
xlabel('Monkey');
box off;
end
