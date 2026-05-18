% Archived original: baseline_relationships.m
% This script was moved to the archive by repository maintenance.

%% Are baseline responses related linearly? Not really
% This should be true, but only for some neurons (Fig. 3 Joshi et al 2016)
figure; hold on;
for mm = 1:num_monkeys
    
    % Each monk
    Lm = LC_PD_data(:,1)==mm;
    
    % Each plot
    subplot(1,num_monkeys,mm); cla reset; hold on;
    xs = LC_PD_data(Lm,3);
    ys = LC_PD_data(Lm,5);
    Lg = isfinite(xs) & isfinite(ys);
    plot(xs, ys, 'k.');
    set(gca, 'FontSize', 12);
    xlabel('Baseline Pupil')
    ylabel('Baseline FR');
    [R,P] = corr(xs(Lg), ys(Lg), 'type', 'Spearman');
    title(sprintf('R=%.3f, P=%.3f', R, P))
    lsline;
end

%% Are baseline responses quadratically related?


