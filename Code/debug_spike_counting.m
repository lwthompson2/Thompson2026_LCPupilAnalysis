%% Step-by-step comparison of spike rate computation for one trial
% This shows exactly how rates are computed to identify the 2x factor

clear all; close all;

addpath(genpath('/Users/lowell/Documents/GitHub/LCPupil_Joshi_Analysis/Code/Updated'));

fprintf('=== STEP-BY-STEP SPIKE RATE COMPUTATION ===\n\n');

% Load one raw data file
monkeys = {'Oz'};
for mm = 1:length(monkeys)
    [base_dir, fnames] = getLCP_cleanDataDir(monkeys{mm}, 'LC');
    if ~isempty(fnames)
        fname = fnames{1};
        full_path = fullfile(base_dir, fname);
        fprintf('Loading: %s\n\n', fname);
        
        s = load(full_path);
        siteData = s.siteData;
        
        times = [-100 0; 0 800; -400 0; 0 200];
        
        % Find beep trials
        Fbeep = find(siteData{1}(:,3)==1 & ...
            siteData{1}(:,4)>abs(min(times(:,1))) & ...
            siteData{1}(:,4)<size(siteData{2},2)-max(times(:,2)));
        num_single_units = max(0, size(siteData{3},2)-1);
        
        if ~isempty(Fbeep) && num_single_units > 0
            % Pick first trial and first unit
            bb = 1;
            uu = 1;
            bt = Fbeep(bb);
            
            fprintf('Trial %d (index %d), Unit %d\n', bb, bt, uu);
            fprintf('---\n\n');
            
            % Extract spike times
            sp = [];
            try
                if iscell(siteData{3}) && size(siteData{3},1) >= bt && size(siteData{3},2) >= uu+1
                    sp = siteData{3}{bt, uu+1};
                end
            catch
            end
            
            if ~isempty(sp)
                % Get beep time
                beep_time = siteData{1}(bt,4);
                fprintf('beep_time: %.1f ms\n', beep_time);
                fprintf('times(3,:) = [%d, %d] (baseline window relative to beep)\n', times(3,1), times(3,2));
                fprintf('times(4,:) = [%d, %d] (evoked window relative to beep)\n', times(4,1), times(4,2));
                fprintf('\n');
                
                % BASELINE spike counting
                fprintf('BASELINE SPIKE COUNTING:\n');
                fprintf('  Window condition: sp >= 0 & sp < beep_time + times(3,2)\n');
                fprintf('  Calculated as: sp >= 0 & sp < %.1f + %d = sp < %.1f\n', beep_time, times(3,2), beep_time + times(3,2));
                baseline_mask = sp >= 0 & sp < beep_time + times(3,2);
                baseline_count = sum(baseline_mask);
                fprintf('  Spike count in window: %d\n', baseline_count);
                fprintf('  Times of these spikes (first 10): ');
                spike_times_in_baseline = sp(baseline_mask);
                fprintf('[%s]\n', num2str(spike_times_in_baseline(1:min(10, length(spike_times_in_baseline)))));
                
                % Convert to rate
                fprintf('\n  Firing rate calculation:\n');
                fprintf('    Spike count / baseline_times * 1000\n');
                fprintf('    = %d / %.1f * 1000\n', baseline_count, beep_time);
                baseline_rate = baseline_count / beep_time * 1000;
                fprintf('    = %.6f Hz\n', baseline_rate);
                
                % EVOKED spike counting
                fprintf('\nEVOKED SPIKE COUNTING:\n');
                fprintf('  Window condition: sp >= beep_time + times(4,1) & sp <= beep_time + times(4,2)\n');
                fprintf('  Calculated as: sp >= %.1f + %d & sp <= %.1f + %d\n', beep_time, times(4,1), beep_time, times(4,2));
                fprintf('  = sp >= %.1f & sp <= %.1f\n', beep_time + times(4,1), beep_time + times(4,2));
                evoked_mask = sp >= beep_time + times(4,1) & sp <= beep_time + times(4,2);
                evoked_count = sum(evoked_mask);
                fprintf('  Spike count in window: %d\n', evoked_count);
                fprintf('  Times of these spikes: ');
                spike_times_in_evoked = sp(evoked_mask);
                fprintf('[%s]\n', num2str(spike_times_in_evoked));
                
                % Convert to rate
                fprintf('\n  Firing rate calculation:\n');
                fprintf('    Spike count / (diff(times(4,:))) * 1000\n');
                fprintf('    = %d / %d * 1000\n', evoked_count, diff(times(4,:)));
                evoked_rate = evoked_count / diff(times(4,:)) * 1000;
                fprintf('    = %.6f Hz\n', evoked_rate);
                
                % Show all spikes with timing info
                fprintf('\n\nALL SPIKES FOR THIS TRIAL/UNIT:\n');
                fprintf('Number of total spikes: %d\n', length(sp));
                fprintf('Spike times (all): [%s]\n', num2str(sort(sp)));
                
                % Double-check the windows
                fprintf('\n\nWINDOW VERIFICATION:\n');
                fprintf('Baseline window: [0, %.1f) - spikes in this window: %d\n', beep_time + times(3,2), baseline_count);
                fprintf('Evoked window:   [%.1f, %.1f] - spikes in this window: %d\n', beep_time + times(4,1), beep_time + times(4,2), evoked_count);
                fprintf('Before baseline: [spikes < 0] - count: %d\n', sum(sp < 0));
                fprintf('After evoked:    [spikes > %.1f] - count: %d\n', beep_time + times(4,2), sum(sp > beep_time + times(4,2)));
                
            else
                fprintf('No spikes for this trial/unit\n');
            end
            
        end
        break;
    end
end
