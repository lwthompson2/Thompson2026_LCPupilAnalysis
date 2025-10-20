% In figure 1 we show the idea - that baseline and evoked LC firing will
% follow an inverted U curve.
% In all the other plots, we show that baseline LC activity (residuals) and the
% baseline subtracted evoked activity are highly negatively correlated.

% However, should we first actually look at the raw relationship? The
% theory suggests (maybe) that the evoked activity should be greater than
% the baseline activitity. 
plotOptions.monkey_symbols = {'o','d'};
figure; hold on;
x_start = [1,5];
for mm = 1:num_monkeys
    m_units = monkey_numbers==mm;
    
    % Raw Baseline FR vs Raw Evoked FR
    subplot(1,3,1); hold on;
    title('Raw Baseline FR vs Raw Evoked FR');
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(stats.rawbase_FR_rawevoked_FR<0.05 & m_units'),1);
    scatter(x,stats.rawbase_FR_rawevoked_FR_R(stats.rawbase_FR_rawevoked_FR<0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[237 28 36]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',1,'MarkerEdgeColor','k')
    x = x_start(mm) + (3-1).*rand(sum(stats.rawbase_FR_rawevoked_FR>0.05 & m_units'),1);
    scatter(x,stats.rawbase_FR_rawevoked_FR_R(stats.rawbase_FR_rawevoked_FR>0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[237 28 36]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',0.2)
    rawbase_FR_rawevoked_FR_R(mm) = signtest(stats.rawbase_FR_rawevoked_FR_R(m_units));
    if rawbase_FR_rawevoked_FR_R(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(stats.rawbase_FR_rawevoked_FR_R(m_units),'omitnan'),median(stats.rawbase_FR_rawevoked_FR_R(m_units),'omitnan')],'-','Color',[237 28 36]./255,'LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(stats.rawbase_FR_rawevoked_FR_R(m_units),'omitnan'),median(stats.rawbase_FR_rawevoked_FR_R(m_units),'omitnan')],'-','Color',[237 28 36]./255,'LineWidth',3)
    end
    
    % Baseline FR Residuals vs Raw Evoked FR
    subplot(1,3,2); hold on;
    title('Baseline FR Residuals vs Raw Evoked FR')
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(stats.base_FR_rawevoked_FR<0.05 & m_units'),1);
    scatter(x,stats.base_FR_rawevoked_FR_R(stats.base_FR_rawevoked_FR<0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[237 28 36]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',1,'MarkerEdgeColor','k')
    x = x_start(mm) + (3-1).*rand(sum(stats.base_FR_rawevoked_FR>0.05 & m_units'),1);
    scatter(x,stats.base_FR_rawevoked_FR_R(stats.base_FR_rawevoked_FR>0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[237 28 36]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',0.2)
    base_FR_rawevoked_FR_R(mm) = signtest(stats.base_FR_rawevoked_FR_R(m_units));
    if base_FR_rawevoked_FR_R(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(stats.base_FR_rawevoked_FR_R(m_units),'omitnan'),median(stats.base_FR_rawevoked_FR_R(m_units),'omitnan')],'-','Color',[237 28 36]./255,'LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(stats.base_FR_rawevoked_FR_R(m_units),'omitnan'),median(stats.base_FR_rawevoked_FR_R(m_units),'omitnan')],'-','Color',[237 28 36]./255,'LineWidth',3)
    end

    % Baseline FR Residuals vs BS Evoked FR
    subplot(1,3,3); hold on;
    title('Baseline FR Residuals vs BS Evoked FR')
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(stats.base_FR_subevoked_FR<0.05 & m_units'),1);
    scatter(x,stats.base_FR_subevoked_FR_R(stats.base_FR_subevoked_FR<0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[237 28 36]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',1,'MarkerEdgeColor','k')
    x = x_start(mm) + (3-1).*rand(sum(stats.base_FR_subevoked_FR>0.05 & m_units'),1);
    scatter(x,stats.base_FR_subevoked_FR_R(stats.base_FR_subevoked_FR>0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor',[237 28 36]./255,'MarkerEdgeColor','none','MarkerFaceAlpha',0.2)
    base_FR_subevoked_FR_R(mm) = signtest(stats.base_FR_subevoked_FR_R(m_units));
    if base_FR_subevoked_FR_R(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(stats.base_FR_subevoked_FR_R(m_units),'omitnan'),median(stats.base_FR_subevoked_FR_R(m_units),'omitnan')],'-','Color',[237 28 36]./255,'LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(stats.base_FR_subevoked_FR_R(m_units),'omitnan'),median(stats.base_FR_subevoked_FR_R(m_units),'omitnan')],'-','Color',[237 28 36]./255,'LineWidth',3)
    end   
end
subplot(1,3,1); hold on; ylim([-1,1]); plot([0,8],[0,0],'--k');
subplot(1,3,2); hold on; ylim([-1,1]); plot([0,8],[0,0],'--k');
subplot(1,3,3); hold on; ylim([-1,1]); plot([0,8],[0,0],'--k');
f = gcf;
f.Position = [1,169,985,420];

% figure; hold on; 
% lm = fitlm(LC_Beep_data(:,10), LC_Beep_data(:,6)+LC_Beep_data(:,7));
% plot(lm)
% 
% % plot(LC_Beep_data(:,10), LC_Beep_data(:,6)+LC_Beep_data(:,7),'o');
% box on;
% axis square;