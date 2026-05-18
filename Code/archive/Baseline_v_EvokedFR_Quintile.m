% Archived original: Baseline_v_EvokedFR_Quintile.m
% This script was moved to the archive by repository maintenance.

%% Is baseline FR related to baseline subtracted evoked pupil?
% NO, and this is the point that Eldar 2013 tries to make:
% "Because phasic [pupil] responses are inversely
% related to baseline pupil diameter and tonic LC-NE activity, pupil
% dilation responses provide an inverse measure of tonic gain"

% Break this out by quintiles
figure; hold on;
for mm = 1:num_monkeys

    % Each monk
    Lm = LC_PD_data(:,1)==mm;

    xs = LC_PD_data(Lm,4);
    ys = LC_PD_data(Lm,5);
    Lg = isfinite(xs) & isfinite(ys);
    xs = xs(Lg);
    ys = ys(Lg);
    qs = quantile(xs,linspace(0,1,6)');
    qs(1) = min(xs);
    qs(end) = max(xs);
    for quant = 1:length(qs)-1
        % Each plot
        pnum = (mm-1)*5+quant;
        subplot(num_monkeys,5,pnum); cla reset; hold on;
        inds = qs(quant) <= xs & xs < qs(quant+1);
        plot(xs(inds), ys(inds), 'k.');
        set(gca, 'FontSize', 12);
        xlabel('Evoked Pupil (baseline sub.)')
        ylabel('Baseline FR');
        [R,P] = corr(xs(inds), ys(inds), 'type', 'Spearman');
        title(sprintf('R=%.3f, P=%.3f', R, P))
        lsline;
    end
end
