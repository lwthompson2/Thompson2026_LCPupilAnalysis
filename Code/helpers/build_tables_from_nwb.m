function [beep_tbl, fix_tbl] = build_tables_from_nwb(paths)
% BUILD_TABLES_FROM_NWB  Reconstruct analysis tables from DANDI NWB files.

if nargin < 1 || isempty(paths)
    paths = config_paths();
end

if ~isfield(paths, 'nwb_root') || isempty(paths.nwb_root)
    error('paths.nwb_root must be set to the local Dandiset folder containing NWB files.');
end

if ~isfolder(paths.nwb_root)
    error('NWB root not found: %s', paths.nwb_root);
end

repo_root = fileparts(fileparts(mfilename('fullpath')));
script_path = fullfile(repo_root, 'dandi_tools', 'extract_analysis_tables_from_nwb.py');
if ~isfile(script_path)
    error('Missing extractor script: %s', script_path);
end

if isfield(paths, 'python_cmd') && ~isempty(paths.python_cmd)
    pycmd = paths.python_cmd;
else
    pycmd = fullfile(repo_root, '..', '.venv-dandi311', 'bin', 'python');
    if ~isfile(pycmd)
        pycmd = 'python3';
    end
end

results_dir = paths.results_dir;
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

beep_csv = fullfile(results_dir, 'LC_Beep_table_from_nwb.csv');
fix_csv = fullfile(results_dir, 'LC_Fix_table_from_nwb.csv');

cmd = sprintf('"%s" "%s" --nwb-root "%s" --beep-csv "%s" --fix-csv "%s"', ...
    pycmd, script_path, paths.nwb_root, beep_csv, fix_csv);
[status, out] = system(cmd);
if status ~= 0
    error('Failed to extract NWB tables (status=%d):\n%s', status, out);
end

beep_tbl = readtable(beep_csv, 'TextType', 'char');
fix_tbl = readtable(fix_csv, 'TextType', 'char');

% Ensure monkey/session_file are cellstr for compatibility with existing code.
if ismember('monkey', beep_tbl.Properties.VariableNames)
    if iscell(beep_tbl.monkey)
        beep_tbl.monkey = cellstr(beep_tbl.monkey);
    elseif isstring(beep_tbl.monkey) || ischar(beep_tbl.monkey)
        beep_tbl.monkey = cellstr(string(beep_tbl.monkey));
    end
end
if ismember('session_file', beep_tbl.Properties.VariableNames)
    if iscell(beep_tbl.session_file)
        beep_tbl.session_file = cellstr(beep_tbl.session_file);
    elseif isstring(beep_tbl.session_file) || ischar(beep_tbl.session_file)
        beep_tbl.session_file = cellstr(string(beep_tbl.session_file));
    end
end
if ismember('monkey', fix_tbl.Properties.VariableNames)
    if iscell(fix_tbl.monkey)
        fix_tbl.monkey = cellstr(fix_tbl.monkey);
    elseif isstring(fix_tbl.monkey) || ischar(fix_tbl.monkey)
        fix_tbl.monkey = cellstr(string(fix_tbl.monkey));
    end
end
if ismember('session_file', fix_tbl.Properties.VariableNames)
    if iscell(fix_tbl.session_file)
        fix_tbl.session_file = cellstr(fix_tbl.session_file);
    elseif isstring(fix_tbl.session_file) || ischar(fix_tbl.session_file)
        fix_tbl.session_file = cellstr(string(fix_tbl.session_file));
    end
end

end
