function fig = plot_S2_LLR_new(stats_table)
% PLOT_S2_LLR_NEW  New LLR plotting & counts for Supplemental Figure 2.
%   fig = plot_S2_LLR_new(stats_table)

if nargin < 1 || isempty(stats_table)
    error('stats_table required');
end

required_vars = {
    'pEvoked_v_pBase_LLR', ...
    'sEvoked_v_sBase_LLR', ...
    'pEvoked_v_sBase_LLR', ...
    'sEvoked_v_pBase_LLR', ...
    'session_id', ...
    'monkey_id' ...
    };
for i = 1:numel(required_vars)
    v = required_vars{i};
    if ~ismember(v, stats_table.Properties.VariableNames)
        stats_table.(v) = NaN(height(stats_table),1);
    end
end

% Pupil-only panel should be one value per unique session (legacy behavior).
session_filter = true(height(stats_table),1);
if ismember('session_id', stats_table.Properties.VariableNames)
    valid_sid = isfinite(stats_table.session_id);
    session_filter = false(height(stats_table),1);
    if any(valid_sid)
        [~, first_idx] = unique(stats_table.session_id(valid_sid), 'stable');
        valid_rows = find(valid_sid);
        session_filter(valid_rows(first_idx)) = true;
    end
    % If some rows do not carry a valid session id, include them rather
    % than silently dropping all data.
    session_filter(~valid_sid) = true;
end

fig = figure('Name','Figure_S2_LLR_new');
fig.Units = 'inches';
fig.Position = [1 1 13.0302 4.6272];
ax1 = subplot(1,4,1); histogram(stats_table.pEvoked_v_pBase_LLR(session_filter),'BinWidth',1,'FaceColor',[0 174 239]./255); xline(3.841); title('pEvoked vs pBase LLR'); ylabel('Number of Sessions'); xlabel('LLR');
ax2 = subplot(1,4,2); histogram(stats_table.sEvoked_v_sBase_LLR,'BinWidth',1,'FaceColor','r'); xline(3.841); title('sEvoked vs sBase LLR'); ylabel('Number of Units'); xlabel('LLR');
ax3 = subplot(1,4,3); histogram(stats_table.pEvoked_v_sBase_LLR,'BinWidth',1,'FaceColor',[0.5 0.5 0.5]); xline(3.841); title('pEvoked vs sBase LLR'); ylabel('Number of Units'); xlabel('LLR');
ax4 = subplot(1,4,4); histogram(stats_table.sEvoked_v_pBase_LLR,'BinWidth',1,'FaceColor',[0.5 0.5 0.5]); xline(3.841); title('sEvoked vs pBase LLR'); ylabel('Number of Units'); xlabel('LLR');

crit = 3.841;

monkey_ids = stats_table.monkey_id;
unit_filter = true(height(stats_table),1);

% Panel 1 uses unique sessions.
annotate_counts_by_monkey(ax1, stats_table.pEvoked_v_pBase_LLR, monkey_ids, session_filter, crit);

% Panels 2-4 use units.
annotate_counts_by_monkey(ax2, stats_table.sEvoked_v_sBase_LLR, monkey_ids, unit_filter, crit);
annotate_counts_by_monkey(ax3, stats_table.pEvoked_v_sBase_LLR, monkey_ids, unit_filter, crit);
annotate_counts_by_monkey(ax4, stats_table.sEvoked_v_pBase_LLR, monkey_ids, unit_filter, crit);

% Print counts per monkey if monkey_id exists
if ismember('monkey_id', stats_table.Properties.VariableNames)
    for mm = unique(stats_table.monkey_id)'
        fprintf('Monkey %d counts LLR>3.841 pEvoked_v_pBase (session-level): %d/%d\n', mm, ...
            sum(stats_table.pEvoked_v_pBase_LLR > 3.841 & stats_table.monkey_id==mm & session_filter), ...
            sum(stats_table.monkey_id==mm & session_filter));
    end
end
end

function annotate_counts_by_monkey(ax, values, monkey_ids, panel_filter, crit)
oz_mask = panel_filter & (monkey_ids == 1);
ci_mask = panel_filter & (monkey_ids == 2);

oz_total = sum(oz_mask);
oz_inc = sum(isfinite(values(oz_mask)));
oz_sig = sum(values(oz_mask) > crit, 'omitnan');

ci_total = sum(ci_mask);
ci_inc = sum(isfinite(values(ci_mask)));
ci_sig = sum(values(ci_mask) > crit, 'omitnan');

txt = sprintf(['Oz  Inc N = %d/%d\n' ...
               'Oz  >3.841 N = %d/%d\n' ...
               'Ci  Inc N = %d/%d\n' ...
               'Ci  >3.841 N = %d/%d'], ...
               oz_inc, oz_total, oz_sig, oz_inc, ci_inc, ci_total, ci_sig, ci_inc);

text(ax, 0.97, 0.97, txt, ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'top', ...
    'FontSize', 8, ...
    'BackgroundColor', 'w', ...
    'Margin', 1);
end
