%% Debug firing rate differences between legacy and new code
% This script directly compares firing rates from getData.m output vs compute_data output

clear all; close all;

% First, run legacy getData.m to get its output
addpath(genpath('/Users/lowell/Documents/GitHub/LCPupil_Joshi_Analysis/Code/Updated'));
cd /Users/lowell/Documents/GitHub/LCPupil_Joshi_Analysis;

% Create a temporary copy of getData without plotting
disp('Running legacy getData.m...');
save_figs_bak = exist('save_figs','var') && save_figs;
clear all;
collect_data = true;
save_figs = false;
do_zscore = true;

% Run the legacy getData.m - we'll capture its outputs
run /Users/lowell/Documents/GitHub/LCPupil_Joshi_Analysis/Code/Updated/getData.m;
legacy_LC_Beep = LC_Beep_table;
legacy_LC_Fix = LC_Fix_table;

% Now run the new compute_data
disp('Running new compute_data...');
clear all;
paths = config_paths();
compute_data(paths, struct('force', true));
load(fullfile(paths.data_cache, 'LC_data_raw.mat'));
new_LC_Beep = LC_Beep_table;
new_LC_Fix = LC_Fix_table;

% Compare statistics
fprintf('\n=== FIRING RATE COMPARISON ===\n');
fprintf('Legacy Beep spike_baseline: mean=%.4f, median=%.4f, std=%.4f, min=%.4f, max=%.4f\n', ...
    mean(legacy_LC_Beep.spike_baseline, 'omitnan'), ...
    median(legacy_LC_Beep.spike_baseline, 'omitnan'), ...
    std(legacy_LC_Beep.spike_baseline, 'omitnan'), ...
    min(legacy_LC_Beep.spike_baseline(~isnan(legacy_LC_Beep.spike_baseline))), ...
    max(legacy_LC_Beep.spike_baseline(~isnan(legacy_LC_Beep.spike_baseline))));

fprintf('New Beep spike_baseline:     mean=%.4f, median=%.4f, std=%.4f, min=%.4f, max=%.4f\n', ...
    mean(new_LC_Beep.spike_baseline, 'omitnan'), ...
    median(new_LC_Beep.spike_baseline, 'omitnan'), ...
    std(new_LC_Beep.spike_baseline, 'omitnan'), ...
    min(new_LC_Beep.spike_baseline(~isnan(new_LC_Beep.spike_baseline))), ...
    max(new_LC_Beep.spike_baseline(~isnan(new_LC_Beep.spike_baseline))));

fprintf('\nRatio (Legacy/New): %.4f\n', ...
    mean(legacy_LC_Beep.spike_baseline(~isnan(legacy_LC_Beep.spike_baseline))) / ...
    mean(new_LC_Beep.spike_baseline(~isnan(new_LC_Beep.spike_baseline))));

fprintf('\n=== BASELINE-SUBTRACTED EVOKED COMPARISON ===\n');
fprintf('Legacy Beep spike_bs_evoked: mean=%.4f, median=%.4f, std=%.4f\n', ...
    mean(legacy_LC_Beep.spike_bs_evoked, 'omitnan'), ...
    median(legacy_LC_Beep.spike_bs_evoked, 'omitnan'), ...
    std(legacy_LC_Beep.spike_bs_evoked, 'omitnan'));

fprintf('New Beep spike_bs_evoked:     mean=%.4f, median=%.4f, std=%.4f\n', ...
    mean(new_LC_Beep.spike_bs_evoked, 'omitnan'), ...
    median(new_LC_Beep.spike_bs_evoked, 'omitnan'), ...
    std(new_LC_Beep.spike_bs_evoked, 'omitnan'));

fprintf('\nRatio (Legacy/New): %.4f\n', ...
    mean(legacy_LC_Beep.spike_bs_evoked(~isnan(legacy_LC_Beep.spike_bs_evoked))) / ...
    mean(new_LC_Beep.spike_bs_evoked(~isnan(new_LC_Beep.spike_bs_evoked))));

% Compare drift residuals
fprintf('\n=== DRIFT RESIDUALS COMPARISON ===\n');
fprintf('Legacy spike_drift_residuals: mean=%.4f, std=%.4f\n', ...
    mean(legacy_LC_Beep.spike_drift_residuals, 'omitnan'), ...
    std(legacy_LC_Beep.spike_drift_residuals, 'omitnan'));

fprintf('New spike_drift_residuals:     mean=%.4f, std=%.4f\n', ...
    mean(new_LC_Beep.spike_drift_residuals, 'omitnan'), ...
    std(new_LC_Beep.spike_drift_residuals, 'omitnan'));

fprintf('\nRatio (Legacy/New): %.4f\n', ...
    mean(legacy_LC_Beep.spike_drift_residuals(~isnan(legacy_LC_Beep.spike_drift_residuals))) / ...
    mean(new_LC_Beep.spike_drift_residuals(~isnan(new_LC_Beep.spike_drift_residuals))));

% Find example units
fprintf('\n=== EXAMPLE UNITS ===\n');
example_unit_ids = [10, 25, 60, 97];
for ex_id = example_unit_ids
    legacy_rows = legacy_LC_Beep(legacy_LC_Beep.unit_id == ex_id, :);
    new_rows = new_LC_Beep(new_LC_Beep.unit_id == ex_id, :);
    fprintf('Unit %d: Legacy has %d beep rows, New has %d beep rows\n', ...
        ex_id, height(legacy_rows), height(new_rows));
    if height(legacy_rows) > 0 && height(new_rows) > 0
        fprintf('  Legacy spike_baseline[1:3]: [%.4f, %.4f, %.4f]\n', ...
            legacy_rows.spike_baseline(1:min(3,height(legacy_rows))));
        fprintf('  New spike_baseline[1:3]:     [%.4f, %.4f, %.4f]\n', ...
            new_rows.spike_baseline(1:min(3,height(new_rows))));
    end
end

%% Save for inspection
save('/tmp/firing_rate_debug.mat', 'legacy_LC_Beep', 'new_LC_Beep');
