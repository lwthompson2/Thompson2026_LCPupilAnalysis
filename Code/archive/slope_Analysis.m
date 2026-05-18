% Archived original: slope_Analysis.m
% This is a copy of the original `slope_Analysis.m` moved to the archive.
% If you need the original behavior, open this file in `Code/archive/`.

% (Original contents preserved here.)

% Script for getting & plotting 
%   LC & pupil baseline/evoked relationships
%   
% Data are "cleaned" versions of FIRA from Sidd's 2016 LC-pupil paper
%   created by cleanLCP_FIRA.m
%   The data are in cell arrays called "siteData", descrption
%   is at the bottom of this file

% Flag
collect_data = true;

% Collect data from both monkeys
monkeys = {'Oz' 'Cicero'};
num_monkeys = length(monkeys);

% time bins (all wrt beep onset)
times = [ ...
    -100    0;      % pupil baseline
    0       900;    % pupil evoked
    -500    0;      % spikes baseline
    0       200];   % spikes evoked

pupil_baseline_times = times(1,1):times(1,2);
pupil_evoked_times = times(2,1):times(2,2);
ith_unit = 0;
spike_rate_data = [];
do_zscore = true;

%% Plot Options
figure; hold on;
set(0, 'DefaultLineLineWidth', 2);

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
    LC_PD_data = [];

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
                    trial_times = [];
                    % spike baseline, evoked per trial per unit
                    spike_fix_data = nan(num_fix_trials, num_single_units);
                    spike_rate_fix_data = nan(num_fix_trials, num_single_units);
                    trial_fix_times = [];

                    
                    % Loop through the trials with beeps
                    for bb = 1:num_beep_trials

                        % Encode with respect to beep time
                        beep_time = siteData{1}(Fbeep(bb),4);
                        trial_times(bb) = beep_time;
                        % Get pupil data
                        bi = round(beep_time);
                        pd = siteData{2}(Fbeep(bb),:,5); % 4=val, 5=slope
                        baseline = mean(siteData{2}(Fbeep(bb),bi+pupil_baseline_times,4),'omitnan'); % actual value
                        evoked = mean(pd(bi+pupil_evoked_times),'omitnan'); % slope
                        % evoked = max(nanrunmean(pd(bi+pupil_evoked_times),50));
                        pupil_data(bb,:) = [baseline, evoked];
                        
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
                        trial_fix_times(bb) = start_time;
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
                        
                        % Relationships for each neuron
                        ith_unit = ith_unit + 1;
                        spike_rate_data(:,1,uu) = spike_data(:,1,uu)./ ...
                            diff(times(3,:)).*1000;
                        spike_rate_data(:,2,uu) = spike_data(:,2,uu)./ ...
                            diff(times(4,:)).*1000;

                        Lg = isfinite(spike_rate_data(:,1,uu)) & isfinite(pupil_data(:,1));
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
                        
                        LC_PD_data = cat(1, LC_PD_data, ...
                            [repmat([mm ff ith_unit],sum(Lg),1), ...
                            pupil_data(Lg,:) spike_rate_data(Lg,1:2,uu)]);

                        % For each session evoked vs baseline
                        % Fit a line vs a quadratic to see if there is a relationship

                        
                        all_trial_times = [trial_times(Lg), trial_fix_times(Lg_fix)];
                        all_baseline_FR = [squeeze(spike_rate_data(Lg,1,uu))', spike_rate_fix_data(Lg_fix,uu)'];
                        all_baseline_pd = [pupil_data(Lg,1)', pupil_fix_data(Lg_fix)'];
                        spike_drift = fitlm(all_trial_times,all_baseline_FR);
                        pupil_drift = fitlm(all_trial_times,all_baseline_pd);
                        baseline_P_alt(ith_unit) = corr(spike_drift.Residuals.Raw, pupil_drift.Residuals.Raw, 'type', 'Spearman');

                        raw_p_evoked = pupil_data(Lg,2)+pupil_data(Lg,1); % Add back baseline to evoked
                        corrected_p_evoked = raw_p_evoked - pupil_drift.Fitted(1:sum(Lg)); % Residual %raw_p_evoked + (trial_times(Lg)'.*pupil_drift.Coefficients.Estimate(2)); % Consider the slope associated with time drift
                        sub_p_evoked = pupil_data(Lg,2); %corrected_p_evoked - pupil_drift.Residuals.Raw; % Now relative to the residual of the baseline fit

                        raw_FR_evoked = spike_rate_data(Lg,2,uu) + spike_rate_data(Lg,1,uu); % Already subtracted, add back baseline
                        corrected_FR_evoked = raw_FR_evoked - spike_drift.Fitted(1:sum(Lg)); % Residual raw_FR_evoked + (trial_times(Lg)'.*spike_drift.Coefficients.Estimate(2)); % Consider the slope associated with time drift
                        sub_FR_evoked = raw_FR_evoked - spike_rate_data(Lg,1,uu); % Baseline subtraction

                        %% 1) Is baseline pupil related to baseline FR?
                        % rho = partialcorr(x,y,z) returns the sample linear partial correlation coefficients between pairs of variables in x and y, controlling for the variables in z.
                        % [base_p_base_FR(ith_unit), p(ith_unit)] = partialcorr(spike_rate_data(Lg,1,uu),pupil_data(Lg,1),[trial_times(Lg)]','Type','Spearman');
                        [base_p_base_FR(ith_unit), p(ith_unit)] = partialcorr(all_baseline_FR',all_baseline_pd', all_trial_times','Type','Spearman');
             
                        subplot(2,5,1);
                        plot(all_baseline_pd,spike_drift.Residuals.Raw,'o')
                        xlabel('Baseline Pupil Slope')
                        ylabel('Baseline FR (residuals)')
                        title('All Trials Baseline Drift')
                        axis square;

                        %% 2) Is baseline pupil related to evoked pupil?
                        Lg = isfinite(spike_rate_data(:,1,uu)) & isfinite(pupil_data(:,1));

                        %   a) raw evoked
                        base_p_evoked_p(ith_unit) = corr(pupil_drift.Residuals.Raw(1:sum(Lg)),corrected_p_evoked(1:sum(Lg)),'type','Spearman');
                        lm = fitlm(pupil_data(Lg,1),pupil_data(Lg,2), 'linear');
                        lm2 = fitlm(pupil_data(Lg,1),pupil_data(Lg,2), 'purequadratic');
                        subplot(2,5,2); hold off;
                        plot(lm); hold on;
                        h=plot(lm2); h(2).Color = 'g'; h(3).Color = 'g'; h(4).Color = 'g';
                        % plot(pupil_drift.Residuals.Raw,corrected_p_evoked,'o')
                        xlabel('Baseline Pupil Slope')
                        ylabel('Evoked Pupil Slope')
                        axis square;
                        legend off;

                        base_p_evoked_p(ith_unit) = corr(pupil_drift.Fitted(1:sum(Lg)),corrected_p_evoked,'type','Spearman');

                        % % We don't necessarily want to subtract 
                        % %   b) baseline subtracted evoked
                        % lm = fitlm(pupil_drift.Residuals.Raw(1:sum(Lg)),sub_p_evoked, 'linear');
                        % lm2 = fitlm(pupil_drift.Residuals.Raw(1:sum(Lg)),sub_p_evoked, 'purequadratic');
                        % subplot(2,5,3); hold off;
                        % plot(lm); hold on;
                        % h=plot(lm2); h(2).Color = 'g'; h(3).Color = 'g'; h(4).Color = 'g';
                        % % plot(pupil_drift.Residuals.Raw, sub_p_evoked,'o')
                        % xlabel('Baseline Pupil (residuals)')
                        % ylabel('Evoked Pupil: baselne subtracted')
                        % axis square;
                        % legend off;
                        % 
                        % base_p_subevoked_p(ith_unit) = corr(pupil_drift.Fitted(1:sum(Lg)),sub_p_evoked,'type','Spearman');
                        % 
                        % %% 3) Is baseline pupil related to evoked FR?
                        % %   a) raw evoked
                        % lm = fitlm(pupil_drift.Residuals.Raw(1:sum(Lg)),corrected_FR_evoked, 'linear');
                        % lm2 = fitlm(pupil_drift.Residuals.Raw(1:sum(Lg)),corrected_FR_evoked, 'purequadratic');
                        % subplot(2,5,4); hold off;
                        % plot(lm); hold on;
                        % h=plot(lm2); h(2).Color = 'g'; h(3).Color = 'g'; h(4).Color = 'g';
                        % % base_p_evoked_FR(ith_unit) = corr(pupil_drift.Fitted,corrected_FR_evoked,'type','Spearman');
                        % % subplot(2,5,5);
                        % % plot(pupil_drift.Residuals.Raw,corrected_FR_evoked,'o')
                        % xlabel('Baseline Pupil (residuals)')
                        % ylabel('Evoked FR (residuals)')
                        % axis square;
                        % legend off;
                        % 
                        % %   b) baseline subtracted evoked
                        % lm = fitlm(pupil_drift.Residuals.Raw(1:sum(Lg)),sub_FR_evoked, 'linear');
                        % lm2 = fitlm(pupil_drift.Residuals.Raw(1:sum(Lg)),sub_FR_evoked, 'purequadratic');
                        % subplot(2,5,5); hold off;
                        % plot(lm); hold on;
                        % h=plot(lm2); h(2).Color = 'g'; h(3).Color = 'g'; h(4).Color = 'g';
                        % base_p_subevoked_FR(ith_unit) = corr(pupil_drift.Fitted(1:sum(Lg)),sub_FR_evoked,'type','Spearman');
                        % % subplot(2,5,6);
                        % % plot(pupil_drift.Residuals.Raw,sub_FR_evoked,'o')
                        % xlabel('Baseline Pupil (residuals)')
                        % ylabel('Evoked FR: baselne subtracted')
                        % axis square;
                        % legend off;

                        %% 4) Is baseline FR related to evoked FR?
                        %   a) raw evoked
                        % lm = fitlm(spike_drift.Residuals.Raw(1:sum(Lg)),corrected_FR_evoked, 'linear');
                        % lm2 = fitlm(spike_drift.Residuals.Raw(1:sum(Lg)),corrected_FR_evoked, 'purequadratic');
                        % subplot(2,5,7); hold off;
                        % plot(lm); hold on;
                        % h=plot(lm2); h(2).Color = 'g'; h(3).Color = 'g'; h(4).Color = 'g';
                        % base_FR_evoked_FR(ith_unit) = corr(spike_drift.Fitted(1:sum(Lg)), corrected_FR_evoked,'type','Spearman');
                        % % subplot(2,5,7);
                        % % plot(spike_drift.Residuals.Raw,corrected_FR_evoked,'o')
                        % xlabel('Baseline FR (residuals)')
                        % ylabel('Evoked FR (residuals)')
                        % axis square;
                        % legend off;
                        % 
                        % %   b) baseline subtracted evoked
                        % lm = fitlm(spike_drift.Residuals.Raw(1:sum(Lg)),sub_FR_evoked, 'linear');
                        % lm2 = fitlm(spike_drift.Residuals.Raw(1:sum(Lg)),sub_FR_evoked, 'purequadratic');
                        % subplot(2,5,8); hold off;
                        % plot(lm); hold on;
                        % h=plot(lm2); h(2).Color = 'g'; h(3).Color = 'g'; h(4).Color = 'g';
                        % base_FR_subevoked_FR(ith_unit) = corr(spike_drift.Fitted(1:sum(Lg)), sub_FR_evoked,'type','Spearman');
                        % % subplot(2,5,8);
                        % % plot(spike_drift.Residuals.Raw,sub_FR_evoked,'o')
                        % xlabel('Baseline FR (residuals)')
                        % ylabel('Evoked FR: baselne subtracted')
                        % axis square;
                        % legend off;

                        %% 5) Is evoked pupil related to baseline FR?
                        %   a) raw evoked
                        lm = fitlm(spike_drift.Residuals.Raw(1:sum(Lg)), pupil_data(Lg,2), 'linear');
                        lm2 = fitlm(spike_drift.Residuals.Raw(1:sum(Lg)), pupil_data(Lg,2), 'purequadratic');
                        subplot(2,5,9); hold off;
                        plot(lm); hold on;
                        h=plot(lm2); h(2).Color = 'g'; h(3).Color = 'g'; h(4).Color = 'g';
                        evoked_p_base_FR(ith_unit) = corr(corrected_p_evoked, spike_drift.Fitted(1:sum(Lg)),'type','Spearman');
                        % subplot(2,5,9);
                        % plot(corrected_p_evoked,spike_drift.Residuals.Raw,'o')
                        ylabel('Evoked Pupil Slope')
                        xlabel('Baseline FR (residuals)')
                        axis square;
                        legend off;

                        % %   b) baseline subtracted evoked
                        % lm = fitlm(spike_drift.Residuals.Raw(1:sum(Lg)), sub_p_evoked,'linear');
                        % lm2 = fitlm(spike_drift.Residuals.Raw(1:sum(Lg)),sub_p_evoked, 'purequadratic');
                        % av = anova(lm2);
                        % subevoked_p_base_FR_lm2(ith_unit,:) = av.pValue(:,1);
                        % subplot(2,5,10); hold off;
                        % plot(lm); hold on;
                        % h=plot(lm2); h(2).Color = 'g'; h(3).Color = 'g'; h(4).Color = 'g';
                        % [subevoked_p_base_FR(ith_unit), subevoked_p_base_FR_pval(ith_unit)] = corr(sub_p_evoked, spike_drift.Residuals.Raw(1:sum(Lg)),'type','Spearman');
                        % % subplot(2,5,10);
                        % % plot(sub_p_evoked,spike_drift.Residuals.Raw,'o')
                        % ylabel('Evoked Pupil: baselne subtracted')
                        % xlabel('Baseline FR (residuals)')
                        % axis square;
                        % legend off;

                        %% 6) Is evoked pupil related to evoked FR?
                        %   a) raw evoked pupil vs baseline sub evoked FR
                        evoked_p_subevoked_FR(ith_unit) = corr(corrected_p_evoked, sub_FR_evoked,'type','Spearman');
                        %   b) raw evoked pupil vs raw evoked FR
                        evoked_p_voked_FR(ith_unit) = corr(corrected_p_evoked, corrected_FR_evoked,'type','Spearman');
                        %   c) baseline sub pupil vs baseline sub evoked FR
                        subevoked_p_subevoked_FR(ith_unit) = corr(sub_p_evoked, sub_FR_evoked,'type','Spearman');
                        %   d) baseline sub pupil vs raw evoked FR
                        subevoked_p_evoked_FR(ith_unit) = corr(sub_p_evoked, corrected_FR_evoked,'type','Spearman');

                        %% Save the figure?
                        % if p(ith_unit) <0.05
                            h=gcf;
                            set(h,'PaperOrientation','landscape');
                            set(h,'PaperUnits','normalized');
                            set(h,'PaperPosition', [0 0 1 1]);
                            if do_zscore
                                name = ['/Users/lowell/Library/Mobile Documents/com~apple~CloudDocs/UPenn Research/Code/LCPupil/Fits/Slope/Z_scored/',monkeys{mm},'/',extractBefore(fnames{ff},'.'),'_',num2str(ith_unit),'.pdf'];
                            else
                                name = ['/Users/lowell/Library/Mobile Documents/com~apple~CloudDocs/UPenn Research/Code/LCPupil/Fits/Slope/',monkeys{mm},'/',extractBefore(fnames{ff},'.'),'_',num2str(ith_unit),'.pdf'];
                            end
                            saveas(h,name)
                        % end
                    end
                end
            end
        end
    end

    % Convert spike counts to rates
    % LC_PD_data(:,6) = LC_PD_data(:,6)./ ...
    %     diff(times(3,:)).*1000;
    % LC_PD_data(:,7) = LC_PD_data(:,7)./ ...
    %     diff(times(4,:)).*1000;
    % LC_PD_data(:,7) = LC_PD_data(:,7) - LC_PD_data(:,6); % evoked rate - baseline rate 

    % save data to file
    % FS_saveProjectFile('2016_LCPupil', 'pdBeep', LC_PD_data);
else

    % load data from file
    % LC_PD_data = FS_loadProjectFile('2016_LCPupil', 'pdBeep');
end

%% Some plotz, separately per monk
% Are evoked pupil responses inversely related to baseline pupil? Yes
% Are evoked spikes inverselt related to baseline spikes? Yes
% Are evoked pupil responses inversely related to tonic LC activity?
figure; 
vars = {'monkey' 'session' 'unit', 'PD baseline' 'PD Evoked Slope' 'Spike baseline' 'Spike response'};
plots = [4 5; 6 7; 5 6];
num_plots = size(plots,1);
for mm = 1:num_monkeys

    % Each monk
    % Only significant baseline neurons
    Lm = LC_PD_data(:,1)==mm & ismember(LC_PD_data(:,3), find(p <0.05));
    % Each plot
    for pp = 1:num_plots
        subplot(num_plots,num_monkeys,(pp-1)*num_monkeys+mm); cla reset; hold on;
        xs = LC_PD_data(Lm, plots(pp,1));
        ys = LC_PD_data(Lm, plots(pp,2));
        Lg = isfinite(xs) & isfinite(ys);
        lm2 = fitlm(xs(Lg), ys(Lg), 'purequadratic');
        plot(xs, ys, 'k.'); hold on;
        [R,P] = corr(xs(Lg), ys(Lg), 'type', 'Spearman');
        title(sprintf('R=%.3f, P=%.3f', R, P))
        lsline;
        plot(lm2);
        set(gca, 'FontSize', 12);
end
% Archived: slope_Analysis.m
% Original exploratory slope analysis script moved to archive.

% (File archived — original content retained in commit history)
