%% Generates a unit summary plot for Joshi 2016 example data
% Created by LWT 9/24/2024
% Requires getData.m to be run

% mm, ff, unit_num
% example_neurons = [1, 18, 24;...
%     1, 19, 25;...
%     2, 5, 48;...
%     2, 16, 60;...
%     2, 27, 69];

example_neurons = [1, 18, 10;...
    1, 19, 25;...
    2, 5, 60;...
    2, 27, 97];

f = figure; f.Units = 'inches'; f.Position = [9.4167 0 11.5833 12.0139];
t = tiledlayout(6,size(example_neurons,1)+1,'TileSpacing','tight','Padding','tight');
n_rows = 6;

%% Loop through examples
for ex = 1:size(example_neurons,1)  % each neuron
    for row = 1:6   % each comparison
        if ex == 5
            continue
        end
        tile_index = (row - 1) * 5 + ex;

        temp_stats = [];
        temp_beep_data = LC_Beep_data(LC_Beep_data(:,3)==example_neurons(ex,3),:);
        temp_fix_data = LC_Fix_data(LC_Fix_data(:,3)==example_neurons(ex,3),:);

        all_trial_times = [temp_beep_data(:,8)', temp_fix_data(:,6)'];
        all_baseline_pd = [temp_beep_data(:,4)', temp_fix_data(:,4)'];
        all_baseline_FR = [temp_beep_data(:,6)', temp_fix_data(:,5)'];
        spike_drift = fitlm(all_trial_times,all_baseline_FR);
        pupil_drift = fitlm(all_trial_times,all_baseline_pd);
        temp_stats.spike_drift_slope = spike_drift.Coefficients.Estimate(2);
        temp_stats.pupil_drift_slope = pupil_drift.Coefficients.Estimate(2);
        temp_stats.baseline_P_alt = corr(spike_drift.Residuals.Raw, pupil_drift.Residuals.Raw, 'type', 'Spearman');

        raw_p_evoked = temp_beep_data(:,4)+temp_beep_data(:,5); % Add back baseline to evoked
        corrected_p_evoked = raw_p_evoked - pupil_drift.Fitted(1:size(temp_beep_data,1)); % Residual %raw_p_evoked + (trial_times(Lg)'.*pupil_drift.Coefficients.Estimate(2)); % Consider the slope associated with time drift
        sub_p_evoked = temp_beep_data(:,5);

        raw_FR_evoked = temp_beep_data(:,6)+temp_beep_data(:,7); % Already subtracted, add back baseline
        corrected_FR_evoked = raw_FR_evoked - spike_drift.Fitted(1:size(temp_beep_data,1)); % Residual raw_FR_evoked + (trial_times(Lg)'.*spike_drift.Coefficients.Estimate(2)); % Consider the slope associated with time drift
        sub_FR_evoked = temp_beep_data(:,7); % Baseline subtraction

        % Create a table for using linear models
        lm_table = table(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)), spike_drift.Residuals.Raw(1:size(temp_beep_data,1)), sub_p_evoked, sub_FR_evoked, raw_p_evoked, raw_FR_evoked,...
            'VariableNames',{'pupil_base', 'spike_base', 'pupil_evoked', 'spike_evoked', 'pupil_evoked_raw', 'spike_evoked_raw'});

        if row == 1
            %% 1) Is baseline pupil related to baseline FR?
            % rho = partialcorr(x,y,z) returns the sample linear partial correlation coefficients between pairs of variables in x and y, controlling for the variables in z.
            % [base_p_base_FR(ith_unit), p(ith_unit)] = partialcorr(spike_rate_data(Lg,1,uu),pupil_data(Lg,1),[trial_times(Lg)]','Type','Spearman');
            [temp_stats.base_p_base_FR, temp_stats.p] = partialcorr(all_baseline_FR',all_baseline_pd', all_trial_times','Type','Spearman');

            nexttile(tile_index); hold off;
            % subplot(6,size(example_neurons,1),ex); hold off;
            plot(pupil_drift.Residuals.Raw,spike_drift.Residuals.Raw,'ok','MarkerFaceColor',[0.5 0.5 0.5])
            lm = fitlm(pupil_drift.Residuals.Raw, spike_drift.Residuals.Raw);
            h=plot(lm); hold on;
            h(1).Marker = 'o'; h(1).MarkerFaceColor = [0.5 0.5 0.5]; h(1).MarkerEdgeColor = 'k'; h(1).LineWidth = 1;
            h(2).Color = 'k';
            h(3).Color = 'k';
            h(4).Color = 'k';
            if ex == 3
                xlabel({'Baseline Pupil (residuals)'})
            else
                xlabel('');
            end
            if ex == 1
                ylabel({'Baseline FR', '(residuals)'})
            else
                ylabel('');
            end
            pbaspect([1 1 1]);
            legend off;
            title('');
            ax = gca;
            dim = [0.2 0.5 0.3 0.3];
            str = {['rho = ' num2str(temp_stats.base_p_base_FR)],...
                ['p = ', num2str(temp_stats.p)]};
            annotation('textbox','Position',ax.Position,'String',str,'FitBoxToText','on','LineStyle','none');
        end

        %% 2) Is baseline pupil related to evoked pupil?
        if row == 2
            % Spearman using residuals across all trials?
            % [temp_stats.base_p_subevoked_p_R, temp_stats.base_p_subevoked_p] = corr(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_p_evoked,'type','Spearman');
            
            % Or partial only including drifts related to these trials
            [temp_stats.base_p_subevoked_p_R, temp_stats.base_p_subevoked_p] = partialcorr(all_baseline_pd(1:size(temp_beep_data,1))',sub_p_evoked, all_trial_times(1:size(temp_beep_data,1))', 'type','Spearman');

            % We don't necessarily want to subtract
            %   b) baseline subtracted evoked
            lme = fitlme(lm_table,'pupil_evoked ~ pupil_base');
            lm = fitlm(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_p_evoked, 'linear');
            lme2 = fitlme(lm_table,'pupil_evoked ~ pupil_base*pupil_base');
            results = compare(lme,lme2);
            temp_stats.pEvoked_v_pBase = results.pValue(2);
            temp_stats.pEvoked_v_pBase_LLR = results.LogLik(1)./results.LogLik(2);
            lm2 = fitlm(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_p_evoked, 'purequadratic');

            % subplot(6,size(example_neurons,1),ex + size(example_neurons,1)); hold off;
            nexttile(tile_index); hold off;
            h=plot(lm); hold on;
            % h(1).Marker = 'none';
            h(2).Color = [0 174 239]./255;
            h(3).Color = [0 174 239]./255;
            h(4).Color = [0 174 239]./255;

            % h=plot(lm2);
            h(1).Marker = 'o'; h(1).MarkerFaceColor = [0 174 239]./255; h(1).MarkerEdgeColor = 'k'; h(1).LineWidth = 1;
            % h(2).Color = 'g';
            % h(3).Color = 'g';
            % h(4).Color = 'g';
            % plot(pupil_drift.Residuals.Raw, sub_p_evoked,'o')
            if ex == 3
                xlabel('Baseline Pupil (residuals)')
            else
                xlabel('');
            end
            if ex == 1
                ylabel({'Evoked Pupil', '(baselne subtracted)'})
            else
                ylabel('');
            end
            pbaspect([1 1 1]);
            l = legend('Location','Southeast');
            pos = l.Position;
            legend off;
            title('');
            ax = gca;
            % [stats.base_p_subevoked_p_R, stats.base_p_subevoked_p]
            rho_val = stats.base_p_subevoked_p_R(stats.unit_id == example_neurons(ex,3));
            p_val = stats.base_p_subevoked_p(stats.unit_id == example_neurons(ex,3));
            str = {['rho = ' num2str(rho_val)],...
                ['p = ', num2str(p_val)]};
            annotation('textbox','Position',pos,'String',str,'FitBoxToText','on','LineStyle','none');
        end

        %% 3) Is baseline FR related to evoked FR?
        %   b) baseline subtracted evoked
        if row == 3
            lm = fitlm(spike_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_FR_evoked, 'linear');
            lm2 = fitlm(spike_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_FR_evoked, 'purequadratic');
            if sum(lm_table.spike_base)>0
                lme = fitlme(lm_table,'spike_evoked ~ spike_base');
                lme2 = fitlme(lm_table,'spike_evoked ~ spike_base*spike_base');
                results = compare(lme,lme2);
                temp_stats.sEvoked_v_sBase = results.pValue(2);
                temp_stats.sEvoked_v_sBase_LLR = results.LogLik(1)./results.LogLik(2);
            else
                temp_stats.sEvoked_v_sBase = NaN;
                temp_stats.sEvoked_v_sBase_LLR = NaN;
            end
            % subplot(6,size(example_neurons,1),ex + 2*size(example_neurons,1));
            nexttile(tile_index);
            hold off;
            h=plot(lm); hold on;
            % h(1).Marker = 'none';
            h(2).Color = 'r';
            h(3).Color = 'r';
            h(4).Color = 'r';

            % h=plot(lm2);
            h(1).Marker = 'o'; h(1).MarkerFaceColor = 'r'; h(1).MarkerEdgeColor = 'k'; h(1).LineWidth = 1;
            % h(2).Color = 'g';
            % h(3).Color = 'g';
            % h(4).Color = 'g';
            % Using all trials for drift residuals
            % [temp_stats.base_FR_subevoked_FR_R, temp_stats.base_FR_subevoked_FR] = corr(spike_drift.Residuals.Raw(1:size(temp_beep_data,1)), sub_FR_evoked,'type','Spearman');
            
            % Or partial only including drifts related to these trials
            [temp_stats.base_FR_subevoked_FR_R, temp_stats.base_FR_subevoked_FR] = partialcorr(all_baseline_FR(1:size(temp_beep_data,1))',sub_FR_evoked, all_trial_times(1:size(temp_beep_data,1))', 'type','Spearman');

            if ex == 3
                xlabel('Baseline FR (residuals)')
            else
                xlabel('');
            end
            if ex == 1
                ylabel({'Evoked FR', '(baselne subtracted)'})
            else
                ylabel('');
            end
            pbaspect([1 1 1]);
            l = legend('Location','Southeast');
            pos = l.Position;
            legend off;
            title('');
            % [stats.base_FR_subevoked_FR_R, stats.base_FR_subevoked_FR]
            ax = gca;
            rho_val = stats.base_FR_subevoked_FR_R(stats.unit_id == example_neurons(ex,3));
            p_val = stats.base_FR_subevoked_FR(stats.unit_id == example_neurons(ex,3));
            str = {['rho = ' num2str(rho_val)],...
                ['p = ', num2str(p_val)]};
            annotation('textbox','Position',pos,'String',str,'FitBoxToText','on','LineStyle','none');
        end
        %% 4) Is evoked pupil related to evoked FR?
        % subplot(6,size(example_neurons,1),ex + 3*size(example_neurons,1)); hold off;
        if row == 4
            nexttile(tile_index); hold off;
            plot(sub_p_evoked,sub_FR_evoked,'ok','MarkerFaceColor',[0.5 0.5 0.5])
            lm = fitlm(sub_p_evoked, sub_FR_evoked);
            h=plot(lm); hold on;
            h(1).Marker = 'o'; h(1).MarkerFaceColor = [0.5 0.5 0.5]; h(1).MarkerEdgeColor = 'k'; h(1).LineWidth = 1;
            h(2).Color = 'k';
            h(3).Color = 'k';
            h(4).Color = 'k';
            if ex == 3
                xlabel({'Evoked Pupil (baseline subtracted)'})
            else
                xlabel('');
            end
            if ex==1
                ylabel({'Evoked FR', '(baseline subtracted)'})
            else
                ylabel('');
            end
            pbaspect([1 1 1]);
            l = legend('Location','northwest');
            pos = l.Position;
            legend off;
            title('');
            % [stats.bs_evoked_r, stats.bs_evoked_p]
            ax = gca;
            rho_val = stats.bs_evoked_r(stats.unit_id == example_neurons(ex,3));
            p_val = stats.bs_evoked_p(stats.unit_id == example_neurons(ex,3));
            str = {['rho = ' num2str(rho_val)],...
                ['p = ', num2str(p_val)]};
            annotation('textbox','Position',pos,'String',str,'FitBoxToText','on','LineStyle','none');

            % Joshi:
            % Spearman%s partial correlation, r,
            % between spiking (spike rate, 0–200 ms following beep onset
            % minus baseline spike rate measured during fixation prior to beep onset)
            % and pupil (maximum change in pupil diameter 0–800 ms following beep
            % onset) responses, accounting for the effects of baseline pupil diameter
            % on both variables.
            [temp_stats.partial_evoked_r, temp_stats.partial_evoked_p] = partialcorr(raw_p_evoked, sub_FR_evoked, temp_beep_data(:,4),'Type','Spearman');
            % Alternatively, why not just compare the baseline subtracted responses
            % directly?
            [temp_stats.bs_evoked_r, temp_stats.bs_evoked_p] = corr(sub_p_evoked, sub_FR_evoked,'Type','Spearman');

            %   a) raw evoked pupil vs baseline sub evoked FR
            temp_stats.evoked_p_subevoked_FR = corr(corrected_p_evoked, sub_FR_evoked,'type','Spearman');
            %   b) raw evoked pupil vs raw evoked FR
            temp_stats.evoked_p_voked_FR = corr(corrected_p_evoked, corrected_FR_evoked,'type','Spearman');
            %   c) baseline sub pupil vs baseline sub evoked FR
            temp_stats.subevoked_p_subevoked_FR = corr(sub_p_evoked, sub_FR_evoked,'type','Spearman');
            %   d) baseline sub pupil vs raw evoked FR
            temp_stats.subevoked_p_evoked_FR = corr(sub_p_evoked, corrected_FR_evoked,'type','Spearman');
            
        end
        %% 5) Is baseline pupil related to evoked FR?
        if row == 5
            %   b) baseline subtracted evoked
            lm = fitlm(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_FR_evoked, 'linear');
            lm2 = fitlm(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_FR_evoked, 'purequadratic');
            if sum(lm_table.spike_base)>0
                lme = fitlme(lm_table,'spike_evoked ~ pupil_base');
                lme2 = fitlme(lm_table,'spike_evoked ~ pupil_base*pupil_base');
                results = compare(lme,lme2);
                temp_stats.sEvoked_v_pBase = results.pValue(2);
                temp_stats.sEvoked_v_pBase_LLR = results.LogLik(1)./results.LogLik(2);
            else
                temp_stats.sEvoked_v_pBase = NaN;
                temp_stats.sEvoked_v_pBase_LLR = NaN;
            end
            % subplot(6,size(example_neurons,1),ex + 4*size(example_neurons,1)); hold off;
            nexttile(tile_index);
            hold off;
            h=plot(lm); hold on;
            % h(1).Marker = 'none';
            h(2).Color = 'k';
            h(3).Color = 'k';
            h(4).Color = 'k';

            % h=plot(lm2);
            h(1).Marker = 'o'; h(1).MarkerFaceColor = [0.5 0.5 0.5]; h(1).MarkerEdgeColor = 'k'; h(1).LineWidth = 1;
            % h(2).Color = 'g';
            % h(3).Color = 'g';
            % h(4).Color = 'g';
            [temp_stats.base_p_subevoked_FR_R, temp_stats.base_p_subevoked_FR] = corr(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)),sub_FR_evoked,'type','Spearman');
            % subplot(2,5,6);
            % plot(pupil_drift.Residuals.Raw,sub_FR_evoked,'o')
            if ex == 3
                xlabel('Baseline Pupil (residuals)')
            else
                xlabel('');
            end
            if ex == 1
                ylabel({'Evoked FR', '(baselne subtracted)'})
            else
                ylabel('');
            end
            pbaspect([1 1 1]);
            l = legend('Location','Northwest');
            pos = l.Position;
            legend off;
            title('');
            % [stats.base_p_subevoked_FR_R, stats.base_p_subevoked_FR]
            ax = gca;
            rho_val = stats.base_p_subevoked_FR_R(stats.unit_id == example_neurons(ex,3));
            p_val = stats.base_p_subevoked_FR(stats.unit_id == example_neurons(ex,3));
            str = {['rho = ' num2str(rho_val)],...
                ['p = ', num2str(p_val)]};
            annotation('textbox','Position',pos,'String',str,'FitBoxToText','on','LineStyle','none');

            % Spearman%s partial correlation, r,
            % between spiking (spike rate, 0–200 ms following beep onset
            % minus baseline spike rate measured during fixation prior to beep onset)
            % and pupil (maximum change in pupil diameter 0–800 ms following beep
            % onset) responses, accounting for the effects of baseline pupil diameter
            % on both variables.

            % baseline pupil, raw evoked evoked FR?  baseline FR?
            [temp_stats.partial_base_p_evoked_FR_r, temp_stats.partial_base_p_evoked_FR_p] = partialcorr(temp_beep_data(:,4), raw_FR_evoked, temp_beep_data(:,6),'Type','Spearman');
            % [temp_stats.partial_base_p_evoked_FR_r, temp_stats.partial_base_p_evoked_FR_p] = partialcorr(pupil_drift.Residuals.Raw(1:size(temp_beep_data,1)), raw_FR_evoked, spike_drift.Residuals.Raw(1:size(temp_beep_data,1)),'Type','Spearman')
        end
        %% 6) Is evoked pupil related to baseline FR?
        %   b) baseline subtracted evoked
        if row == 6
            lm = fitlm(sub_p_evoked, spike_drift.Residuals.Raw(1:size(temp_beep_data,1)),'linear');
            lm2 = fitlm(sub_p_evoked, spike_drift.Residuals.Raw(1:size(temp_beep_data,1)), 'purequadratic');
            if sum(lm_table.spike_base)>0
                lme = fitlme(lm_table,'pupil_evoked ~ spike_base');
                lme2 = fitlme(lm_table,'pupil_evoked ~ spike_base*spike_base');
                results = compare(lme,lme2);
                temp_stats.pEvoked_v_sBase = results.pValue(2);
                temp_stats.pEvoked_v_sBase_LLR = results.LogLik(1)./results.LogLik(2);
            else
                temp_stats.pEvoked_v_sBase = NaN;
                temp_stats.pEvoked_v_sBase_LLR = NaN;
            end
            av = anova(lm2);
            temp_stats.subevoked_p_base_FR_lm2 = av.pValue(:,1);
            % subplot(6,size(example_neurons,1),ex + 5*size(example_neurons,1)); hold off;
            nexttile(tile_index); hold off;
            h=plot(lm); hold on;
            % h(1).Marker = 'none';
            h(2).Color = 'k';
            h(3).Color = 'k';
            h(4).Color = 'k';

            % h=plot(lm2);
            h(1).Marker = 'o'; h(1).MarkerFaceColor = [0.5 0.5 0.5]; h(1).MarkerEdgeColor = 'k'; h(1).LineWidth = 1;
            % h(2).Color = 'g';
            % h(3).Color = 'g';
            % h(4).Color = 'g';
            [temp_stats.subevoked_p_base_FR_R, temp_stats.subevoked_p_base_FR] = corr(sub_p_evoked, spike_drift.Residuals.Raw(1:size(temp_beep_data,1)),'type','Spearman');
            % subplot(2,5,10);
            % plot(sub_p_evoked,spike_drift.Residuals.Raw,'o')
            if ex == 3
                xlabel('Evoked Pupil (baselne subtracted)')
            else
                xlabel('');
            end
            if ex==1
                ylabel({'Baseline FR', '(residuals)'})
            else
                ylabel('');
            end
            pbaspect([1 1 1]);
            l = legend('Location','Northwest');
            pos = l.Position;
            legend off;
            title('');
            % [stats.subevoked_p_base_FR_R, stats.subevoked_p_base_FR]
            ax = gca;
            rho_val = stats.subevoked_p_base_FR_R(stats.unit_id == example_neurons(ex,3));
            p_val = stats.subevoked_p_base_FR(stats.unit_id == example_neurons(ex,3));
            str = {['rho = ' num2str(rho_val)],...
                ['p = ', num2str(p_val)]};
            annotation('textbox','Position',pos,'String',str,'FitBoxToText','on','LineStyle','none');

            % baseline FR, raw evoked pupil, baseline pupil
            [temp_stats.partial_base_FR_evoked_p_r, temp_stats.partial_base_FR_evoked_p_p] = partialcorr(temp_beep_data(:,6), raw_p_evoked, temp_beep_data(:,4),'Type','Spearman');

        end
    end
end

%% Plot correlation distributions
scatter_m_sz = 50;
plotOptions.monkey_symbols = {'o','d'};
x_start = [1,5];
temp_session_numbers_unique = session_numbers_unique;
% filter?
temp_stats = stats; %(stats.p<0.05,:);
temp_session_numbers_unique = session_numbers_unique; %(stats.p<0.05);
if size(temp_session_numbers_unique,1) == 1
    temp_session_numbers_unique = temp_session_numbers_unique';
end

for mm = 1:num_monkeys
    m_units = temp_stats.monkey_id==mm;
    %% 1) Is baseline pupil related to baseline FR?
    nexttile(size(example_neurons,1) + 1); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.p<0.05 & m_units),1);
    scatter(x,temp_stats.base_p_base_FR(temp_stats.p<0.05 & m_units),scatter_m_sz,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','k','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.p>0.05 & m_units),1);
    scatter(x,temp_stats.base_p_base_FR(temp_stats.p>0.05 & m_units),scatter_m_sz,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',0.3)
    base_p_base_FR_signtest(mm) = signrank(temp_stats.base_p_base_FR(m_units));
    if base_p_base_FR_signtest(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_p_base_FR(m_units),'omitnan'),median(temp_stats.base_p_base_FR(m_units),'omitnan')],'-','Color','k','LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_p_base_FR(m_units),'omitnan'),median(temp_stats.base_p_base_FR(m_units),'omitnan')],'-','Color','k','LineWidth',3)
    end
    title('')
    plot([0,8],[0 0],':k')
    xlim([0,8])
    ylim([-1,1])
    xlabel('');
    xticks([]);
    % xticklabels()
    ylabel('Spearman Partial Correlation')

    %% 2) Baseline Pupil vs Evoked Pupil
    nexttile(2*(size(example_neurons,1) + 1)); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.base_p_subevoked_p<0.05 & m_units & temp_session_numbers_unique),1);
    scatter(x,temp_stats.base_p_subevoked_p_R(temp_stats.base_p_subevoked_p<0.05 & m_units & temp_session_numbers_unique),scatter_m_sz,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0 174 239]./255,'MarkerEdgeColor','k','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.base_p_subevoked_p>0.05 & m_units  & temp_session_numbers_unique),1);
    scatter(x,temp_stats.base_p_subevoked_p_R(temp_stats.base_p_subevoked_p>0.05 & m_units  & temp_session_numbers_unique),scatter_m_sz,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0 174 239]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',0.2)
    base_p_subevoked_p_R(mm) = signrank(temp_stats.base_p_subevoked_p_R(m_units  & temp_session_numbers_unique));
    if base_p_subevoked_p_R(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_p_subevoked_p_R(m_units & temp_session_numbers_unique),'omitnan'),median(temp_stats.base_p_subevoked_p_R(m_units & temp_session_numbers_unique),'omitnan')],'-','Color',[0 174 239]./255,'LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_p_subevoked_p_R(m_units & temp_session_numbers_unique),'omitnan'),median(temp_stats.base_p_subevoked_p_R(m_units & temp_session_numbers_unique),'omitnan')],'-','Color',[0 174 239]./255,'LineWidth',3)
    end
    title('')
    plot([0,8],[0 0],':k')
    xlim([0,8])
    ylim([-1,1])
    xlabel('');
    xticks([]);
    ylabel('Spearman Correlation')

    %% 3) Baseline FR vs Evoked FR
    nexttile(3*(size(example_neurons,1) + 1)); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.base_FR_subevoked_FR<0.05 & m_units),1);
    scatter(x,temp_stats.base_FR_subevoked_FR_R(temp_stats.base_FR_subevoked_FR<0.05 & m_units),scatter_m_sz,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[237 28 36]./255,'MarkerEdgeColor','k','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.base_FR_subevoked_FR>0.05 & m_units),1);
    scatter(x,temp_stats.base_FR_subevoked_FR_R(temp_stats.base_FR_subevoked_FR>0.05 & m_units),scatter_m_sz,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[237 28 36]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',0.2)
    base_FR_subevoked_FR_R(mm) = signrank(temp_stats.base_FR_subevoked_FR_R(m_units));
    if base_FR_subevoked_FR_R(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_FR_subevoked_FR_R(m_units),'omitnan'),median(temp_stats.base_FR_subevoked_FR_R(m_units),'omitnan')],'-','Color',[237 28 36]./255,'LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_FR_subevoked_FR_R(m_units),'omitnan'),median(temp_stats.base_FR_subevoked_FR_R(m_units),'omitnan')],'-','Color',[237 28 36]./255,'LineWidth',3)
    end
    title('')
    plot([0,8],[0 0],':k')
    xlim([0,8])
    ylim([-1,1])
    xticks([]);
    xlabel('');
    ylabel('Spearman Correlation')
    
    %% 4) Evoked pupil vs Evoked FR (baseline sub)
    nexttile(4*(size(example_neurons,1) + 1)); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.bs_evoked_p<0.05 & m_units),1);
    scatter(x,temp_stats.bs_evoked_r(temp_stats.bs_evoked_p<0.05 & m_units),scatter_m_sz,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','k','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.bs_evoked_p>0.05 & m_units),1);
    scatter(x,temp_stats.bs_evoked_r(temp_stats.bs_evoked_p>0.05 & m_units),scatter_m_sz,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',0.3)
    bs_evoked_r_signtest(mm) = signrank(temp_stats.bs_evoked_r(m_units));
    if bs_evoked_r_signtest(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.bs_evoked_r(m_units),'omitnan'),median(temp_stats.bs_evoked_r(m_units),'omitnan')],'-','Color','k','LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.bs_evoked_r(m_units),'omitnan'),median(temp_stats.bs_evoked_r(m_units),'omitnan')],'-','Color','k','LineWidth',3)
    end    
    title('')
    plot([0,8],[0 0],':k')
    xlim([0,8])
    ylim([-1,1])
    xticks([]);
    xlabel('');
    ylabel('Spearman Correlation')

    %% 5) Baseline Pupil vs Evoked FR
    nexttile(5*(size(example_neurons,1) + 1)); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.base_p_subevoked_FR<0.05 & m_units),1);
    scatter(x,temp_stats.base_p_subevoked_FR_R(temp_stats.base_p_subevoked_FR<0.05 & m_units),scatter_m_sz,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','k','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.base_p_subevoked_FR>0.05 & m_units),1);
    scatter(x,temp_stats.base_p_subevoked_FR_R(temp_stats.base_p_subevoked_FR>0.05 & m_units),scatter_m_sz,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',0.3)
    base_p_subevoked_FR_R(mm) = signrank(temp_stats.base_p_subevoked_FR_R(m_units));
    if base_p_subevoked_FR_R(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_p_subevoked_FR_R(m_units),'omitnan'),median(temp_stats.base_p_subevoked_FR_R(m_units),'omitnan')],'-','Color','k','LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_p_subevoked_FR_R(m_units),'omitnan'),median(temp_stats.base_p_subevoked_FR_R(m_units),'omitnan')],'-','Color','k','LineWidth',3)
    end
    title('')
    plot([0,8],[0 0],':k')
    xlim([0,8])
    xticks([]);
    ylim([-1,1])
    xlabel('');
    ylabel('Spearman Correlation')

    %% 6) Baseline FR vs Evoked Pupil
    nexttile(6*(size(example_neurons,1) + 1)); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.subevoked_p_base_FR<0.05 & m_units),1);
    scatter(x,temp_stats.subevoked_p_base_FR_R(temp_stats.subevoked_p_base_FR<0.05 & m_units),scatter_m_sz,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','k','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.subevoked_p_base_FR>=0.05 & m_units),1);
    scatter(x,temp_stats.subevoked_p_base_FR_R(temp_stats.subevoked_p_base_FR>=0.05 & m_units),scatter_m_sz,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',0.3)
    base_FR_subevoked_p_R(mm) = signrank(temp_stats.subevoked_p_base_FR_R(m_units));
    if base_FR_subevoked_p_R(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.subevoked_p_base_FR_R(m_units),'omitnan'),median(temp_stats.subevoked_p_base_FR_R(m_units),'omitnan')],'-','Color','k','LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.subevoked_p_base_FR_R(m_units),'omitnan'),median(temp_stats.subevoked_p_base_FR_R(m_units),'omitnan')],'-','Color','k','LineWidth',3)
    end
    title('')
    plot([0,8],[0 0],':k')
    xlim([0,8])
    xticks([]);
    ylim([-1,1])
    xlabel('');
    ylabel('Spearman Correlation')
end