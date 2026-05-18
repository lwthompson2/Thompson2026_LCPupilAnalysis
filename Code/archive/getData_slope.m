% Archived copy of getData_slope (migrated from Code/Updated)
% This file is archived and should not be used for manuscript figure generation.
% Original content preserved for record.

% (archived content removed for brevity)

% See Code/Updated/getData.m for the primary data-generation script.
% Script for getting & plotting 
%   LC & pupil baseline/evoked relationships
%   (archived copy: original exploratory slope variant)
%   The data are in cell arrays called "siteData", descrption
%   is at the bottom of this file

clear all
% close all

% Flag
collect_data = true;
save_figs = false;
do_zscore = false;

% Collect data from both monkeys
monkeys = {'Oz' 'Cicero'};
num_monkeys = length(monkeys);

pup_pup_folders = {'None','Positive','Negative'};

% time bins (all wrt beep onset)
times = [ ...
	-100    0;      % pupil basel10ine
	0       900;    % pupil evoked
	-500    0;      % spikes baseline
	0       200];   % spikes evoked

pupil_baseline_times = times(1,1):times(1,2);
pupil_evoked_times = times(2,1):times(2,2);
ith_unit = 0;
spike_rate_data = [];

%% Plot Options
set(0, 'DefaultFigureRenderer', 'painters');
set(0, 'DefaultLineLineWidth', 2);
figure; hold on;

%% Possibly get data
if collect_data

	% Set up data matrix
	%   rows are trials, columns are:
	%   monkey
	%   session index
	%   pupil baseline
	%   pupil evoked
	%   spike baseline
	%   spike evoked
	LC_Beep_data = [];
	LC_Fix_data = [];

	% For each monkey
	for mm = 1:num_monkeys

		% load file
		[base_dir, fnames] = getLCP_cleanDataDir(monkeys{mm}, 'LC');
		if ~isempty(fnames)

			% Loop through the data files
			for ff = 1:length(fnames)
				disp(sprintf('monkey = %s, %d/%d files', ...
					monkeys{mm}, ff, length(fnames)))
				load(fullfile(base_dir, fnames{ff}));
				unique_session = 1;
                
				%  siteData{1}: trialsxcols matrix, cols are:
				%   1 ... fix start time wrt fixation on
				%   2 ... fix end time wrt fix start time (fix duration)
				%   3 ... reported correct
				%   4 ... beep on time (when appropriate), wrt to fix start time
				%   5 ... trial begin time, wrt to fix start time
				%   6 ... trial end time, wrt to fix start time
				%   7 ... trial wrt time (cpu clock)
				%   8 ... LFP index corresponding to fix start time (coded above)
				%   9 ... ELESTM on time (when appropriate), wrt fix start time

				% "Evoked" response is from correct beep trials, single-units only
				Fbeep = find(siteData{1}(:,3)==1 & ...
					siteData{1}(:,4)>abs(min(times(:,1))) & ... % beep times greater than min before times (sufficient time before beep)
					siteData{1}(:,4)<size(siteData{2},2)-max(times(:,2))); 
				Ffix = find(siteData{1}(:,3)==1 & ... % correct
					isnan(siteData{1}(:,4)) & ... % not a beep trial
					isnan(siteData{1}(:,9))); % not a stim trial
				num_single_units = size(siteData{3}, 2)-1;

				if ~isempty(Fbeep) && ~isempty(Ffix) && num_single_units > 0
                    
					num_beep_trials = size(Fbeep,1);
					num_fix_trials = size(Ffix,1);
					num_pupil_samples = size(siteData{2},2);

					% pupil baseline, evoked per trial
					pupil_data = nan.*zeros(num_beep_trials, 2);
					pupil_fix_data = nan.*zeros(num_fix_trials, 1);

					% spike baseline, evoked per trial per unit
					spike_data = nan(num_beep_trials, 2, num_single_units);
					spike_rate_data = nan(num_beep_trials, 2, num_single_units);
					fix_start_times = nan(num_beep_trials, 1);
					trial_times = [];
					% spike baseline, evoked per trial per unit
					spike_fix_data = nan(num_fix_trials, num_single_units);
					spike_rate_fix_data = nan(num_fix_trials, num_single_units);
					trial_fix_times = [];

                    
					% Loop through the trials with beeps
					for bb = 1:num_beep_trials

						% Encode with respect to beep time
						beep_time = siteData{1}(Fbeep(bb),4);
						trial_times(bb) = siteData{1}(Fbeep(bb),7);
						% Get pupil data
						bi = round(beep_time);
						pd = siteData{2}(Fbeep(bb),:,4); % 4=val, 5=slope
						baseline = mean(pd(bi+pupil_baseline_times),'omitnan');
						pd = siteData{2}(Fbeep(bb),:,5); % 4=val, 5=slope
						% evoked = nanmean(nanrunmean(pd(bi+pupil_evoked_times),50));
						evoked_mm = [nanmin(pd(bi+pupil_evoked_times)),...
							nanmax(pd(bi+pupil_evoked_times))];
						[~,evoked_i] = max(abs(evoked_mm));
						evoked = evoked_mm(evoked_i);
						pupil_data(bb,:) = [baseline, evoked];
						fix_start_times(bb) = siteData{1}(Fbeep(bb),1);

						% Get spike data per unit
						for uu = 1:num_single_units
							sp = siteData{3}{Fbeep(bb), uu+1};
							baseline = sum(sp>=beep_time+times(3,1) & ...
							   sp<=beep_time+times(3,2));
							evoked = sum(sp>=beep_time+times(4,1) & ...
							   sp<=beep_time+times(4,2));
							spike_data(bb,:,uu) = [baseline, evoked];
                            
						end
					end

					% Loop through the trials without beeps
					for bb = 1:num_fix_trials

						% Encode with respect to fix on time
						start_time = siteData{1}(Ffix(bb),1);
						end_time = siteData{1}(Ffix(bb),2);
						fix_times = 0:(end_time - start_time);
						trial_fix_times(bb) = siteData{1}(Ffix(bb),7);
						% Get pupil data
						bi = round(start_time);
						pd = siteData{2}(Ffix(bb),:,4); % 4=val, 5=slope
						baseline = mean(pd(bi+fix_times),'omitnan');
						pupil_fix_data(bb,:) = baseline;
						% Get spike data per unit
						for uu = 1:num_single_units
							sp = siteData{3}{Ffix(bb), uu+1};
							baseline = sum(sp>=start_time & ...
								sp<=end_time);
							spike_fix_data(bb,uu) = baseline;
							spike_rate_fix_data(bb,uu) = baseline./(end_time-start_time).*1000;
						end
					end

					% Save each unit alongside a copy of the pupil data
					% possibly z-score units
					for uu = 1:num_single_units
						if uu >1
							unique_session = 0;
						end
                        
						% Relationships for each neuron
						ith_unit = ith_unit + 1;
						session_numbers_unique(ith_unit) = unique_session;
						spike_rate_data(:,1,uu) = spike_data(:,1,uu)./ ...
							diff(times(3,:)).*1000;
						spike_rate_data(:,2,uu) = spike_data(:,2,uu)./ ...
							diff(times(4,:)).*1000;
                        
						Lg = isfinite(spike_rate_data(:,1,uu)) & isfinite(pupil_data(:,1)) & isfinite(pupil_data(:,2)) & abs(zscore(spike_rate_data(:,2,uu)))<8;
						Lg_fix = isfinite(spike_rate_fix_data(:,uu)) & isfinite(pupil_fix_data);
						if do_zscore
							% Get all the firing rate data including evoked
							all_FR = [squeeze(spike_rate_data(Lg,1,uu))', squeeze(spike_rate_data(Lg,2,uu))', spike_rate_fix_data(Lg_fix,uu)'];
							all_zFR = zscore(all_FR);
							spike_rate_data(Lg,1,uu) = all_zFR(1:sum(Lg));
							spike_rate_data(Lg,2,uu) = all_zFR(sum(Lg)+(1:sum(Lg)));
							spike_rate_fix_data(Lg_fix,uu) = all_zFR((2*sum(Lg))+1:end);
						end
                        
						spike_rate_data(:,2,uu) = spike_rate_data(:,2,uu) - spike_rate_data(:,1,uu); % evoked - baseline
						session_numbers(ith_unit) = ff; % pupil vs pupil data need to know which units belong to the same session
						monkey_numbers(ith_unit) = mm;
                        
						% Calculate a global drift over time and extract
						% residuals
						all_trial_times = [trial_times(Lg), trial_fix_times(Lg_fix)];
						all_baseline_pd = [pupil_data(Lg,1)', pupil_fix_data(Lg_fix,:)'];
						all_baseline_FR = [squeeze(spike_rate_data(Lg,1,uu))', squeeze(spike_rate_fix_data(Lg_fix,uu))'];
						spike_drift = fitlm(all_trial_times,all_baseline_FR);
						pupil_drift = fitlm(all_trial_times,all_baseline_pd);
                        
						% Beep trials only for simplified data
						LC_Beep_data = cat(1, LC_Beep_data, ...
							[repmat([mm unique_session ith_unit],sum(Lg),1), ...
							pupil_data(Lg,:) squeeze(spike_rate_data(Lg,1,uu)) squeeze(spike_rate_data(Lg,2,uu)) trial_times(Lg)'...
							pupil_drift.Residuals.Raw(1:sum(Lg)) spike_drift.Residuals.Raw(1:sum(Lg))]);
						LC_Beep_labels = {'monkey_id','session_id', 'unit_id', 'pupil_baseline', 'pupil_bs_evoked',...
							'spike_baseline', 'spike_bs_evoked', 'fix_global_start_time',...
							'pupil_drift_residuals', 'spike_drift_residuals'};

						% Fix trials only for simplified data
						LC_Fix_data = cat(1, LC_Fix_data, ...
							[repmat([mm unique_session ith_unit],sum(Lg_fix),1), ...
							pupil_fix_data(Lg_fix,:) squeeze(spike_rate_fix_data(Lg_fix,uu)) trial_fix_times(Lg_fix)'...
							pupil_drift.Residuals.Raw(sum(Lg)+1:end) spike_drift.Residuals.Raw(sum(Lg)+1:end)]);
						LC_Fix_labels = {'monkey_id','session_id', 'unit_id', 'pupil_baseline',...
							'spike_baseline', 'fix_global_start_time',...
							'pupil_drift_residuals', 'spike_drift_residuals'};


					end
				end
			end
		end
	end

	% save data to file
	% FS_saveProjectFile('2016_LCPupil', 'pdBeep', LC_PD_data);
else

	% load data from file
	% LC_PD_data = FS_loadProjectFile('2016_LCPupil', 'pdBeep');
end
stats = struct2table(stats);

%% Original cleaning script notes:

% Cleans up and saves siteData (in file "clean_name"):
%  siteData{1}: trialsxcols matrix, cols are:
%   1 ... fix start time wrt fixation on
%   2 ... fix end time wrt fix start time (fix duration)
%   3 ... reported correct
%   4 ... beep on time (when appropriate), wrt to fix start time
%   5 ... trial begin time, wrt to fix start time
%   6 ... trial end time, wrt to fix start time
%   7 ... trial wrt time (cpu clock)
%   8 ... LFP index corresponding to fix start time (coded above)
%   9 ... ELESTM on time (when appropriate), wrt fix start time
%
%  siteData{2}: Analog:
%   dim1: trial
%   dim2: sample
%   dim3: 1 = x, 2 = y, 3 = z-pupil, 4 = corrected z-pupil, 5 = pupil slope
%   [remember first sample is considered time=0 (i.e., wrt fix start time)]
%     = eyedat(Lgood,:,:);
%
%  siteData{3}: spikes, re-coded wrt fix start time
%
%  siteData{4}: LFP
%
%  siteData{5}: pupil events
%   1. trial number
%   2. start time of event (wrt fix start time)
%   3. end time of event (wrt fix start time)
%   4. magnitude at start of event (raw z-score)
%   5. magnitude at end of event (raw z-score)
%   6. magnitude at start of event (corrected z-score)
%   7. magnitude at end of event (corrected z-score)
%   8. time of subsequent max slope
%   9. magnitude of subsequent max slope (corrected z/sample)
%
%  siteData{6}: microsaccades
%   1. trial number
%   2. start time of event (wrt fix start time)
%   3. duration of event (wrt fix start time)
%   4. maximum velocity (deg/ms)
%   5. magnitude of microsaccade event (deg)
%   6. onset time wrt phase of associated pupil event (fraction)
%   7. magnitude of associated pupil event
%
%  siteData{7}: spike/LFP channels
%   1. spike channels
%   2. LFP names

