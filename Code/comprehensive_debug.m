%% Comprehensive debug script for user to run
% Shows: (1) Fourth example data availability, (2) Firing rate scaling factors

clear all; close all;

paths = config_paths();
fprintf('=== LC PUPIL DATA DEBUGGING ===\n\n');

%% PART 1: Check data availability for all four examples
fprintf('PART 1: EXAMPLE UNITS DATA AVAILABILITY\n');
fprintf('==========================================\n\n');

if exist(fullfile(paths.results_dir, 'LC_data_raw.mat'), 'file')
    load(fullfile(paths.results_dir, 'LC_data_raw.mat'));
    
    example_ids = [10, 25, 60, 97];
    
    for ex_idx = 1:length(example_ids)
        unit_id = example_ids(ex_idx);
        beep_rows = LC_Beep_table(LC_Beep_table.unit_id == unit_id, :);
        fix_rows = LC_Fix_table(LC_Fix_table.unit_id == unit_id, :);
        
        fprintf('Example %d - Unit ID %d:\n', ex_idx, unit_id);
        fprintf('  Beep rows: %d\n', height(beep_rows));
        fprintf('  Fix rows: %d\n', height(fix_rows));
        
        if height(beep_rows) > 0
            fprintf('  spike_baseline: mean=%.6f, has NaN=%d/%d\n', ...
                mean(beep_rows.spike_baseline, 'omitnan'), ...
                sum(isnan(beep_rows.spike_baseline)), ...
                height(beep_rows));
            fprintf('  spike_bs_evoked: mean=%.6f, has NaN=%d/%d\n', ...
                mean(beep_rows.spike_bs_evoked, 'omitnan'), ...
                sum(isnan(beep_rows.spike_bs_evoked)), ...
                height(beep_rows));
        else
            fprintf('  *** NO BEEP DATA ***\n');
        end
        fprintf('\n');
    end
else
    fprintf('ERROR: Cached data not found at %s\n', fullfile(paths.results_dir, 'LC_data_raw.mat'));
    fprintf('Please run: paths = config_paths(); compute_data(paths, struct(''force'', true));\n');
    return;
end

%% PART 2: Global firing rate statistics
fprintf('\n');
fprintf('PART 2: GLOBAL FIRING RATE STATISTICS\n');
fprintf('======================================\n\n');

fprintf('ALL BEEP TRIALS (combined):\n');
fprintf('  spike_baseline:\n');
fprintf('    Mean: %.6f\n', mean(LC_Beep_table.spike_baseline, 'omitnan'));
fprintf('    Median: %.6f\n', median(LC_Beep_table.spike_baseline, 'omitnan'));
fprintf('    Std: %.6f\n', std(LC_Beep_table.spike_baseline, 'omitnan'));
fprintf('    Min: %.6f\n', min(LC_Beep_table.spike_baseline(~isnan(LC_Beep_table.spike_baseline))));
fprintf('    Max: %.6f\n', max(LC_Beep_table.spike_baseline(~isnan(LC_Beep_table.spike_baseline))));

fprintf('\n  spike_bs_evoked (baseline-subtracted evoked):\n');
fprintf('    Mean: %.6f\n', mean(LC_Beep_table.spike_bs_evoked, 'omitnan'));
fprintf('    Median: %.6f\n', median(LC_Beep_table.spike_bs_evoked, 'omitnan'));
fprintf('    Std: %.6f\n', std(LC_Beep_table.spike_bs_evoked, 'omitnan'));

fprintf('\n  spike_drift_residuals (should be near 0):\n');
fprintf('    Mean: %.6f\n', mean(LC_Beep_table.spike_drift_residuals, 'omitnan'));
fprintf('    Std: %.6f\n', std(LC_Beep_table.spike_drift_residuals, 'omitnan'));

%% PART 3: Per-unit statistics to look for patterns
fprintf('\n');
fprintf('PART 3: PER-UNIT STATISTICS (first 10 units with data)\n');
fprintf('========================================================\n\n');

unique_units = unique(LC_Beep_table.unit_id(~isnan(LC_Beep_table.unit_id)));
for uu = 1:min(10, length(unique_units))
    uid = unique_units(uu);
    unit_data = LC_Beep_table(LC_Beep_table.unit_id == uid, :);
    if height(unit_data) > 3
        fprintf('Unit %d: %d trials\n', uid, height(unit_data));
        fprintf('  baseline: mean=%.6f, std=%.6f\n', ...
            mean(unit_data.spike_baseline, 'omitnan'), ...
            std(unit_data.spike_baseline, 'omitnan'));
        fprintf('  bs_evoked: mean=%.6f\n', ...
            mean(unit_data.spike_bs_evoked, 'omitnan'));
    end
end

%% PART 4: Recommended next steps
fprintf('\n');
fprintf('PART 4: NEXT STEPS\n');
fprintf('=======================\n\n');

if height(LC_Beep_table(LC_Beep_table.unit_id == 97, :)) == 0
    fprintf('>>> Unit 97 has NO beep rows. This explains the missing evoked data.\n');
    fprintf('>>> Possible causes:\n');
    fprintf('    1. Unit 97''s source file doesn''t have both beep AND fix trials\n');
    fprintf('    2. All of unit 97''s beep trials were filtered out by Lg mask\n');
    fprintf('    3. Unit 97 wasn''t mapped correctly in legacy_unit_map\n');
else
    fprintf('>>> Unit 97 has %d beep rows. The missing evoked data is puzzling.\n', ...
        height(LC_Beep_table(LC_Beep_table.unit_id == 97, :)));
end

fprintf('\n>>> For the ~2x firing rate difference:\n');
fprintf('    Compare these values against legacy getData.m output.\n');
fprintf('    The discrepancy could be in:\n');
fprintf('    1. Spike counting window (beep_time denominator)\n');
fprintf('    2. Evoked window duration (200 ms)\n');
fprintf('    3. Z-scoring application\n');
fprintf('    4. Data units (counts vs rates)\n');
