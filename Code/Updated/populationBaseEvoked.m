%% Generates a population summary plot for Joshi 2016 data
% Created by LWT 9/24/2024
% FIRST USE getData and set do_zscore to true!!!

% 1) Is baseline pupil related to baseline FR?
% 2) Is baseline pupil related to evoked pupil?
% 3) Is baseline FR related to evoked FR?
% 4) Is baseline pupil related to evoked FR?
% 5) Is evoked pupil related to baseline FR?
plots = [9 10;... % baseline pupil, baseline FR
    9 5;... % baseline pupil, evoked pupil: Are evoked pupil responses inversely related to baseline pupil? Yes
    10 7;... % baseline FR, evoked FR: Are evoked spikes inversely related to baseline spikes?
    5 7;... % evoked pupil, evoked FR
    9 7;... % baseline pupil, evoked FR: Are evoked spikes inversely related to baseline pupil?
    5 10]; % evoked pupil, baseline FR: Are evoked pupil responses inversely related to tonic LC activity?

% plots = [9 10;... % baseline pupil, baseline FR
%     4 5;... % baseline pupil, evoked pupil: Are evoked pupil responses inversely related to baseline pupil? Yes
%     10 7;... % baseline FR, evoked FR: Are evoked spikes inversely related to baseline spikes?
%     4 7;... % baseline pupil, evoked FR: Are evoked spikes inversely related to baseline pupil?
%     5 10]; % evoked pupil, baseline FR: Are evoked pupil responses inversely related to tonic LC activity?

num_plots = size(plots,1);
figure; 
vars = {'monkey_id','session_id', 'unit_id', 'Baseline Pupil (z-scored)', 'Evoked Pupil',...
                            'Baseline FR (z-scored)', 'Evoked FR', 'fix_global_start_time',...
                            'Baseline Pupil (residuals)','Baseline FR (residuals)'}; %{'monkey' 'session' 'unit', 'PD baseline' 'PD response' 'Spike baseline' 'Spike response'};
lin_mod_pos = {dictionary(), dictionary()};
lin_mod_neg = {dictionary(), dictionary()};

for mm = 1:num_monkeys

    % Each monk
    Lm = LC_Beep_data(:,1)==mm; % trials matching this monkey
    Lm_sig_pos = LC_Beep_data(:,1)==mm & ismember(LC_Beep_data(:,3), find(stats.p<0.05)) & ismember(LC_Beep_data(:,3), find(stats.base_p_base_FR>0)); % trials matching this monkey
    Lm_sig_neg = LC_Beep_data(:,1)==mm & ismember(LC_Beep_data(:,3), find(stats.p<0.05)) & ismember(LC_Beep_data(:,3), find(stats.base_p_base_FR<0)); % trials matching this monkey
    LmFix = LC_Fix_data(:,1)==mm; % trials matching this monkey
    

    % Each plot
    for pp = 1:num_plots
        subplot(num_monkeys,num_plots,sub2ind([num_plots,num_monkeys],pp,mm)); hold on;
        if pp == 1
            % xs = [LC_Beep_data(Lm & LC_Beep_data(:,2), plots(pp,1)); LC_Fix_data(LmFix & LC_Fix_data(:,2), 7)];
            % ys = [LC_Beep_data(Lm & LC_Beep_data(:,2), plots(pp,2)); LC_Fix_data(LmFix & LC_Fix_data(:,2), 8)];
            % Update to use the table which should be more straight forward
            xs = [LC_Beep_table.pupil_drift_residuals(LC_Beep_table.monkey_id == mm); LC_Fix_table.pupil_drift_residuals(LC_Fix_table.monkey_id == mm)];
            ys = [LC_Beep_table.spike_drift_residuals(LC_Beep_table.monkey_id == mm); LC_Fix_table.spike_drift_residuals(LC_Fix_table.monkey_id == mm)];
            xs_sig_pos = [LC_Beep_table.pupil_drift_residuals(LC_Beep_table.monkey_id == mm & ismember(LC_Beep_table.unit_id, stats.unit_id(stats.p<0.05 & stats.base_p_base_FR>0)));...
                LC_Fix_table.pupil_drift_residuals(LC_Fix_table.monkey_id == mm & ismember(LC_Fix_table.unit_id, stats.unit_id(stats.p<0.05 & stats.base_p_base_FR>0)))];
            ys_sig_pos = [LC_Beep_table.spike_drift_residuals(LC_Beep_table.monkey_id == mm & ismember(LC_Beep_table.unit_id, stats.unit_id(stats.p<0.05 & stats.base_p_base_FR>0)));...
                LC_Fix_table.spike_drift_residuals(LC_Fix_table.monkey_id == mm & ismember(LC_Fix_table.unit_id, stats.unit_id(stats.p<0.05 & stats.base_p_base_FR>0)))];
            xs_sig_neg = [LC_Beep_table.pupil_drift_residuals(LC_Beep_table.monkey_id == mm & ismember(LC_Beep_table.unit_id, stats.unit_id(stats.p<0.05 & stats.base_p_base_FR<0)));...
                LC_Fix_table.pupil_drift_residuals(LC_Fix_table.monkey_id == mm & ismember(LC_Fix_table.unit_id, stats.unit_id(stats.p<0.05 & stats.base_p_base_FR<0)))];
            ys_sig_neg = [LC_Beep_table.spike_drift_residuals(LC_Beep_table.monkey_id == mm & ismember(LC_Beep_table.unit_id, stats.unit_id(stats.p<0.05 & stats.base_p_base_FR<0)));...
                LC_Fix_table.spike_drift_residuals(LC_Fix_table.monkey_id == mm & ismember(LC_Fix_table.unit_id, stats.unit_id(stats.p<0.05 & stats.base_p_base_FR<0)))];
        elseif pp == 2
            % For pupil only data we need to select sessions rather than all units
            xs = LC_Beep_data(Lm & LC_Beep_data(:,2), plots(pp,1));
            ys = LC_Beep_data(Lm & LC_Beep_data(:,2), plots(pp,2));
        else
            % all regardless of sig pos and neg
            xs = LC_Beep_data(Lm, plots(pp,1));
            ys = LC_Beep_data(Lm, plots(pp,2));
            % Non significant only
            % xs = LC_Beep_data(~Lm_sig_pos & ~Lm_sig_neg & Lm, plots(pp,1));
            % ys = LC_Beep_data(~Lm_sig_pos & ~Lm_sig_neg & Lm, plots(pp,2));
            xs_sig_pos = LC_Beep_data(Lm_sig_pos, plots(pp,1));
            ys_sig_pos = LC_Beep_data(Lm_sig_pos, plots(pp,2));
            xs_sig_neg = LC_Beep_data(Lm_sig_neg, plots(pp,1));
            ys_sig_neg = LC_Beep_data(Lm_sig_neg, plots(pp,2));
        end
        
        if mm == 1
            scatter(xs, ys, 60, 'o','MarkerFaceColor',[0.5 0.5 0.5], 'MarkerEdgeColor','k','MarkerFaceAlpha',0.2);
            if pp ~= 2
                lin_mod_pos{mm}(strcat(vars{plots(pp,1)},vars{plots(pp,2)})) = fitlm(xs_sig_pos,ys_sig_pos);
                lin_mod_neg{mm}(strcat(vars{plots(pp,1)},vars{plots(pp,2)})) = fitlm(xs_sig_neg,ys_sig_neg);
                scatter(xs_sig_pos, ys_sig_pos, 60, 'o','MarkerFaceColor',[22 153 81]./255, 'MarkerEdgeColor','k','MarkerFaceAlpha',1);
                scatter(xs_sig_neg, ys_sig_neg, 60, 'o','MarkerFaceColor',[242 121 0]./255, 'MarkerEdgeColor','k','MarkerFaceAlpha',1);
            end
        else
            scatter(xs, ys, 60, 'd','MarkerFaceColor',[0.5 0.5 0.5], 'MarkerEdgeColor','k','MarkerFaceAlpha',0.3);
            if pp ~= 2
                lin_mod_pos{mm}(strcat(vars{plots(pp,1)},vars{plots(pp,2)})) = fitlm(xs_sig_pos,ys_sig_pos);
                lin_mod_neg{mm}(strcat(vars{plots(pp,1)},vars{plots(pp,2)})) = fitlm(xs_sig_neg,ys_sig_neg);
                scatter(xs_sig_pos, ys_sig_pos, 60, 'd','MarkerFaceColor',[22 153 81]./255, 'MarkerEdgeColor','k','MarkerFaceAlpha',1);
                scatter(xs_sig_neg, ys_sig_neg, 60, 'd','MarkerFaceColor',[242 121 0]./255, 'MarkerEdgeColor','k','MarkerFaceAlpha',1);
            end
        end
        set(gca, 'FontSize', 12);
        xlabel(vars{plots(pp,1)});
        ylabel(vars{plots(pp,2)});
        Lg = isfinite(xs) & isfinite(ys);
        [R_all{mm,pp},P_all{mm,pp}] = corr(xs(Lg), ys(Lg), 'type', 'Spearman');
        Lg = isfinite(xs_sig_pos) & isfinite(ys_sig_pos);
        [R_pos{mm,pp},P_pos{mm,pp}] = corr(xs_sig_pos(Lg), ys_sig_pos(Lg), 'type', 'Spearman');
        Lg = isfinite(xs_sig_neg) & isfinite(ys_sig_neg);
        [R_neg{mm,pp},P_neg{mm,pp}] = corr(xs_sig_neg(Lg), ys_sig_neg(Lg), 'type', 'Spearman');
        % title({sprintf('R=%.3f, P=%.3f', R_all{mm}, P_all{mm})})
        h = lsline;
        if pp ~= 2
            h(1).Color = [242 121 0]./255; % neg
            h(2).Color = [22 153 81]./255; % positive
        end
        axis square;
        box on;
    end
end
f = gcf; f.Position = [58, 360, 1406, 420];