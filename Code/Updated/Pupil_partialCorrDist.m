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
    m_units = monkey_numbers==mm & session_numbers_unique;
    
    % Raw Baseline pupil vs Raw Evoked pupil
    subplot(1,3,1); hold on;
    title('Raw Baseline Pupil vs Raw Evoked Pupil');
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(stats.rawbase_p_rawevoked_p<0.05 & m_units'),1);
    scatter(x,stats.rawbase_p_rawevoked_p_R(stats.rawbase_p_rawevoked_p<0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor','b','MarkerEdgeColor','none','MarkerFaceAlpha',1,'MarkerEdgeColor','k')
    x = x_start(mm) + (3-1).*rand(sum(stats.rawbase_p_rawevoked_p>0.05 & m_units'),1);
    scatter(x,stats.rawbase_p_rawevoked_p_R(stats.rawbase_p_rawevoked_p>0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor','b','MarkerEdgeColor','none','MarkerFaceAlpha',0.2)
    rawbase_p_rawevoked_p_R(mm) = signtest(stats.rawbase_p_rawevoked_p_R(m_units));
    if rawbase_p_rawevoked_p_R(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(stats.rawbase_p_rawevoked_p_R(m_units),'omitnan'),median(stats.rawbase_p_rawevoked_p_R(m_units),'omitnan')],'-','Color','b','LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(stats.rawbase_p_rawevoked_p_R(m_units),'omitnan'),median(stats.rawbase_p_rawevoked_p_R(m_units),'omitnan')],'-','Color','b','LineWidth',3)
    end
    
    % Baseline p Residuals vs Raw Evoked p
    subplot(1,3,2); hold on;
    title('Baseline Pupil Residuals vs Raw Evoked Pupil')
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(stats.base_p_rawevoked_p<0.05 & m_units'),1);
    scatter(x,stats.base_p_rawevoked_p_R(stats.base_p_rawevoked_p<0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor','b','MarkerEdgeColor','none','MarkerFaceAlpha',1,'MarkerEdgeColor','k')
    x = x_start(mm) + (3-1).*rand(sum(stats.base_p_rawevoked_p>0.05 & m_units'),1);
    scatter(x,stats.base_p_rawevoked_p_R(stats.base_p_rawevoked_p>0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor','b','MarkerEdgeColor','none','MarkerFaceAlpha',0.2)
    base_p_rawevoked_p_R(mm) = signtest(stats.base_p_rawevoked_p_R(m_units));
    if base_p_rawevoked_p_R(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(stats.base_p_rawevoked_p_R(m_units),'omitnan'),median(stats.base_p_rawevoked_p_R(m_units),'omitnan')],'-','Color','b','LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(stats.base_p_rawevoked_p_R(m_units),'omitnan'),median(stats.base_p_rawevoked_p_R(m_units),'omitnan')],'-','Color','b','LineWidth',3)
    end

    % Baseline p Residuals vs BS Evoked p
    subplot(1,3,3); hold on;
    title('Baseline Pupil Residuals vs BS Evoked Pupil')
    % give random X positions
    x = x_start(mm) + (3-1).*rand(sum(stats.base_p_subevoked_p<0.05 & m_units'),1);
    scatter(x,stats.base_p_subevoked_p_R(stats.base_p_subevoked_p<0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor','b','MarkerEdgeColor','none','MarkerFaceAlpha',1,'MarkerEdgeColor','k')
    x = x_start(mm) + (3-1).*rand(sum(stats.base_p_subevoked_p>0.05 & m_units'),1);
    scatter(x,stats.base_p_subevoked_p_R(stats.base_p_subevoked_p>0.05 & m_units'),80,plotOptions.monkey_symbols{mm},'MarkerFaceColor','b','MarkerEdgeColor','none','MarkerFaceAlpha',0.2)
    base_p_subevoked_p_R(mm) = signtest(stats.base_p_subevoked_p_R(m_units));
    if base_p_subevoked_p_R(mm) < 0.05
        plot(x_start(mm) + [-0.5,2.5],[median(stats.base_p_subevoked_p_R(m_units),'omitnan'),median(stats.base_p_subevoked_p_R(m_units),'omitnan')],'-','Color','b','LineWidth',6)
    else
        plot(x_start(mm) + [-0.5,2.5],[median(stats.base_p_subevoked_p_R(m_units),'omitnan'),median(stats.base_p_subevoked_p_R(m_units),'omitnan')],'-','Color','b','LineWidth',3)
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