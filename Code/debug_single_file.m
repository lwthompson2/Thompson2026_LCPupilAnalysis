%% Minimal test: compare firing rate computation on single file
% This script loads one raw data file and compares legacy vs new rate computation

close all; clear all;

% Get list of files
monkeys = {'Oz' 'Cicero'};
for mm = 1:length(monkeys)
    addpath(genpath(sprintf('/Users/lowell/Documents/GitHub/LCPupil_Joshi_Analysis/Code/Updated')));
    [base_dir, fnames] = getLCP_cleanDataDir(monkeys{mm}, 'LC');
    if ~isempty(fnames)
        fname = fnames{1};  % Test first file
        fprintf('Testing %s / %s\n', monkeys{mm}, fname);
        
        % Load the file
        full_path = fullfile(base_dir, fname);
        s = load(full_path);
        siteData = s.siteData;
        
        times = [-100 0; 0 800; -400 0; 0 200];
        
        % Find valid beep trials (same logic as legacy)
        Fbeep = find(siteData{1}(:,3)==1 & ...
            siteData{1}(:,4)>abs(min(times(:,1))) & ...
            siteData{1}(:,4)<size(siteData{2},2)-max(times(:,2)));
        num_single_units = max(0, size(siteData{3},2)-1);
        
        if ~isempty(Fbeep) && num_single_units > 0
            % Pick first unit
            uu = 1;
            fprintf('  File has %d beep trials, testing unit %d\n', length(Fbeep), uu);
            
            % Compute spike counts and baseline_times (legacy way)
            legacy_spike_counts = [];
            legacy_baseline_times = [];
            new_spike_counts = [];
            new_baseline_times = [];
            
            for bb = 1:min(5, length(Fbeep))  % just first 5 trials
                bt = Fbeep(bb);
                beep_time = siteData{1}(bt,4);
                sp = [];
                try
                    if iscell(siteData{3}) && size(siteData{3},1) >= bt && size(siteData{3},2) >= uu+1
                        sp = siteData{3}{bt, uu+1};
                    end
                catch
                end
                
                if ~isempty(sp)
                    % LEGACY: baseline = entire fix period up to beep
                    baseline_count = sum(sp >= 0 & sp < beep_time + times(3,2));
                    evoked_count = sum(sp >= beep_time + times(4,1) & sp <= beep_time + times(4,2));
                    
                    % LEGACY rates
                    legacy_baseline_rate = baseline_count / beep_time * 1000;
                    legacy_evoked_rate = evoked_count / diff(times(4,:)) * 1000;
                    
                    fprintf('    Trial %d: beep_time=%.1f ms, baseline_count=%d, baseline_rate=%.4f\n', ...
                        bb, beep_time, baseline_count, legacy_baseline_rate);
                    fprintf('             evoked_count=%d, evoked_rate=%.4f\n', ...
                        evoked_count, legacy_evoked_rate);
                    
                    legacy_spike_counts = [legacy_spike_counts; baseline_count, evoked_count];
                    legacy_baseline_times = [legacy_baseline_times; beep_time];
                end
            end
        end
        break;  % just test first monkey
    end
end
