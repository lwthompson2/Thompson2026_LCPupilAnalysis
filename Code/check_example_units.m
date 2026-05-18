%% Check fourth example unit data
% Simple script to show what data we have for example unit 97

clear all; close all;

paths = config_paths();

% First check if we have cached data
if exist(fullfile(paths.results_dir, 'LC_data_raw.mat'), 'file')
    load(fullfile(paths.results_dir, 'LC_data_raw.mat'));
    
    % Example unit IDs
    example_ids = [10, 25, 60, 97];
    
    for eid = example_ids
        beep_rows = LC_Beep_table(LC_Beep_table.unit_id == eid, :);
        fix_rows = LC_Fix_table(LC_Fix_table.unit_id == eid, :);
        
        fprintf('Unit %d:\n', eid);
        fprintf('  Beep table: %d rows\n', height(beep_rows));
        fprintf('  Fix table: %d rows\n', height(fix_rows));
        
        if height(beep_rows) > 0
            fprintf('  Beep spike_baseline: mean=%.4f, min=%.4f, max=%.4f\n', ...
                mean(beep_rows.spike_baseline, 'omitnan'), ...
                min(beep_rows.spike_baseline(~isnan(beep_rows.spike_baseline))), ...
                max(beep_rows.spike_baseline(~isnan(beep_rows.spike_baseline))));
            fprintf('  Beep spike_bs_evoked: mean=%.4f, min=%.4f, max=%.4f\n', ...
                mean(beep_rows.spike_bs_evoked, 'omitnan'), ...
                min(beep_rows.spike_bs_evoked(~isnan(beep_rows.spike_bs_evoked))), ...
                max(beep_rows.spike_bs_evoked(~isnan(beep_rows.spike_bs_evoked))));
            fprintf('  Beep pupil_baseline: mean=%.4f\n', mean(beep_rows.pupil_baseline, 'omitnan'));
            fprintf('  Beep pupil_bs_evoked: mean=%.4f\n', mean(beep_rows.pupil_bs_evoked, 'omitnan'));
        else
            fprintf('  *** NO BEEP ROWS ***\n');
        end
        fprintf('\n');
    end
else
    fprintf('Cached data not found. Run compute_data first.\n');
end
