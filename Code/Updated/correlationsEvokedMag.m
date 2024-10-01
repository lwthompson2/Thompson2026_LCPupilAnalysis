%% Are evoked magnitudes related to correlations?
% Change to mean(response) rather than abs responses.
% Try not changing the R values to R2
% change x & y saccades

% Plot the trend over time for all sessions (pupil and blah);
% Fit a line and look at a scatter plot of the linear fits (slope) over time?


valid = isfinite(stats.subevoked_p_base_FR_R) & isfinite(stats.base_FR_subevoked_FR_R);

figure; hold on;
subplot(1,4,1);
plot(stats.base_p_subevoked_p_R(valid), stats.mean_pupil_evoked_mag(valid), 'ok','MarkerFaceColor','k')
lsline;
title('Pupil-Pupil')
xlabel('R')
ylabel('mean evoked pupil')
[R,P] = corr(stats.base_p_subevoked_p_R(valid), stats.mean_pupil_evoked_mag(valid), 'type', 'Spearman')
axis square;
xlim([-1 1]);

subplot(1,4,2);
plot(stats.base_FR_subevoked_FR_R(valid), stats.mean_spike_evoked_mag(valid), 'ok','MarkerFaceColor','k')
lsline
title('Base FR Evoked FR')
xlabel('R')
ylabel('mean evoked FR')
[R,P] = corr(stats.base_FR_subevoked_FR_R(valid), stats.mean_spike_evoked_mag(valid), 'type', 'Spearman')
axis square;
xlim([-1 1]);

subplot(1,4,3);
plot(stats.base_p_subevoked_FR_R(valid), stats.mean_spike_evoked_mag(valid), 'ok','MarkerFaceColor','k')
lsline
title('Base Pupil Evoked FR')
xlabel('R')
ylabel('mean evoked FR')
[R,P] = corr(stats.base_p_subevoked_FR_R(valid), stats.mean_spike_evoked_mag(valid), 'type', 'Spearman')
axis square;
xlim([-1 1]);

subplot(1,4,4);
plot(stats.subevoked_p_base_FR_R(valid), stats.mean_pupil_evoked_mag(valid), 'ok','MarkerFaceColor','k')
lsline
title('Base FR Evoked Pupil')
xlabel('R')
ylabel('mean evoked pupil')
[R,P] = corr(stats.subevoked_p_base_FR_R(valid), stats.mean_pupil_evoked_mag(valid), 'type', 'Spearman')
axis square;
xlim([-1 1]);
