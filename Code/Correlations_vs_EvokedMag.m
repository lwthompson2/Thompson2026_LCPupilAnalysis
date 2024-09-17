%% Are evoked magnitudes related to correlations?
% Change to mean(response) rather than abs responses.
% Try not changing the R values to R2
% change x & y saccades

% Plot the trend over time for all sessions (pupil and blah);
% Fit a line and look at a scatter plot of the linear fits (slope) over time?


valid = isfinite(subevoked_p_base_FR_R) & isfinite(base_FR_subevoked_FR_R);

figure; hold on;
subplot(1,4,1);
plot(base_p_subevoked_p_R(valid).^2, pupil_evoked_mag(valid), 'o')
lsline;
title('Pupil-Pupil')
xlabel('R^2')
ylabel('mean(abs(evoked pupil))')
[R,P] = corr(base_p_subevoked_p_R(valid).^2', pupil_evoked_mag(valid)', 'type', 'Spearman')

subplot(1,4,2);
plot(base_FR_subevoked_FR_R(valid).^2, spike_evoked_mag(valid), 'o')
lsline
title('Base FR Evoked FR')
xlabel('R^2')
ylabel('mean(abs(evoked FR))')
[R,P] = corr(base_FR_subevoked_FR_R(valid).^2', spike_evoked_mag(valid)', 'type', 'Spearman')

subplot(1,4,3);
plot(base_p_subevoked_FR_R(valid).^2, spike_evoked_mag(valid), 'o')
lsline
title('Base Pupil Evoked FR')
xlabel('R^2')
ylabel('mean(abs(evoked FR))')
[R,P] = corr(base_p_subevoked_FR_R(valid).^2', spike_evoked_mag(valid)', 'type', 'Spearman')

subplot(1,4,4);
plot(subevoked_p_base_FR_R(valid).^2, pupil_evoked_mag(valid), 'o')
lsline
title('Base FR Evoked Pupil')
xlabel('R^2')
ylabel('mean(abs(evoked pupil))')
[R,P] = corr(subevoked_p_base_FR_R(valid).^2', pupil_evoked_mag(valid)', 'type', 'Spearman')
