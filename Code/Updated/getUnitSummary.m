%% getUnitSummary
% plot unit summary and get stats on per-unit basis
clear stats; % just in case

%% Params and options
save_figs = false;
to_remove = [43, 65]; % neurons that have insufficient rate values

for ith_unit = 1:length(unique(LC_Beep_data(:,3)))
    disp(sprintf('Unit summary %d/%d', ...
                    ith_unit, length(unique(LC_Beep_data(:,3)))))
    stats(ith_unit) = unitSummaryPlot(LC_Beep_table(LC_Beep_table.unit_id==ith_unit,:), LC_Fix_table(LC_Fix_table.unit_id==ith_unit,:));
    unit_ids(ith_unit) = ith_unit; % because you remove neurons by index later
    mm = LC_Beep_data(LC_Beep_data(:,3)==ith_unit,1);
    mm = mm(1);
    %% Save the figure?
    if save_figs
        % if stats(ith_unit).p <0.05
            h=gcf;
            set(h,'PaperOrientation','landscape');
            set(h,'PaperUnits','normalized');
            set(h,'PaperPosition', [0 0 1 1]);
            if do_zscore
                name = ['/Users/lowell/Documents/GitHub/LCPupil_Joshi_Analysis/Fits/Z_scored/',monkeys{mm},'/','Unit_',num2str(ith_unit),'.pdf'];
            else
                name = ['/Users/lowell/Documents/GitHub/LCPupil_Joshi_Analysis/Fits/',monkeys{mm},'/','Unit_',num2str(ith_unit),'.pdf'];
            end
            saveas(h,name)
        % end
    end
end
stats = struct2table(stats);
stats.unit_id = unit_ids';
%% remove unwanted neurons
stats([to_remove],:) = [];
session_numbers_unique(to_remove) = [];
LC_Beep_table([find(ismember(LC_Beep_data(:,3),to_remove))],:) = [];
LC_Beep_data(ismember(LC_Beep_data(:,3),to_remove),:) = [];
LC_Fix_table([find(ismember(LC_Fix_data(:,3),to_remove))],:) = [];
LC_Fix_data(ismember(LC_Fix_data(:,3),to_remove),:) = [];
