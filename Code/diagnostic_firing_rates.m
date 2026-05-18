%% Comprehensive firing rate diagnostic
% This script compares firing rates and diagnostic info between legacy and new code

clear all; close all;

fprintf('=== FIRING RATE DIAGNOSTIC ===\n\n');

% Load new code outputs
paths = config_paths();
if exist(fullfile(paths.results_dir, 'LC_data_raw.mat'), 'file')
    load(fullfile(paths.results_dir, 'LC_data_raw.mat'));
    new_beep = LC_Beep_table;
    new_fix = LC_Fix_table;
    fprintf('Loaded new code data.\n');
else
    fprintf('ERROR: New code data not found. Run compute_data first.\n');
    return;
end

% Get one unit that has data
example_unit = 10;
beep_data = new_beep(new_beep.unit_id == example_unit, :);

if isempty(beep_data)
    fprintf('No data for unit %d\n', example_unit);
    return;
end

fprintf('\nExample Unit: %d\n', example_unit);
fprintf('Number of beep trials: %d\n', height(beep_data));

% Show sample values
fprintf('\nSample values (first 5 trials):\n');
fprintf('  Trial#  spike_baseline  spike_bs_evoked  pupil_baseline  pupil_bs_evoked\n');
for ii = 1:min(5, height(beep_data))
    fprintf('  %3d     %12.6f    %12.6f    %12.6f    %12.6f\n', ...
        ii, ...
        beep_data.spike_baseline(ii), ...
        beep_data.spike_bs_evoked(ii), ...
        beep_data.pupil_baseline(ii), ...
        beep_data.pupil_bs_evoked(ii));
end

% Check statistics
fprintf('\nBaseline firing rate statistics:\n');
fprintf('  mean: %.6f\n', mean(beep_data.spike_baseline, 'omitnan'));
fprintf('  std:  %.6f\n', std(beep_data.spike_baseline, 'omitnan'));
fprintf('  min:  %.6f\n', min(beep_data.spike_baseline(~isnan(beep_data.spike_baseline))));
fprintf('  max:  %.6f\n', max(beep_data.spike_baseline(~isnan(beep_data.spike_baseline))));

fprintf('\nEvoked (baseline-subtracted) firing rate statistics:\n');
fprintf('  mean: %.6f\n', mean(beep_data.spike_bs_evoked, 'omitnan'));
fprintf('  std:  %.6f\n', std(beep_data.spike_bs_evoked, 'omitnan'));
fprintf('  min:  %.6f\n', min(beep_data.spike_bs_evoked(~isnan(beep_data.spike_bs_evoked))));
fprintf('  max:  %.6f\n', max(beep_data.spike_bs_evoked(~isnan(beep_data.spike_bs_evoked))));

% Check the raw (non z-scored) values if available
fprintf('\nRaw evoked firing rate statistics (non z-scored):\n');
fprintf('  mean: %.6f\n', mean(beep_data.raw_spike_evoked, 'omitnan'));
fprintf('  std:  %.6f\n', std(beep_data.raw_spike_evoked, 'omitnan'));

% Check drift residuals
fprintf('\nDrift residuals (should be near 0 mean):\n');
fprintf('  spike_drift mean: %.6f\n', mean(beep_data.spike_drift_residuals, 'omitnan'));
fprintf('  pupil_drift mean: %.6f\n', mean(beep_data.pupil_drift_residuals, 'omitnan'));

% Check fourth example status
fprintf('\n\n=== FOURTH EXAMPLE UNIT (unit_id = 97) ===\n');
unit_97 = new_beep(new_beep.unit_id == 97, :);
fprintf('Number of beep rows: %d\n', height(unit_97));
if height(unit_97) > 0
    fprintf('spike_baseline mean: %.6f\n', mean(unit_97.spike_baseline, 'omitnan'));
    fprintf('spike_bs_evoked mean: %.6f\n', mean(unit_97.spike_bs_evoked, 'omitnan'));
else
    fprintf('*** NO BEEP ROWS FOR UNIT 97 ***\n');
end
