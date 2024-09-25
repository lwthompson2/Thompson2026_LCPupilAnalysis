plotOptions.monkey_symbols = {'o','d'};
x_start = [1,5];

figure; hold on;
for mm = 1:num_monkeys
    m_units = monkey_numbers==mm;
    % Baseline Pupil vs Baseline Firing rate
    subplot(1,5,1); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(stats.p<0.05 & m_units'),1);
    scatter(x,stats.base_p_base_FR(stats.p<0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(stats.p>0.05 & m_units'),1);
    scatter(x,stats.base_p_base_FR(stats.p>0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',0.3)
    plot(x_start(mm) + [-0.5,2.5],[median(stats.base_p_base_FR(m_units),'omitnan'),median(stats.base_p_base_FR(m_units),'omitnan')],'-','Color','k','LineWidth',6)

    % Baseline Pupil vs Evoked Pupil
    subplot(1,5,2); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(stats.base_p_subevoked_p<0.05 & m_units'),1);
    scatter(x,stats.base_p_subevoked_p_R(stats.base_p_subevoked_p<0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0 174 239]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(stats.base_p_subevoked_p>0.05 & m_units'),1);
    scatter(x,stats.base_p_subevoked_p_R(stats.base_p_subevoked_p>0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0 174 239]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',0.2)
    plot(x_start(mm) + [-0.5,2.5],[median(stats.base_p_subevoked_p_R(m_units),'omitnan'),median(stats.base_p_subevoked_p_R(m_units),'omitnan')],'-','Color',[0 174 239]./255,'LineWidth',6)

    % Baseline FR vs Evoked FR
    subplot(1,5,3); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(stats.base_FR_subevoked_FR<0.05 & m_units'),1);
    scatter(x,stats.base_FR_subevoked_FR_R(stats.base_FR_subevoked_FR<0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[237 28 36]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(stats.base_FR_subevoked_FR>0.05 & m_units'),1);
    scatter(x,stats.base_FR_subevoked_FR_R(stats.base_FR_subevoked_FR>0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[237 28 36]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',0.2)
    plot(x_start(mm) + [-0.5,2.5],[median(stats.base_FR_subevoked_FR_R(m_units),'omitnan'),median(stats.base_FR_subevoked_FR_R(m_units),'omitnan')],'-','Color',[237 28 36]./255,'LineWidth',6)

    % Baseline Pupil vs Evoked FR
    subplot(1,5,4); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(stats.base_p_subevoked_FR<0.05 & m_units'),1);
    scatter(x,stats.base_p_subevoked_FR_R(stats.base_p_subevoked_FR<0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(stats.base_p_subevoked_FR>0.05 & m_units'),1);
    scatter(x,stats.base_p_subevoked_FR_R(stats.base_p_subevoked_FR>0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',0.3)
    plot(x_start(mm) + [-0.5,2.5],[median(stats.base_p_subevoked_FR_R(m_units),'omitnan'),median(stats.base_p_subevoked_FR_R(m_units),'omitnan')],'-','Color','k','LineWidth',6)

    % Baseline FR vs Evoked Pupil
    subplot(1,5,5); hold on;
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(stats.subevoked_p_base_FR<0.05 & m_units'),1);
    scatter(x,stats.subevoked_p_base_FR_R(stats.subevoked_p_base_FR<0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',1)
    x = x_start(mm) + (3-1).*rand(sum(stats.subevoked_p_base_FR>0.05 & m_units'),1);
    scatter(x,stats.subevoked_p_base_FR_R(stats.subevoked_p_base_FR>0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor','none','MarkerFaceAlpha',0.3)
    plot(x_start(mm) + [-0.5,2.5],[median(stats.base_p_subevoked_FR_R(m_units),'omitnan'),median(stats.base_p_subevoked_FR_R(m_units),'omitnan')],'-','Color','k','LineWidth',6)
end

%% Formating
subplot(1,5,1); hold on;
title('Baseline')
plot([0,8],[0 0],':k')
xlim([0,8])
ylim([-0.4,0.4])
xlabel('');
ylabel('Spearman Partial Correlation')

subplot(1,5,2); hold on;
title('Pupil-Pupil')
plot([0,8],[0 0],':k')
xlim([0,8])
ylim([-1,1])
xlabel('');
ylabel('Spearman Correlation')

subplot(1,5,3); hold on;
title('FR-FR')
plot([0,8],[0 0],':k')
xlim([0,8])
ylim([-1,1])
xlabel('');
ylabel('Spearman Correlation')

subplot(1,5,4); hold on;
title('Base P vs Evoked FR')
plot([0,8],[0 0],':k')
xlim([0,8])
ylim([-1,1])
xlabel('');
ylabel('Spearman Correlation')

subplot(1,5,5); hold on;
title('Evoked P vs Base FR')
plot([0,8],[0 0],':k')
xlim([0,8])
ylim([-1,1])
xlabel('');
ylabel('Spearman Correlation')
