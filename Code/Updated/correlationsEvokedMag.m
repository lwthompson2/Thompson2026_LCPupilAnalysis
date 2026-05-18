%% Are evoked magnitudes related to correlations?
% Change to mean(response) rather than abs responses.
% Try not changing the R values to R2
% change x & y saccades

% Plot the trend over time for all sessions (pupil and blah);
% Fit a line and look at a scatter plot of the linear fits (slope) over time?

for m = 1:2
    valid = stats.monkey_id == m & isfinite(stats.subevoked_p_base_FR_R) & isfinite(stats.base_FR_subevoked_FR_R);

    figure; hold on;
    subplot(2,4,1);
    plot(stats.mean_pupil_evoked_mag(valid & logical(session_numbers_unique')), stats.base_p_subevoked_p_R(valid & logical(session_numbers_unique')), 'ok','MarkerFaceColor','w')
    lsline;
    title('Pupil-Pupil')
    ylabel('R')
    xlabel('mean evoked pupil')
    [R,P] = corr(stats.mean_pupil_evoked_mag(valid & logical(session_numbers_unique')), stats.base_p_subevoked_p_R(valid & logical(session_numbers_unique')), 'type', 'Spearman')
    axis square;
    ylim([-1 1]);

    subplot(2,4,2);
    plot(stats.mean_spike_evoked_mag(valid), stats.base_FR_subevoked_FR_R(valid), 'ok','MarkerFaceColor','w')
    lsline
    title('Base FR Evoked FR')
    ylabel('R')
    xlabel('mean evoked FR')
    [R,P] = corr(stats.mean_spike_evoked_mag(valid), stats.base_FR_subevoked_FR_R(valid), 'type', 'Spearman')
    axis square;
    ylim([-1 1]);

    subplot(2,4,3);
    plot(stats.mean_spike_evoked_mag(valid), stats.base_p_subevoked_FR_R(valid), 'ok','MarkerFaceColor','w')
    lsline
    title('Base Pupil Evoked FR')
    ylabel('R')
    xlabel('mean evoked FR')
    [R,P] = corr(stats.mean_spike_evoked_mag(valid), stats.base_p_subevoked_FR_R(valid), 'type', 'Spearman')
    axis square;
    ylim([-1 1]);

    subplot(2,4,4);
    plot(stats.mean_pupil_evoked_mag(valid), stats.subevoked_p_base_FR_R(valid), 'ok','MarkerFaceColor','w')
    lsline
    title('Base FR Evoked Pupil')
    ylabel('R')
    xlabel('mean evoked pupil')
    [R,P] = corr(stats.mean_pupil_evoked_mag(valid), stats.subevoked_p_base_FR_R(valid), 'type', 'Spearman')
    axis square;
    ylim([-1 1]);

    % Second row looks at range
    subplot(2,4,5);
    plot(stats.range_pupil_evoked_mag(valid & logical(session_numbers_unique')), stats.base_p_subevoked_p_R(valid & logical(session_numbers_unique')), 'ok','MarkerFaceColor','w')
    lsline;
    title('Pupil-Pupil')
    ylabel('R')
    xlabel('range evoked pupil')
    [R,P] = corr(stats.range_pupil_evoked_mag(valid & logical(session_numbers_unique')), stats.base_p_subevoked_p_R(valid & logical(session_numbers_unique')), 'type', 'Spearman')
    axis square;
    ylim([-1 1]);

    subplot(2,4,6);
    plot(stats.range_spike_evoked_mag(valid), stats.base_FR_subevoked_FR_R(valid), 'ok','MarkerFaceColor','w')
    lsline
    title('Base FR Evoked FR')
    ylabel('R')
    xlabel('range evoked FR')
    [R,P] = corr(stats.range_spike_evoked_mag(valid), stats.base_FR_subevoked_FR_R(valid), 'type', 'Spearman')
    axis square;
    ylim([-1 1]);

    subplot(2,4,7);
    plot(stats.range_spike_evoked_mag(valid), stats.base_p_subevoked_FR_R(valid), 'ok','MarkerFaceColor','w')
    lsline
    title('Base Pupil Evoked FR')
    ylabel('R')
    xlabel('range evoked FR')
    [R_spike_range(m),P_spike_range(m)] = corr(stats.range_spike_evoked_mag(valid), stats.base_p_subevoked_FR_R(valid), 'type', 'Spearman')
    axis square;
    ylim([-1 1]);

    subplot(2,4,8);
    plot(stats.range_pupil_evoked_mag(valid), stats.subevoked_p_base_FR_R(valid), 'ok','MarkerFaceColor','w')
    lsline
    title('Base FR Evoked Pupil')
    ylabel('R')
    xlabel('range evoked pupil')
    [R_pupil_range(m),P_pupil_range(m)] = corr(stats.range_pupil_evoked_mag(valid), stats.subevoked_p_base_FR_R(valid), 'type', 'Spearman')
    axis square;
    ylim([-1 1]);

    %% Does the LLR correlate with range?
    figure; hold on;
    subplot(2,4,1); hold on;
    plot(stats.range_pupil_evoked_mag(valid), stats.pEvoked_v_sBase_LLR(valid), 'ok','MarkerFaceColor','w')
    lsline
    title('Evoked Pupil v Base FR');
    ylabel('LLR');
    xlabel('Evoked Pupil Range');
    axis square;

    subplot(2,4,5); hold on;
    plot(stats.range_spike_baseline(valid), stats.pEvoked_v_sBase_LLR(valid), 'ok','MarkerFaceColor','w')
    lsline
    title('Evoked Pupil v Base FR');
    ylabel('LLR');
    xlabel('Baseline Spike Range');
    axis square;
end
% Does the LLR correlate with magnitude
% Do the "inverse" cross measure comparisons correlate with range?
% Do the "inverse" cross measure comparisons correlate with magnitude?
