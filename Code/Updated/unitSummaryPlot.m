function stats = unitSummaryPlot(LC_Beep_table, LC_Fix_table)
%% Generates a unit summary plot for Joshi 2016 data and gets relevant statistics
% Created by LWT 9/24/2024

% Input:
% UPDATED TO USE TABLES WITH THE SAME DATA/LABELS MENTIONED BELOW.
% The two matrices LC_Beep_data and LC_Fix_data for a SINGLE UNIT (getData.m)
% Iterative process copied below (concatenating matrices for each unit - hence the repmat for labels):
% For trials with beeps (and therefore evoked data):
% LC_Beep_data = cat(1, LC_PD_data, ...
%     [repmat([mm ff ith_unit],sum(Lg),1), ...
%     pupil_data(Lg,:) squeeze(spike_rate_data(Lg,1,uu)) sub_FR_evoked fix_start_times(Lg)]);
% LC_Beep_labels = {'monkey_id','session_id', 'unit_id', 'pupil_baseline', 'pupil_bs_evoked',...
%     'spike_baseline', 'spike_bs_evoked', 'fix_global_start_time'};
% 
% Fix trials only (no beep)
% LC_Fix_data = cat(1, LC_Fix_data, ...
%     [repmat([mm ff ith_unit],sum(Lg_fix),1), ...
%     pupil_fix_data(Lg_fix,:) squeeze(spike_rate_fix_data(Lg_fix,uu)) trial_fix_times(Lg_fix)]);
% LC_Fix_labels = {'monkey_id','session_id', 'unit_id', 'pupil_baseline',...
%     'spike_baseline', 'fix_global_start_time'};

% Output:
% 'stats' struct with results from correlations, linear models included in
% the plots, plus others

% Note that with the check below you could input the entire LC_Beep_data
% mat or data for a single unit. You'd need to add these inds to the
% indexing below.
% unit_beep_inds = LC_Beep_data(:,3) == unit_num;
% unit_fix_inds = LC_Fix_data(:,3) == unit_num;

% For each session evoked vs baseline
% Fit a line vs a quadratic to see if there is a relationship

stats.monkey_id = LC_Beep_table.monkey_id(1);

all_trial_times = [LC_Beep_table.fix_global_start_time', LC_Fix_table.fix_global_start_time'];
all_baseline_pd = [LC_Beep_table.pupil_baseline', LC_Fix_table.pupil_baseline'];
all_baseline_FR = [LC_Beep_table.spike_baseline', LC_Fix_table.spike_baseline'];
spike_drift = fitlm(all_trial_times,all_baseline_FR); % already in table but no stats
pupil_drift = fitlm(all_trial_times,all_baseline_pd); % already in table but no stats

% Get drift coefficients
stats.spike_drift_slope = spike_drift.Coefficients.Estimate(2);
stats.pupil_drift_slope = pupil_drift.Coefficients.Estimate(2);
% Correlate the residuals (similar to the baseline_p that uses a partial
% correlation.
stats.baseline_P_alt = corr(spike_drift.Residuals.Raw, pupil_drift.Residuals.Raw, 'type', 'Spearman');

% Check for evoked activity
stats.evoked_spikes = signtest(LC_Beep_table.spike_baseline, LC_Beep_table.spike_baseline+LC_Beep_table.spike_bs_evoked);

%% 1) Is baseline pupil related to baseline FR?
% rho = partialcorr(x,y,z) returns the sample linear partial correlation coefficients between pairs of variables in x and y, controlling for the variables in z.
% [stats.base_p_base_FR, stats.p] = partialcorr(LC_Fix_table.spike_baseline,LC_Fix_table.pupil_baseline,LC_Fix_table.fix_global_start_time,'Type','Spearman');
[stats.base_p_base_FR, stats.p] = partialcorr(all_baseline_FR',all_baseline_pd', all_trial_times','Type','Spearman');

% Plot baseline firing rate over time with drift estimate
subplot(3,4,[1,2]); hold off;
plot(all_trial_times./1000,all_baseline_FR,'ok','MarkerFaceColor','r');  hold on;
j = lsline;
j.Color = 'r';
xlabel('Time (sec)')
ylabel('Baseline Firing Rate (spikes/sec)')
title('Baseline FR Drift')
box off;
% axis square;

% Plot baseline pupil over time with drift estimate
subplot(3,4,[3,4]); hold off;
plot(all_trial_times./1000,all_baseline_pd,'ok','MarkerFaceColor','b'); hold on;
j = lsline;
j.Color = 'b';
if LC_Beep_table.unit_id==25
    sample_time = LC_Beep_table.fix_global_start_time(13)/1000;
    sample_baseline_pd = LC_Beep_table.pupil_baseline(13);
    plot(sample_time,sample_baseline_pd,'og','MarkerFaceColor','b')
end
xlabel('Time (sec)')
ylabel('Baseline Pupil Diameter (Z-Score)')
title('Baseline Pupil Drift')
box off;
% axis square;

% Plot the relationship between the residuals
subplot(3,4,5); hold off;
plot(pupil_drift.Residuals.Raw,spike_drift.Residuals.Raw,'ok','MarkerFaceColor',[0.5 0.5 0.5])
j = lsline;
j.Color = 'k';
if stats.p <0.05
    title('**All Trials Baseline Drift**')
else
    title('All Trials Baseline Drift')
end
xlabel({'Baseline Pupil', '(residuals)'})
ylabel({'Baseline FR', '(residuals)'})
axis square;


%% 2) Is baseline pupil related to evoked pupil?

% Correlate pupil baseline residuals and baseline subtracted evoked
[stats.base_p_subevoked_p_R, stats.base_p_subevoked_p] = corr(LC_Beep_table.pupil_drift_residuals,LC_Beep_table.pupil_bs_evoked,'type','Spearman');

% Compare linear and quadratic models
% For plotting purposes we use fitlm. For stats we use fitlme
lm = fitlm(LC_Beep_table,'pupil_bs_evoked ~ pupil_drift_residuals');
lm2 = fitlm(LC_Beep_table,'pupil_bs_evoked ~ pupil_drift_residuals*pupil_drift_residuals');
lme = fitlme(LC_Beep_table,'pupil_bs_evoked ~ pupil_drift_residuals');
lme2 = fitlme(LC_Beep_table,'pupil_bs_evoked ~ pupil_drift_residuals*pupil_drift_residuals');
results = compare(lme,lme2);
stats.pEvoked_v_pBase = results.pValue(2);
stats.pEvoked_v_pBase_LLR = 2*(results.LogLik(2) - results.LogLik(1));
% Plot the linear models
subplot(3,4,9); hold off;
h=plot(lm); hold on;
h(1).Marker = 'none';
h(2).Color = 'b';
h(3).Color = 'b';
h(4).Color = 'b';
h=plot(lm2);
h(1).Marker = 'o'; h(1).MarkerFaceColor = 'b'; h(1).MarkerEdgeColor = 'k';
h(2).Color = 'g';
h(3).Color = 'g';
h(4).Color = 'g';
xlabel('Baseline Pupil (residuals)')
ylabel('Evoked Pupil: baselne subtracted')
axis square;
legend off;

%% 3) Is baseline FR related to evoked FR?

% Correlate spike baseline residuals and baseline subtracted evoked
[stats.base_FR_subevoked_FR_R, stats.base_FR_subevoked_FR] = corr(LC_Beep_table.spike_drift_residuals, LC_Beep_table.spike_bs_evoked,'type','Spearman');

% Use fitlm for plotting
lm = fitlm(LC_Beep_table, 'spike_bs_evoked ~ spike_drift_residuals');
lm2 = fitlm(LC_Beep_table, 'spike_bs_evoked ~ spike_drift_residuals*spike_drift_residuals');
% To actually do this we need sufficient data
if numel(unique(LC_Beep_table.spike_drift_residuals))>1
    % Use lme for model comparison
    lme = fitlme(LC_Beep_table, 'spike_bs_evoked ~ spike_drift_residuals');
    lme2 = fitlme(LC_Beep_table, 'spike_bs_evoked ~ spike_drift_residuals*spike_drift_residuals');
    results = compare(lme,lme2);
    stats.sEvoked_v_sBase = results.pValue(2);
    stats.sEvoked_v_sBase_LLR = 2*(results.LogLik(2) - results.LogLik(1)); %results.LogLik(1)./results.LogLik(2);
else
    stats.sEvoked_v_sBase = NaN;
    stats.sEvoked_v_sBase_LLR = NaN;
end

% Plot
subplot(3,4,10); hold off;
h=plot(lm); hold on;
h(1).Marker = 'none';
h(2).Color = 'r';
h(3).Color = 'r';
h(4).Color = 'r';
h=plot(lm2);
h(1).Marker = 'o'; h(1).MarkerFaceColor = 'r'; h(1).MarkerEdgeColor = 'k';
h(2).Color = 'g';
h(3).Color = 'g';
h(4).Color = 'g';
xlabel('Baseline FR (residuals)')
ylabel('Evoked FR: baselne subtracted')
axis square;
legend off;

%% 4) Is baseline pupil related to evoked FR?

[stats.base_p_subevoked_FR_R, stats.base_p_subevoked_FR] = corr(LC_Beep_table.pupil_drift_residuals, LC_Beep_table.spike_bs_evoked,'type','Spearman');

% Spearman%s partial correlation, r, 
% between spiking (spike rate, 0–200 ms following beep onset 
% minus baseline spike rate measured during fixation prior to beep onset) 
% and pupil (maximum change in pupil diameter 0–800 ms following beep 
% onset) responses, accounting for the effects of baseline pupil diameter 
% on both variables.
[stats.partial_base_p_evoked_FR_r, stats.partial_base_p_evoked_FR_p] = partialcorr(LC_Beep_table.pupil_drift_residuals,... % baseline pupil
    LC_Beep_table.spike_bs_evoked+LC_Beep_table.spike_baseline,... % raw evoked FR
    LC_Beep_table.spike_baseline,'Type','Spearman'); % spike baseline  

lm = fitlm(LC_Beep_table, 'spike_bs_evoked ~ pupil_drift_residuals');
lm2 = fitlm(LC_Beep_table, 'spike_bs_evoked ~ pupil_drift_residuals*pupil_drift_residuals');

if numel(unique(LC_Beep_table.spike_drift_residuals))>1
    lme = fitlme(LC_Beep_table, 'spike_bs_evoked ~ pupil_drift_residuals');
    lme2 = fitlme(LC_Beep_table, 'spike_bs_evoked ~ pupil_drift_residuals*pupil_drift_residuals');
    results = compare(lme,lme2);
    stats.sEvoked_v_pBase = results.pValue(2);
    stats.sEvoked_v_pBase_LLR = 2*(results.LogLik(2) - results.LogLik(1)); %results.LogLik(1)./results.LogLik(2);
else
    stats.sEvoked_v_pBase = NaN;
    stats.sEvoked_v_pBase_LLR = NaN;
end
subplot(3,4,11); hold off;
h=plot(lm); hold on;
h(1).Marker = 'none';
h(2).Color = 'k';
h(3).Color = 'k';
h(4).Color = 'k';
h=plot(lm2);
h(1).Marker = 'o'; h(1).MarkerFaceColor = [0.5 0.5 0.5]; h(1).MarkerEdgeColor = 'k';
h(2).Color = 'g';
h(3).Color = 'g';
h(4).Color = 'g';
xlabel('Baseline Pupil (residuals)')
ylabel('Evoked FR: baselne subtracted')
axis square;
legend off;

%% 5) Is evoked pupil related to baseline FR?

[stats.subevoked_p_base_FR_R, stats.subevoked_p_base_FR] = corr(LC_Beep_table.pupil_bs_evoked, LC_Beep_table.spike_drift_residuals,'type','Spearman');
[stats.partial_base_FR_evoked_p_r, stats.partial_base_FR_evoked_p_p] = partialcorr(LC_Beep_table.spike_drift_residuals,...
    LC_Beep_table.pupil_bs_evoked+LC_Beep_table.pupil_baseline,...
    LC_Beep_table.pupil_baseline,'Type','Spearman');

lm = fitlm(LC_Beep_table,'pupil_bs_evoked ~ spike_drift_residuals');
lm2 = fitlm(LC_Beep_table,'pupil_bs_evoked ~ spike_drift_residuals*spike_drift_residuals');

if numel(unique(LC_Beep_table.spike_drift_residuals))>1
    lme = fitlme(LC_Beep_table,'pupil_bs_evoked ~ spike_drift_residuals');
    lme2 = fitlme(LC_Beep_table,'pupil_bs_evoked ~ spike_drift_residuals*spike_drift_residuals');
    results = compare(lme,lme2);
    stats.pEvoked_v_sBase = results.pValue(2);
    stats.pEvoked_v_sBase_LLR = 2*(results.LogLik(2) - results.LogLik(1)); %results.LogLik(1)./results.LogLik(2);
else
    stats.pEvoked_v_sBase = NaN;
    stats.pEvoked_v_sBase_LLR = NaN;
end
av = anova(lm2);
stats.subevoked_p_base_FR_lm2 = av.pValue(:,1);
subplot(3,4,12); hold off;
h=plot(lm); hold on;
h(1).Marker = 'none';
h(2).Color = 'k';
h(3).Color = 'k';
h(4).Color = 'k';
h=plot(lm2);
h(1).Marker = 'o'; h(1).MarkerFaceColor = [0.5 0.5 0.5]; h(1).MarkerEdgeColor = 'k';
h(2).Color = 'g';
h(3).Color = 'g';
h(4).Color = 'g';
xlabel('Evoked Pupil: baselne subtracted')
ylabel('Baseline FR (residuals)')
axis square;
legend off;

%% 6) Is evoked pupil related to evoked FR?
subplot(3,4,6); hold off;
plot(LC_Beep_table.pupil_bs_evoked, LC_Beep_table.spike_bs_evoked,'ok','MarkerFaceColor',[0.5 0.5 0.5])
j = lsline;
j.Color = 'k';
title('Evoked Responses')
xlabel({'Evoked Pupil', '(baseline subtracted)'})
ylabel({'Evoked FR', '(baseline subtracted)'})
axis square;

% Joshi:
% Spearman%s partial correlation, r, 
% between spiking (spike rate, 0–200 ms following beep onset 
% minus baseline spike rate measured during fixation prior to beep onset) 
% and pupil (maximum change in pupil diameter 0–800 ms following beep 
% onset) responses, accounting for the effects of baseline pupil diameter 
% on both variables.
[stats.partial_evoked_r, stats.partial_evoked_p] = partialcorr(LC_Beep_table.pupil_bs_evoked+LC_Beep_table.pupil_baseline,...
    LC_Beep_table.spike_bs_evoked, LC_Beep_table.pupil_baseline,'Type','Spearman');
% Alternatively, why not just compare the baseline subtracted responses
% directly?
[stats.bs_evoked_r, stats.bs_evoked_p] = corr(LC_Beep_table.pupil_bs_evoked, LC_Beep_table.spike_bs_evoked,'Type','Spearman');

%% Get some other measures
% mean evoked responses
stats.mean_spike_evoked_mag = mean(LC_Beep_table.spike_bs_evoked,'omitnan');
stats.mean_pupil_evoked_mag = mean(LC_Beep_table.pupil_bs_evoked,'omitnan');

% range of evoked responses
stats.range_spike_evoked_mag = max(LC_Beep_table.spike_bs_evoked) - min(LC_Beep_table.spike_bs_evoked);
stats.range_pupil_evoked_mag = max(LC_Beep_table.pupil_bs_evoked) - min(LC_Beep_table.pupil_bs_evoked);

stats.range_spike_baseline = max(LC_Beep_table.spike_baseline) - min(LC_Beep_table.spike_baseline);
stats.range_pupil_baseline = max(LC_Beep_table.pupil_baseline) - min(LC_Beep_table.pupil_baseline);
end