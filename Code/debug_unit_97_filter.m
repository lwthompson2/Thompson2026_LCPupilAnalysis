%% Debug unit 97 specifically - why are its beep trials filtered out?

clear all; close all;

fprintf('=== DEBUGGING UNIT 97 FILTERING ===\n\n');

% Load the specific file that contains unit 97
base_dir = '/Users/lowell/Documents/GitHub/LCPupil_Joshi_Analysis/Data/Cleaned/Cicero/LC';
fname = 'Cicero_032014_d15_700_FixnBeep.mat';

s = load(fullfile(base_dir, fname));
siteData = s.siteData;

times = [-100 0; 0 800; -400 0; 0 200];

% Find beep/fix trials
Fbeep = find(siteData{1}(:,3)==1 & ...
    siteData{1}(:,4)>abs(min(times(:,1))) & ...
    siteData{1}(:,4)<size(siteData{2},2)-max(times(:,2)));
Ffix = find(siteData{1}(:,3)==1 & ...
    isnan(siteData{1}(:,4)) & ...
    isnan(siteData{1}(:,9)));
num_single_units = max(0, size(siteData{3},2)-1);

fprintf('File: %s\n', fname);
fprintf('Total beep trials: %d\n', numel(Fbeep));
fprintf('Total fix trials: %d\n', numel(Ffix));
fprintf('Number of units: %d\n\n', num_single_units);

% Process unit 1 (which is unit 97 in the global numbering)
uu = 1;
fprintf('Processing Unit %d (global ID 97):\n', uu);
fprintf('==========================================\n\n');

% Extract spike counts for all beep trials
nb = numel(Fbeep);
spike_rate_data = nan(nb, 2);
pupil_data = nan(nb, 2);
baseline_times = nan(nb, 1);

for bb = 1:nb
    bt = Fbeep(bb);
    beep_time = siteData{1}(bt,4);
    baseline_times(bb) = beep_time;
    
    % Get spike data
    sp = [];
    try
        if iscell(siteData{3}) && size(siteData{3},1) >= bt && size(siteData{3},2) >= uu+1
            sp = siteData{3}{bt, uu+1};
        end
    catch
    end
    
    if ~isempty(sp)
        % baseline
        baseline_count = sum(sp >= 0 & sp < beep_time + times(3,2));
        spike_rate_data(bb, 1) = baseline_count / beep_time * 1000;
        
        % evoked
        evoked_count = sum(sp >= beep_time + times(4,1) & sp <= beep_time + times(4,2));
        spike_rate_data(bb, 2) = evoked_count / diff(times(4,:)) * 1000;
    end
    
    % Get pupil data
    pd = [];
    if size(siteData{2}, 1) >= bt && size(siteData{2}, 2) >= 1
        if ndims(siteData{2}) >= 3
            pd = squeeze(siteData{2}(bt, :, 4));
        else
            pd = squeeze(siteData{2}(bt, :));
        end
    end
    
    if ~isempty(pd) && isvector(pd)
        bi = round(beep_time) + 1;
        bi = min(bi, numel(pd));
        pupil_data(bb, 1) = mean(pd(1:bi), 'omitnan');
        
        pupil_evoked_times = times(2,1):times(2,2);
        ev_idx = bi + pupil_evoked_times;
        ev_idx = ev_idx(ev_idx >= 1 & ev_idx <= numel(pd));
        if ~isempty(ev_idx)
            sm = movmean(pd(ev_idx) - pupil_data(bb,1), 50, 'omitnan');
            if ~isempty(sm)
                max_evoked = max(sm);
                min_evoked = min(sm);
                if abs(max_evoked) > abs(min_evoked)
                    pupil_data(bb, 2) = max_evoked;
                else
                    pupil_data(bb, 2) = min_evoked;
                end
            end
        end
    end
end

% Now compute the mask components separately
fprintf('Computing filter mask components:\n\n');

% Component 1: isfinite(spike_rate_data(:,1,uu))
comp1 = isfinite(spike_rate_data(:,1));
fprintf('Component 1: isfinite(spike_baseline) = %d/%d\n', sum(comp1), nb);

% Component 2: isfinite(pupil_data(:,1))
comp2 = isfinite(pupil_data(:,1));
fprintf('Component 2: isfinite(pupil_baseline) = %d/%d\n', sum(comp2), nb);

% Component 3: isfinite(pupil_data(:,2))
comp3 = isfinite(pupil_data(:,2));
fprintf('Component 3: isfinite(pupil_bs_evoked) = %d/%d\n', sum(comp3), nb);

% Component 4: abs(zscore(spike_rate_data(:,2,uu)))<8
evoked_z = zscore(spike_rate_data(:,2));
comp4 = (evoked_z < 8);
fprintf('Component 4: abs(zscore(spike_evoked)) < 8 = %d/%d\n', sum(comp4), nb);

% Show which trials fail each component
fprintf('\nTrials failing each component:\n');
fprintf('Fail comp1 (spike_baseline not finite): ');
failing_comp1 = find(~comp1);
fprintf('[%s]\n', num2str(failing_comp1'));

fprintf('Fail comp2 (pupil_baseline not finite): ');
failing_comp2 = find(~comp2);
fprintf('[%s]\n', num2str(failing_comp2'));

fprintf('Fail comp3 (pupil_evoked not finite): ');
failing_comp3 = find(~comp3);
fprintf('[%s]\n', num2str(failing_comp3'));

fprintf('Fail comp4 (abs(zscore(spike_evoked)) >= 8): ');
failing_comp4 = find(~comp4);
fprintf('[%s]\n', num2str(failing_comp4'));

% Final mask
Lg = comp1 & comp2 & comp3 & comp4;
fprintf('\nFinal mask (all components): %d/%d trials pass\n', sum(Lg), nb);

fprintf('\nTrials that FAIL the final mask:\n');
failing_all = find(~Lg);
fprintf('Indices: [%s]\n', num2str(failing_all'));

% Show details of failing trials
if ~isempty(failing_all)
    fprintf('\nDetailed breakdown of failing trials:\n');
    for ii = 1:min(5, length(failing_all))
        trial_idx = failing_all(ii);
        fprintf('\nTrial %d:\n', trial_idx);
        fprintf('  spike_baseline: %.6f (finite: %d)\n', spike_rate_data(trial_idx,1), comp1(trial_idx));
        fprintf('  spike_evoked: %.6f (z-score: %.6f, <8: %d)\n', spike_rate_data(trial_idx,2), evoked_z(trial_idx), comp4(trial_idx));
        fprintf('  pupil_baseline: %.6f (finite: %d)\n', pupil_data(trial_idx,1), comp2(trial_idx));
        fprintf('  pupil_evoked: %.6f (finite: %d)\n', pupil_data(trial_idx,2), comp3(trial_idx));
        fprintf('  Pass: %d\n', Lg(trial_idx));
    end
end

fprintf('\n\nSUMMARY:\n');
fprintf('Unit 97 in file Cicero_032014_d15_700_FixnBeep.mat:\n');
fprintf('  Total beep trials available: %d\n', nb);
fprintf('  Trials passing Lg filter: %d\n', sum(Lg));
fprintf('  Trials failing Lg filter: %d\n', sum(~Lg));
fprintf('\nThis explains why unit 97 has NO beep rows in the output!\n');
