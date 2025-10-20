%% Get all the possible partial correlations

for ith_unit = 1:max(LC_Beep_table.unit_id)
    % Select beep and fix trials for this unit
    unit_trials_beep = LC_Beep_table.unit_id == ith_unit;
    unit_trials_fix = LC_Fix_table.unit_id == ith_unit;
    
    % Concatenate these to compare all baselines
    all_baseline_FR = [LC_Beep_table.spike_baseline(unit_trials_beep); LC_Fix_table.spike_baseline(unit_trials_fix)];
    all_baseline_pd = [LC_Beep_table.pupil_baseline(unit_trials_beep); LC_Fix_table.pupil_baseline(unit_trials_fix)];
    % [stats.base_p_base_FR(ith_unit), stats.p(ith_unit)] = partialcorr(all_baseline_FR',all_baseline_pd', all_trial_times','Type','Spearman');

    %% LC Firing Rates
    % Raw baseline vs. raw evoked
    [stats.rawbase_s_rawevoked_s_R(ith_unit), stats.rawbase_s_rawevoked_s_p(ith_unit)] = corr(LC_Beep_table.spike_baseline(unit_trials_beep), ...
        LC_Beep_table.raw_spike_evoked(unit_trials_beep), 'type','Spearman');

    % Raw baseline vs. baseline subtracted evoked
    [stats.rawbase_s_bsevoked_s_R(ith_unit), stats.rawbase_s_bsevoked_s_p(ith_unit)] = corr(LC_Beep_table.spike_baseline(unit_trials_beep), ...
        LC_Beep_table.spike_bs_evoked(unit_trials_beep), 'type','Spearman');

    % Residual baseline vs. raw evoked
    [stats.base_s_rawevoked_p_R(ith_unit), stats.base_s_rawevoked_s_p(ith_unit)] = corr(LC_Beep_table.spike_drift_residuals(unit_trials_beep), ...
        LC_Beep_table.raw_spike_evoked(unit_trials_beep), 'type','Spearman');

    % Residual baseline vs. baseline subtracted evoked
    [stats.base_s_subevoked_s_R(ith_unit), stats.base_s_subevoked_s_p(ith_unit)] = corr(LC_Beep_table.spike_drift_residuals(unit_trials_beep), ...
        LC_Beep_table.spike_bs_evoked(unit_trials_beep), 'type','Spearman');

    %% Pupil Responses
    % Raw baseline vs. raw evoked
    [stats.rawbase_p_rawevoked_p_R(ith_unit), stats.rawbase_p_rawevoked_p(ith_unit)] = corr(LC_Beep_table.pupil_baseline(unit_trials_beep), ...
        LC_Beep_table.raw_pupil_evoked(unit_trials_beep), 'type','Spearman');

    % Raw baseline vs. baseline subtracted evoked
    [stats.rawbase_p_subevoked_p_R(ith_unit), stats.rawbase_p_subevoked_p(ith_unit)] = corr(LC_Beep_table.pupil_baseline(unit_trials_beep), ...
        LC_Beep_table.pupil_bs_evoked(unit_trials_beep), 'type','Spearman');

    % Residual baseline vs. raw evoked
    [stats.base_p_rawevoked_p_R(ith_unit), stats.base_p_rawevoked_p(ith_unit)] = corr(LC_Beep_table.pupil_drift_residuals(unit_trials_beep), ...
        LC_Beep_table.raw_pupil_evoked(unit_trials_beep), 'type','Spearman');

    % Residual baseline vs. baseline subtracted evoked
    [stats.base_p_subevoked_p_R(ith_unit), stats.base_p_subevoked_p(ith_unit)] = corr(LC_Beep_table.pupil_drift_residuals(unit_trials_beep), ...
        LC_Beep_table.pupil_bs_evoked(unit_trials_beep), 'type','Spearman');
end