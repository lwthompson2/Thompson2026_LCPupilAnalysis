%% Are baseline subtracted evoked responses related? Yes!
% NOTE: This is effectively Figure 7 from Joshi et al., 2016
figure; hold on;
for mm = 1:num_monkeys
    
    % Each monk
    Lm = LC_PD_data(:,1)==mm;
    
    % Each plot
    subplot(1,num_monkeys,mm); cla reset; hold on;
    xs = LC_PD_data(Lm,4);
    ys = LC_PD_data(Lm,6);
    Lg = isfinite(xs) & isfinite(ys);
    plot(xs, ys, 'k.');
    set(gca, 'FontSize', 12);
    xlabel('Evoked Pupil (baseline sub.)')
    ylabel('Evoked FR (baseline sub.)');
    [R,P] = corr(xs(Lg), ys(Lg), 'type', 'Spearman');
    title(sprintf('R=%.3f, P=%.3f', R, P))
    lsline;
end


