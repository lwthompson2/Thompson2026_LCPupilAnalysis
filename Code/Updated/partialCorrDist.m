plotOptions.monkey_symbols = {'o','d'};
x_start = [1,5];
temp_session_numbers_unique = session_numbers_unique;
% filter?
temp_stats = stats; %(stats.evoked_spikes<0.05,:);
temp_session_numbers_unique = session_numbers_unique; %(stats.evoked_spikes<0.05);
if size(temp_session_numbers_unique,1) == 1
    temp_session_numbers_unique = temp_session_numbers_unique';
end
%% Plot correlation distributions
figure; hold on; 
for mm = 1:num_monkeys
    m_units = temp_stats.monkey_id==mm;

    % Baseline Pupil vs Evoked Pupil
    subplot(1,6,1); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.base_p_subevoked_p<0.05 & m_units & temp_session_numbers_unique),1);
    scatter(x,temp_stats.base_p_subevoked_p_R(temp_stats.base_p_subevoked_p<0.05 & m_units & temp_session_numbers_unique),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0 174 239]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.base_p_subevoked_p>0.05 & m_units  & temp_session_numbers_unique),1);
    scatter(x,temp_stats.base_p_subevoked_p_R(temp_stats.base_p_subevoked_p>0.05 & m_units  & temp_session_numbers_unique),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0 174 239]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',0.2)
    base_p_subevoked_p_R(mm) = signrank(temp_stats.base_p_subevoked_p_R(m_units  & temp_session_numbers_unique));
    if base_p_subevoked_p_R(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_p_subevoked_p_R(m_units & temp_session_numbers_unique),'omitnan'),median(temp_stats.base_p_subevoked_p_R(m_units & temp_session_numbers_unique),'omitnan')],'-','Color',[0 174 239]./255,'LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_p_subevoked_p_R(m_units & temp_session_numbers_unique),'omitnan'),median(temp_stats.base_p_subevoked_p_R(m_units & temp_session_numbers_unique),'omitnan')],'-','Color',[0 174 239]./255,'LineWidth',3)
    end

    % Baseline FR vs Evoked FR
    subplot(1,6,2); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.base_FR_subevoked_FR<0.05 & m_units),1);
    scatter(x,temp_stats.base_FR_subevoked_FR_R(temp_stats.base_FR_subevoked_FR<0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[237 28 36]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.base_FR_subevoked_FR>0.05 & m_units),1);
    scatter(x,temp_stats.base_FR_subevoked_FR_R(temp_stats.base_FR_subevoked_FR>0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[237 28 36]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',0.2)
    base_FR_subevoked_FR_R(mm) = signrank(temp_stats.base_FR_subevoked_FR_R(m_units));
    if base_FR_subevoked_FR_R(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_FR_subevoked_FR_R(m_units),'omitnan'),median(temp_stats.base_FR_subevoked_FR_R(m_units),'omitnan')],'-','Color',[237 28 36]./255,'LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_FR_subevoked_FR_R(m_units),'omitnan'),median(temp_stats.base_FR_subevoked_FR_R(m_units),'omitnan')],'-','Color',[237 28 36]./255,'LineWidth',3)
    end
    
    % Baseline Pupil vs Baseline Firing rate
    subplot(1,6,3); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.p<0.05 & m_units),1);
    scatter(x,temp_stats.base_p_base_FR(temp_stats.p<0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.p>0.05 & m_units),1);
    scatter(x,temp_stats.base_p_base_FR(temp_stats.p>0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',0.3)
    base_p_base_FR_signtest(mm) = signrank(temp_stats.base_p_base_FR(m_units));
    if base_p_base_FR_signtest(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_p_base_FR(m_units),'omitnan'),median(temp_stats.base_p_base_FR(m_units),'omitnan')],'-','Color','k','LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_p_base_FR(m_units),'omitnan'),median(temp_stats.base_p_base_FR(m_units),'omitnan')],'-','Color','k','LineWidth',3)
    end

    % Evoked pupil vs Evoked FR (baseline sub)
    subplot(1,6,4); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.bs_evoked_p<0.05 & m_units),1);
    scatter(x,temp_stats.bs_evoked_r(temp_stats.bs_evoked_p<0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.bs_evoked_p>0.05 & m_units),1);
    scatter(x,temp_stats.bs_evoked_r(temp_stats.bs_evoked_p>0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',0.3)
    bs_evoked_r_signtest(mm) = signrank(temp_stats.bs_evoked_r(m_units));
    if bs_evoked_r_signtest(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.bs_evoked_r(m_units),'omitnan'),median(temp_stats.bs_evoked_r(m_units),'omitnan')],'-','Color','k','LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.bs_evoked_r(m_units),'omitnan'),median(temp_stats.bs_evoked_r(m_units),'omitnan')],'-','Color','k','LineWidth',3)
    end
    

    % Baseline Pupil vs Evoked FR
    subplot(1,6,5); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.base_p_subevoked_FR<0.05 & m_units),1);
    scatter(x,temp_stats.base_p_subevoked_FR_R(temp_stats.base_p_subevoked_FR<0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.base_p_subevoked_FR>0.05 & m_units),1);
    scatter(x,temp_stats.base_p_subevoked_FR_R(temp_stats.base_p_subevoked_FR>0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',0.3)
    base_p_subevoked_FR_R(mm) = signrank(temp_stats.base_p_subevoked_FR_R(m_units));
    if base_p_subevoked_FR_R(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_p_subevoked_FR_R(m_units),'omitnan'),median(temp_stats.base_p_subevoked_FR_R(m_units),'omitnan')],'-','Color','k','LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.base_p_subevoked_FR_R(m_units),'omitnan'),median(temp_stats.base_p_subevoked_FR_R(m_units),'omitnan')],'-','Color','k','LineWidth',3)
    end

    % Baseline FR vs Evoked Pupil
    subplot(1,6,6); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.subevoked_p_base_FR<0.05 & m_units),1);
    scatter(x,temp_stats.subevoked_p_base_FR_R(temp_stats.subevoked_p_base_FR<0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(temp_stats.subevoked_p_base_FR>=0.05 & m_units),1);
    scatter(x,temp_stats.subevoked_p_base_FR_R(temp_stats.subevoked_p_base_FR>=0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',0.3)
    base_p_subevoked_FR_R(mm) = signrank(temp_stats.subevoked_p_base_FR_R(m_units));
    if base_p_subevoked_FR_R(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.subevoked_p_base_FR_R(m_units),'omitnan'),median(temp_stats.subevoked_p_base_FR_R(m_units),'omitnan')],'-','Color','k','LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.subevoked_p_base_FR_R(m_units),'omitnan'),median(temp_stats.subevoked_p_base_FR_R(m_units),'omitnan')],'-','Color','k','LineWidth',3)
    end
end

%% Formatting
subplot(1,6,1); hold on;
title('Pupil-Pupil')
plot([0,8],[0 0],':k')
xlim([0,8])
ylim([-1,1])
xlabel('');
ylabel('Spearman Correlation')

subplot(1,6,2); hold on;
title('FR-FR')
plot([0,8],[0 0],':k')
xlim([0,8])
ylim([-1,1])
xlabel('');
ylabel('Spearman Correlation')

subplot(1,6,3); hold on;
title('Baseline')
plot([0,8],[0 0],':k')
xlim([0,8])
ylim([-1,1])
xlabel('');
ylabel('Spearman Partial Correlation')

subplot(1,6,4); hold on;
title({'Direct evoked comparison', 'baseline subtracted'})
plot([0,8],[0 0],':k')
xlim([0,8])
ylim([-1,1])
xlabel('');
ylabel('Spearman Correlation')

subplot(1,6,5); hold on;
title('Base P vs Evoked FR')
plot([0,8],[0 0],':k')
xlim([0,8])
ylim([-1,1])
xlabel('');
ylabel('Spearman Correlation')

subplot(1,6,6); hold on;
title('Evoked P vs Base FR')
plot([0,8],[0 0],':k')
xlim([0,8])
ylim([-1,1])
xlabel('');
ylabel('Spearman Correlation')

% %% Testing additions
% figure; hold on; 
% for mm = 1:num_monkeys
%     m_units = temp_stats.monkey_id==mm;
% 
% 
%     subplot(1,2,2); hold on;
%     % give random X positions
%     x = x_start(mm) + (3-1).*rand(sum(temp_stats.partial_evoked_p<0.05 & m_units),1);
%     scatter(x,temp_stats.partial_evoked_r(temp_stats.partial_evoked_p<0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',1)
%     x = x_start(mm) + (3-1).*rand(sum(temp_stats.partial_evoked_p>0.05 & m_units),1);
%     scatter(x,temp_stats.partial_evoked_r(temp_stats.partial_evoked_p>0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',0.3)
%     bs_evoked_r_signtest(mm) = signtest(temp_stats.partial_evoked_r(m_units));
%     if bs_evoked_r_signtest(mm) < 0.05
%         plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.partial_evoked_r(m_units),'omitnan'),median(temp_stats.partial_evoked_r(m_units),'omitnan')],'-','Color','k','LineWidth',6)
%     else
%         plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.partial_evoked_r(m_units),'omitnan'),median(temp_stats.partial_evoked_r(m_units),'omitnan')],'-','Color','k','LineWidth',3)
%     end
%     title({'Partial evoked comparison: raw pupil', 'subtracted FR','baseline FR'})
%     plot([0,8],[0 0],':k')
%     xlim([0,8])
%     ylim([-1,1])
%     xlabel('');
%     ylabel('Partial Spearman Correlation')
% end
% 
% %% Other partial corr options:
% % [temp_stats.partial_base_p_evoked_FR_r, temp_stats.partial_base_p_evoked_FR_p]
% % [temp_stats.partial_base_FR_evoked_p_r, temp_stats.partial_base_FR_evoked_p_p]
% 
% figure; hold on; 
% for mm = 1:num_monkeys
%     m_units = temp_stats.monkey_id==mm;
%     subplot(1,2,1); hold on;
%     % give random X positions
%     x = x_start(mm) + (3-1).*rand(sum(temp_stats.partial_base_FR_evoked_p_p<0.05 & m_units),1);
%     scatter(x,temp_stats.partial_base_FR_evoked_p_r(temp_stats.partial_base_FR_evoked_p_p<0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',1)
%     x = x_start(mm) + (3-1).*rand(sum(temp_stats.partial_base_FR_evoked_p_p>0.05 & m_units),1);
%     scatter(x,temp_stats.partial_base_FR_evoked_p_r(temp_stats.partial_base_FR_evoked_p_p>0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',0.3)
%     partial_base_FR_evoked_signtest(mm) = signtest(temp_stats.partial_base_FR_evoked_p_r(m_units));
%     if partial_base_FR_evoked_signtest(mm) < 0.05
%         plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.partial_base_FR_evoked_p_r(m_units),'omitnan'),median(temp_stats.partial_base_FR_evoked_p_r(m_units),'omitnan')],'-','Color','k','LineWidth',6)
%     else
%         plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.partial_base_FR_evoked_p_r(m_units),'omitnan'),median(temp_stats.partial_base_FR_evoked_p_r(m_units),'omitnan')],'-','Color','k','LineWidth',3)
%     end
%     title({'Partial baseline FR', 'raw evoked pupil', 'baseline pupil'})
%     plot([0,8],[0 0],':k')
%     xlim([0,8])
%     ylim([-1,1])
%     xlabel('');
%     ylabel('Partial Spearman Correlation')
% 
%     subplot(1,2,2); hold on;
%     % give random X positions
%     x = x_start(mm) + (3-1).*rand(sum(temp_stats.partial_base_p_evoked_FR_p<0.05 & m_units),1);
%     scatter(x,temp_stats.partial_base_p_evoked_FR_r(temp_stats.partial_base_p_evoked_FR_p<0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',1)
%     x = x_start(mm) + (3-1).*rand(sum(temp_stats.partial_base_p_evoked_FR_p>0.05 & m_units),1);
%     scatter(x,temp_stats.partial_base_p_evoked_FR_r(temp_stats.partial_base_p_evoked_FR_p>0.05 & m_units),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',0.3)
%     bs_evoked_r_signtest(mm) = signtest(temp_stats.partial_base_p_evoked_FR_r(m_units));
%     if bs_evoked_r_signtest(mm) < 0.05
%         plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.partial_base_p_evoked_FR_r(m_units),'omitnan'),median(temp_stats.partial_base_p_evoked_FR_r(m_units),'omitnan')],'-','Color','k','LineWidth',6)
%     else
%         plot(x_start(mm) + [-0.5,2.5],[median(temp_stats.partial_base_p_evoked_FR_r(m_units),'omitnan'),median(temp_stats.partial_base_p_evoked_FR_r(m_units),'omitnan')],'-','Color','k','LineWidth',3)
%     end
%     title({'Partial baseline pupil', 'raw evoked FR', 'baseline FR'})
%     plot([0,8],[0 0],':k')
%     xlim([0,8])
%     ylim([-1,1])
%     xlabel('');
%     ylabel('Partial Spearman Correlation')
% end

