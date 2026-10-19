function [beep_tbl, fix_tbl] = apply_manuscript_filter(beep_tbl, fix_tbl, session_csv, unit_csv)
% APPLY_MANUSCRIPT_FILTER  Restrict tables to manuscript include lists.

if isempty(beep_tbl) && isempty(fix_tbl)
    return
end

if ~isfile(session_csv) || ~isfile(unit_csv)
    error('Manuscript include CSVs not found:\n  %s\n  %s', session_csv, unit_csv);
end

Ts = readtable(session_csv, 'TextType', 'char');
Tu = readtable(unit_csv, 'TextType', 'char');

req_s = {'monkey','session_file'};
req_u = {'monkey','session_file','unit'};
if ~all(ismember(req_s, Ts.Properties.VariableNames))
    error('Session include CSV must include columns: monkey, session_file');
end
if ~all(ismember(req_u, Tu.Properties.VariableNames))
    error('Unit include CSV must include columns: monkey, session_file, unit');
end

Ts = unique(Ts(:, req_s), 'rows');
Tu = Tu(:, req_u);
Tu.unit = double(Tu.unit);

beep_tbl = filter_table(beep_tbl, Ts, Tu);
fix_tbl = filter_table(fix_tbl, Ts, Tu);

end

function T = filter_table(T, Ts, Tu)
if isempty(T)
    return
end

if ~ismember('monkey', T.Properties.VariableNames) || ~ismember('session_file', T.Properties.VariableNames)
    error('Table missing required columns monkey/session_file for manuscript filtering');
end
if ~ismember('unit', T.Properties.VariableNames)
    error('Table missing required column unit for manuscript filtering');
end

% Keep only included sessions.
sess_keys = cell(height(Ts),1);
for i = 1:height(Ts)
    sess_keys{i} = sprintf('%s|%s', Ts.monkey{i}, Ts.session_file{i});
end

row_sess_keys = cell(height(T),1);
for i = 1:height(T)
    row_sess_keys{i} = sprintf('%s|%s', T.monkey{i}, T.session_file{i});
end
is_sess = ismember(row_sess_keys, sess_keys);
T = T(is_sess, :);
if isempty(T)
    return
end

% Keep only included units within those sessions.
unit_keys = cell(height(Tu),1);
for i = 1:height(Tu)
    unit_keys{i} = sprintf('%s|%s|%g', Tu.monkey{i}, Tu.session_file{i}, Tu.unit(i));
end

row_unit_keys = cell(height(T),1);
for i = 1:height(T)
    row_unit_keys{i} = sprintf('%s|%s|%g', T.monkey{i}, T.session_file{i}, T.unit(i));
end
is_unit = ismember(row_unit_keys, unit_keys);
T = T(is_unit, :);

end
