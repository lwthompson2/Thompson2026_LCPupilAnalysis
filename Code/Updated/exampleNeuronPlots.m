%% Generates a unit summary plot for Joshi 2016 example data
% Created by LWT 9/24/2024
% Requires getData.m to be run

% mm, ff, unit_num
example_neurons = [1, 18, 24;...
    1, 19, 25;...
    2, 5, 48;...
    2, 16, 60;...
    2, 27, 69];

    % 1, 21, 27;...
    % 2, 35, 77;...
    % 2, 39, 80
f = figure; f.Position = [828 1 685 865];
t = tiledlayout(6,size(example_neurons,1),'TileSpacing','tight','Padding','compact');
n_rows = 6;
n_cols = size(example_neurons,1);
tile_index = @(r,c) (r - 1) * n_cols + c;

for ex = 1:size(example_neurons,1)
    temp_stats = [];
    temp_beep_data = LC_Beep_data(LC_Beep_data(:,3)==example_neurons(ex,3),:);
    temp_fix_data = LC_Fix_data(LC_Fix_data(:,3)==example_neurons(ex,3),:);

    all_trial_times = [temp_beep_data(:,8)', temp_fix_data(:,6)'];
    all_baseline_pd = [temp_beep_data(:,4)', temp_fix_data(:,4)'];
    all_baseline_FR = [temp_beep_data(:,6)', temp_fix_data(:,5)'];
    spike_drift = fitlm(all_trial_times,all_baseline_FR);
    pupil_drift = fitlm(all_trial_times,all_baseline_pd);
    temp_stats.spike_drift_slope = spike_drift.Coefficients.Estimate(2);
    temp_stats.pupil_drift_slope = pupil_drift.Coefficients.Estimate(2);
    temp_stats.baseline_P_alt = corr(spike_drift.Residuals.Raw, pupil_drift.Residuals.Raw, 'type', 'Spearman');

    raw_p_evoked = temp_beep_data(:,4)+temp_beep_data(:,5); % Add back baseline to evoked
    corrected_p_evoked = raw_p_evoked - pupil_drift.Fitted(1:size(temp_beep_data,1)); % Residual %raw_p_evoked + (trial_times(Lg)'.*pupil_drift.Coefficients.Estimate(2)); % Consider the slope associated with time drift
    sub_p_evoked = temp_beep_data(:,5);

    raw_FR_evoked = temp_beep_data(:,6)+temp_beep_data(:,7); % Already subtracted, add back baseline
    corrected_FR_evoked = raw_FR_evoked - spike_drift.Fitted(1:size(temp_beep_data,1)); % Residual raw_FR_evoked + (trial_times(Lg)'.*spike_drift.Coefficients.Estimate(2)); % Consider the slope associated with time drift
    sub_FR_evoked = temp_beep_data(:,7); % Baseline subtraction

    % Create a table for using linear models
    lm_table = table(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)), spike_drift.Residuals.Raw(1:size(temp_beep_data,1)), sub_p_evoked, sub_FR_evoked, raw_p_evoked, raw_FR_evoked,...
        'VariableNames',{'pupil_base', 'spike_base', 'pupil_evoked', 'spike_evoked', 'pupil_evoked_raw', 'spike_evoked_raw'});

    %% 1) Is baseline pupil related to baseline FR?
    % rho = partialcorr(x,y,z) returns the sample linear partial correlation coefficients between pairs of variables in x and y, controlling for the variables in z.
    % [base_p_base_FR(ith_unit), p(ith_unit)] = partialcorr(spike_rate_data(Lg,1,uu),pupil_data(Lg,1),[trial_times(Lg)]','Type','Spearman');
    [temp_stats.base_p_base_FR, temp_stats.p] = partialcorr(all_baseline_FR',all_baseline_pd', all_trial_times','Type','Spearman');
    
    nexttile(ex); hold off;
    % subplot(6,size(example_neurons,1),ex); hold off;
    plot(pupil_drift.Residuals.Raw,spike_drift.Residuals.Raw,'ok','MarkerFaceColor',[0.5 0.5 0.5])
    lm = fitlm(pupil_drift.Residuals.Raw, spike_drift.Residuals.Raw);
    h=plot(lm); hold on;
    h(1).Marker = 'o'; h(1).MarkerFaceColor = [0.5 0.5 0.5]; h(1).MarkerEdgeColor = 'k';
    h(2).Color = 'k';
    h(3).Color = 'k';
    h(4).Color = 'k';
    if ex == 3
        xlabel({'Baseline Pupil (residuals)'})
    else
        xlabel('');
    end
    if ex == 1
        ylabel({'Baseline FR', '(residuals)'})
    else
        ylabel('');
    end
    pbaspect([1 1 1]);
    legend off;


    %% 2) Is baseline pupil related to evoked pupil?

    [temp_stats.base_p_subevoked_p_R, temp_stats.base_p_subevoked_p] = corr(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_p_evoked,'type','Spearman');

    % We don't necessarily want to subtract
    %   b) baseline subtracted evoked
    lme = fitlme(lm_table,'pupil_evoked ~ pupil_base');
    lm = fitlm(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_p_evoked, 'linear');
    lme2 = fitlme(lm_table,'pupil_evoked ~ pupil_base*pupil_base');
    results = compare(lme,lme2);
    temp_stats.pEvoked_v_pBase = results.pValue(2);
    temp_stats.pEvoked_v_pBase_LLR = results.LogLik(1)./results.LogLik(2);
    lm2 = fitlm(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_p_evoked, 'purequadratic');

    % subplot(6,size(example_neurons,1),ex + size(example_neurons,1)); hold off;
    nexttile(ex + size(example_neurons,1)); hold off;
    h=plot(lm); hold on;
    % h(1).Marker = 'none';
    h(2).Color = 'b';
    h(3).Color = 'b';
    h(4).Color = 'b';

    % h=plot(lm2);
    h(1).Marker = 'o'; h(1).MarkerFaceColor = 'b'; h(1).MarkerEdgeColor = 'k';
    % h(2).Color = 'g';
    % h(3).Color = 'g';
    % h(4).Color = 'g';
    % plot(pupil_drift.Residuals.Raw, sub_p_evoked,'o')
    if ex == 3
        xlabel('Baseline Pupil (residuals)')
    else
        xlabel('');
    end
    if ex == 1
        ylabel({'Evoked Pupil', '(baselne subtracted)'})
    else
        ylabel('');
    end
    pbaspect([1 1 1]);
    legend off;
    

    %% 3) Is baseline FR related to evoked FR?
    %   b) baseline subtracted evoked
    lm = fitlm(spike_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_FR_evoked, 'linear');
    lm2 = fitlm(spike_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_FR_evoked, 'purequadratic');
    if sum(lm_table.spike_base)>0
        lme = fitlme(lm_table,'spike_evoked ~ spike_base');
        lme2 = fitlme(lm_table,'spike_evoked ~ spike_base*spike_base');
        results = compare(lme,lme2);
        temp_stats.sEvoked_v_sBase = results.pValue(2);
        temp_stats.sEvoked_v_sBase_LLR = results.LogLik(1)./results.LogLik(2);
    else
        temp_stats.sEvoked_v_sBase = NaN;
        temp_stats.sEvoked_v_sBase_LLR = NaN;
    end
    % subplot(6,size(example_neurons,1),ex + 2*size(example_neurons,1));
    nexttile(ex + 2*size(example_neurons,1));
    hold off;
    h=plot(lm); hold on;
    % h(1).Marker = 'none';
    h(2).Color = 'r';
    h(3).Color = 'r';
    h(4).Color = 'r';

    h=plot(lm2);
    h(1).Marker = 'o'; h(1).MarkerFaceColor = 'r'; h(1).MarkerEdgeColor = 'k';
    % h(2).Color = 'g';
    % h(3).Color = 'g';
    % h(4).Color = 'g';
    [temp_stats.base_FR_subevoked_FR_R, temp_stats.base_FR_subevoked_FR] = corr(spike_drift.Residuals.Raw(1:size(temp_beep_data,1)), sub_FR_evoked,'type','Spearman');
    % subplot(2,5,8);
    % plot(spike_drift.Residuals.Raw,sub_FR_evoked,'o')
    if ex == 3
        xlabel('Baseline FR (residuals)')
    else
        xlabel('');
    end
    if ex == 1
        ylabel({'Evoked FR', '(baselne subtracted)'})
    else
        ylabel('');
    end
    pbaspect([1 1 1]);
    legend off;

    %% 4) Is evoked pupil related to evoked FR?
    % subplot(6,size(example_neurons,1),ex + 3*size(example_neurons,1)); hold off;
    nexttile(ex + 3*size(example_neurons,1)); hold off;
    plot(sub_p_evoked,sub_FR_evoked,'ok','MarkerFaceColor',[0.5 0.5 0.5])
    lm = fitlm(sub_p_evoked, sub_FR_evoked);
    h=plot(lm); hold on;
    h(1).Marker = 'o'; h(1).MarkerFaceColor = [0.5 0.5 0.5]; h(1).MarkerEdgeColor = 'k';
    h(2).Color = 'k';
    h(3).Color = 'k';
    h(4).Color = 'k';
    if ex == 3
        xlabel({'Evoked Pupil (baseline subtracted)'})
    else
        xlabel('');
    end
    if ex==1
        ylabel({'Evoked FR', '(baseline subtracted)'})
    else
        ylabel('');
    end
    pbaspect([1 1 1]);
    legend off;
    
    % Joshi:
    % Spearman%s partial correlation, r,
    % between spiking (spike rate, 0–200 ms following beep onset
    % minus baseline spike rate measured during fixation prior to beep onset)
    % and pupil (maximum change in pupil diameter 0–800 ms following beep
    % onset) responses, accounting for the effects of baseline pupil diameter
    % on both variables.
    [temp_stats.partial_evoked_r, temp_stats.partial_evoked_p] = partialcorr(raw_p_evoked, sub_FR_evoked, temp_beep_data(:,4),'Type','Spearman');
    % Alternatively, why not just compare the baseline subtracted responses
    % directly?
    [temp_stats.bs_evoked_r, temp_stats.bs_evoked_p] = corr(sub_p_evoked, sub_FR_evoked,'Type','Spearman');

    %   a) raw evoked pupil vs baseline sub evoked FR
    temp_stats.evoked_p_subevoked_FR = corr(corrected_p_evoked, sub_FR_evoked,'type','Spearman');
    %   b) raw evoked pupil vs raw evoked FR
    temp_stats.evoked_p_voked_FR = corr(corrected_p_evoked, corrected_FR_evoked,'type','Spearman');
    %   c) baseline sub pupil vs baseline sub evoked FR
    temp_stats.subevoked_p_subevoked_FR = corr(sub_p_evoked, sub_FR_evoked,'type','Spearman');
    %   d) baseline sub pupil vs raw evoked FR
    temp_stats.subevoked_p_evoked_FR = corr(sub_p_evoked, corrected_FR_evoked,'type','Spearman');

    %% 4) Is baseline pupil related to evoked FR?
    %   b) baseline subtracted evoked
    lm = fitlm(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_FR_evoked, 'linear');
    lm2 = fitlm(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_FR_evoked, 'purequadratic');
    if sum(lm_table.spike_base)>0
        lme = fitlme(lm_table,'spike_evoked ~ pupil_base');
        lme2 = fitlme(lm_table,'spike_evoked ~ pupil_base*pupil_base');
        results = compare(lme,lme2);
        temp_stats.sEvoked_v_pBase = results.pValue(2);
        temp_stats.sEvoked_v_pBase_LLR = results.LogLik(1)./results.LogLik(2);
    else
        temp_stats.sEvoked_v_pBase = NaN;
        temp_stats.sEvoked_v_pBase_LLR = NaN;
    end
    % subplot(6,size(example_neurons,1),ex + 4*size(example_neurons,1)); hold off;
    nexttile(ex + 4*size(example_neurons,1));
    hold off;
    h=plot(lm); hold on;
    % h(1).Marker = 'none';
    h(2).Color = 'k';
    h(3).Color = 'k';
    h(4).Color = 'k';

    % h=plot(lm2);
    h(1).Marker = 'o'; h(1).MarkerFaceColor = [0.5 0.5 0.5]; h(1).MarkerEdgeColor = 'k';
    % h(2).Color = 'g';
    % h(3).Color = 'g';
    % h(4).Color = 'g';
    [temp_stats.base_p_subevoked_FR_R, temp_stats.base_p_subevoked_FR] = corr(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_FR_evoked,'type','Spearman');
    % subplot(2,5,6);
    % plot(pupil_drift.Residuals.Raw,sub_FR_evoked,'o')
    if ex == 3
        xlabel('Baseline Pupil (residuals)')
    else
        xlabel('');
    end
    if ex == 1
        ylabel({'Evoked FR', '(baselne subtracted)'})
    else
        ylabel('');
    end
    pbaspect([1 1 1]);
    legend off;

    % Spearman%s partial correlation, r,
    % between spiking (spike rate, 0–200 ms following beep onset
    % minus baseline spike rate measured during fixation prior to beep onset)
    % and pupil (maximum change in pupil diameter 0–800 ms following beep
    % onset) responses, accounting for the effects of baseline pupil diameter
    % on both variables.

    % baseline pupil, raw evoked evoked FR?  baseline FR?
    [temp_stats.partial_base_p_evoked_FR_r, temp_stats.partial_base_p_evoked_FR_p] = partialcorr(temp_beep_data(:,4), raw_FR_evoked, temp_beep_data(:,6),'Type','Spearman');
    % [temp_stats.partial_base_p_evoked_FR_r, temp_stats.partial_base_p_evoked_FR_p] = partialcorr(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)), raw_FR_evoked, spike_drift.Residuals.Raw(1:size(temp_beep_data,1)),'Type','Spearman')

    %% 5) Is evoked pupil related to baseline FR?
    %   b) baseline subtracted evoked
    lm = fitlm(sub_p_evoked, spike_drift.Residuals.Raw(1:size(temp_beep_data,1)),'linear');
    lm2 = fitlm(sub_p_evoked, spike_drift.Residuals.Raw(1:size(temp_beep_data,1)), 'purequadratic');
    if sum(lm_table.spike_base)>0
        lme = fitlme(lm_table,'pupil_evoked ~ spike_base');
        lme2 = fitlme(lm_table,'pupil_evoked ~ spike_base*spike_base');
        results = compare(lme,lme2);
        temp_stats.pEvoked_v_sBase = results.pValue(2);
        temp_stats.pEvoked_v_sBase_LLR = results.LogLik(1)./results.LogLik(2);
    else
        temp_stats.pEvoked_v_sBase = NaN;
        temp_stats.pEvoked_v_sBase_LLR = NaN;
    end
    av = anova(lm2);
    temp_stats.subevoked_p_base_FR_lm2 = av.pValue(:,1);
    % subplot(6,size(example_neurons,1),ex + 5*size(example_neurons,1)); hold off;
    nexttile(ex + 5*size(example_neurons,1)); hold off;
    h=plot(lm); hold on;
    % h(1).Marker = 'none';
    h(2).Color = 'k';
    h(3).Color = 'k';
    h(4).Color = 'k';

    % h=plot(lm2);
    h(1).Marker = 'o'; h(1).MarkerFaceColor = [0.5 0.5 0.5]; h(1).MarkerEdgeColor = 'k';
    % h(2).Color = 'g';
    % h(3).Color = 'g';
    % h(4).Color = 'g';
    [temp_stats.subevoked_p_base_FR_R, temp_stats.subevoked_p_base_FR] = corr(sub_p_evoked, spike_drift.Residuals.Raw(1:size(temp_beep_data,1)),'type','Spearman');
    % subplot(2,5,10);
    % plot(sub_p_evoked,spike_drift.Residuals.Raw,'o')
    if ex == 3
        xlabel('Evoked Pupil (baselne subtracted)')
    else
        xlabel('');
    end
    if ex==1
        ylabel({'Baseline FR', '(residuals)'})
    else
        ylabel('');
    end
    pbaspect([1 1 1]);
    legend off;

    % baseline FR, raw evoked pupil, baseline pupil
    [temp_stats.partial_base_FR_evoked_p_r, temp_stats.partial_base_FR_evoked_p_p] = partialcorr(temp_beep_data(:,6), raw_p_evoked, temp_beep_data(:,4),'Type','Spearman');
end