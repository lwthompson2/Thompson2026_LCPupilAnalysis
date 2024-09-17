%% Are non-baseline subtracted evoked responses related? Not really..
figure; hold on;
for mm = 1:num_monkeys
    
    % Each monk
    Lm = LC_PD_data(:,1)==mm;
    
    % Each plot
    subplot(1,num_monkeys,mm); cla reset; hold on;
    xs = LC_PD_data(Lm,3) + LC_PD_data(Lm,4); % add back baseline
    ys = LC_PD_data(Lm,5) + LC_PD_data(Lm,6);
    Lg = isfinite(xs) & isfinite(ys);
    plot(xs, ys, 'k.');
    set(gca, 'FontSize', 12);
    xlabel('Evoked Pupil')
    ylabel('Evoked Response');
    [R,P] = corr(xs(Lg), ys(Lg), 'type', 'Spearman');
    title(sprintf('R=%.3f, P=%.3f', R, P))
    lsline;
end

%% Is baseline pupil related to non-baseline subtracted evoked FR? Not really
figure; hold on;
for mm = 1:num_monkeys
    
    % Each monk
    Lm = LC_PD_data(:,1)==mm;
    
    % Each plot
    subplot(1,num_monkeys,mm); cla reset; hold on;
    xs = LC_PD_data(Lm,3);
    ys = LC_PD_data(Lm,5) + LC_PD_data(Lm,6);
    Lg = isfinite(xs) & isfinite(ys);
    plot(xs, ys, 'k.');
    set(gca, 'FontSize', 12);
    xlabel('Baseline Pupil')
    ylabel('Evoked FR');
    [R,P] = corr(xs(Lg), ys(Lg), 'type', 'Spearman');
    title(sprintf('R=%.3f, P=%.3f', R, P))
    lsline;
end

%% Is non-baseline subtracted evoked pupil related to baseline FR?
figure; hold on;
for mm = 1:num_monkeys
    
    % Each monk
    Lm = LC_PD_data(:,1)==mm;
    
    % Each plot
    subplot(1,num_monkeys,mm); cla reset; hold on;
    xs = LC_PD_data(Lm,3) + LC_PD_data(Lm,4);
    ys = LC_PD_data(Lm,5);
    Lg = isfinite(xs) & isfinite(ys);
    plot(xs, ys, 'k.');
    set(gca, 'FontSize', 12);
    xlabel('Evoked Pupil')
    ylabel('Baseline FR');
    [R,P] = corr(xs(Lg), ys(Lg), 'type', 'Spearman');
    title(sprintf('R=%.3f, P=%.3f', R, P))
    lsline;
end

%% Is baseline FR related to baseline subtracted evoked pupil?
% NO, and this is the point that Eldar 2013 tries to make:
% "Because phasic [pupil] responses are inversely
% related to baseline pupil diameter and tonic LC-NE activity, pupil
% dilation responses provide an inverse measure of tonic gain"

figure; hold on;
for mm = 1:num_monkeys
    
    % Each monk
    Lm = LC_PD_data(:,1)==mm;
    
    % Each plot
    subplot(1,num_monkeys,mm); cla reset; hold on;
    xs = LC_PD_data(Lm,4);
    ys = LC_PD_data(Lm,5);
    Lg = isfinite(xs) & isfinite(ys);
    plot(xs, ys, 'k.');
    set(gca, 'FontSize', 12);
    xlabel('Evoked Pupil (baseline sub.)')
    ylabel('Baseline FR');
    [R,P] = corr(xs(Lg), ys(Lg), 'type', 'Spearman');
    title(sprintf('R=%.3f, P=%.3f', R, P))
    lsline;
end