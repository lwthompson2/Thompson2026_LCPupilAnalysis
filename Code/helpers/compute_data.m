function outputs = compute_data(paths, options)
% COMPUTE_DATA  Build and cache LC/pupil tables (raw + z-scored) using
% modular helpers in Code/helpers from NWB sources.

if nargin < 1 || isempty(paths)
    if exist('config_paths.m','file')
        paths = config_paths();
    else
        error('Paths not provided and config_paths.m not found.');
    end
end
if nargin < 2, options = struct(); end
if ~isfield(options,'force'), options.force = false; end
options.source = 'nwb';
if ~isfield(options,'manuscript_filter') || isempty(options.manuscript_filter)
    options.manuscript_filter = true;
end
if ~isfield(options,'session_include_csv') || isempty(options.session_include_csv)
    options.session_include_csv = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'include_lists', 'manuscript_session_include.csv');
end
if ~isfield(options,'unit_include_csv') || isempty(options.unit_include_csv)
    options.unit_include_csv = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'include_lists', 'manuscript_unit_include.csv');
end
options.source = "nwb";

results_dir = paths.results_dir;
if ~exist(results_dir,'dir'), mkdir(results_dir); end

raw_mat = fullfile(results_dir, 'LC_data_raw.mat');
z_mat = fullfile(results_dir, 'LC_data_zscored.mat');
processing_version = sprintf('trial_filter_absz_lt8_combinedz_v2_%s', char(options.source));

% If cached files exist and not forced, load and return.
% Guard with processing_version so stale caches from previous filtering
% rules are automatically invalidated.
outputs = struct();
if ~options.force && exist(raw_mat,'file') && exist(z_mat,'file')
    s_raw = load(raw_mat);
    s_z = load(z_mat);
    cache_ok = isfield(s_raw, 'processing_version') && ischar(s_raw.processing_version) && ...
        strcmp(s_raw.processing_version, processing_version) && ...
        isfield(s_z, 'processing_version') && ischar(s_z.processing_version) && ...
        strcmp(s_z.processing_version, processing_version);
    if cache_ok
        outputs.raw.LC_Beep_table = s_raw.LC_Beep_table; outputs.raw.LC_Fix_table = s_raw.LC_Fix_table; %#ok<STRNU>
        outputs.z.LC_Beep_table = s_z.LC_Beep_table; outputs.z.LC_Fix_table = s_z.LC_Fix_table; %#ok<STRNU>
        outputs.raw_mat = raw_mat; outputs.z_mat = z_mat;
        return
    end
end

all_beep = table();
all_fix = table();
[all_beep, all_fix] = build_tables_from_nwb(paths);
if ~isempty(all_beep)
    all_beep.legacy_unit_id = NaN(height(all_beep),1);
end
if ~isempty(all_fix)
    all_fix.legacy_unit_id = NaN(height(all_fix),1);
end

% Recreate deterministic legacy-style unit IDs by session and local unit.
if ~isempty(all_beep) || ~isempty(all_fix)
    Kb = table();
    Kf = table();
    if ~isempty(all_beep)
        Kb = all_beep(:, {'monkey','session_file','unit'});
    end
    if ~isempty(all_fix)
        Kf = all_fix(:, {'monkey','session_file','unit'});
    end
    K = unique([Kb; Kf], 'rows', 'stable');

    monkey_ord = zeros(height(K),1);
    for ki = 1:height(K)
        if strcmpi(K.monkey{ki}, 'Oz')
            monkey_ord(ki) = 1;
        elseif strcmpi(K.monkey{ki}, 'Cicero')
            monkey_ord(ki) = 2;
        else
            monkey_ord(ki) = 99;
        end
    end
    K.monkey_ord = monkey_ord;
    K = sortrows(K, {'monkey_ord','session_file','unit'});
    K.legacy_unit_id = (1:height(K))';

    key_map = containers.Map('KeyType', 'char', 'ValueType', 'double');
    for ki = 1:height(K)
        k = sprintf('%s|%s|%d', K.monkey{ki}, K.session_file{ki}, K.unit(ki));
        key_map(k) = K.legacy_unit_id(ki);
    end
    if ~isempty(all_beep)
        for bi = 1:height(all_beep)
            k = sprintf('%s|%s|%d', all_beep.monkey{bi}, all_beep.session_file{bi}, all_beep.unit(bi));
            if isKey(key_map, k)
                all_beep.legacy_unit_id(bi) = key_map(k);
            end
        end
    end
    if ~isempty(all_fix)
        for fi = 1:height(all_fix)
            k = sprintf('%s|%s|%d', all_fix.monkey{fi}, all_fix.session_file{fi}, all_fix.unit(fi));
            if isKey(key_map, k)
                all_fix.legacy_unit_id(fi) = key_map(k);
            end
        end
    end
end

if options.manuscript_filter
    [all_beep, all_fix] = apply_manuscript_filter(all_beep, all_fix, options.session_include_csv, options.unit_include_csv);
end

raw_tables = struct('beep', all_beep, 'fix', all_fix);
% z-score tables grouped by unit/session where possible
z_tables = zscore_tables(raw_tables);

% Save both raw and z-scored versions
save_cached_tables(results_dir, raw_tables, z_tables, processing_version);

% Return outputs struct similar to previous API
outputs.raw_mat = raw_mat;
outputs.z_mat = z_mat;
outputs.raw.LC_Beep_table = raw_tables.beep;
outputs.raw.LC_Fix_table = raw_tables.fix;
outputs.z.LC_Beep_table = z_tables.beep;
outputs.z.LC_Fix_table = z_tables.fix;
% --- Compatibility: add legacy-style columns expected by plotting scripts ---
try
    LC_Beep_table = outputs.raw.LC_Beep_table;
    LC_Fix_table = outputs.raw.LC_Fix_table;
    % create numeric monkey_id with legacy lock: Oz=1, Cicero=2
    monkey_map = containers.Map({'Oz','Cicero'}, [1,2]);
    LC_Beep_table.monkey_id = NaN(height(LC_Beep_table),1);
    for i=1:height(LC_Beep_table)
        m = LC_Beep_table.monkey{i};
        if isKey(monkey_map, m)
            LC_Beep_table.monkey_id(i) = monkey_map(m);
        end
    end
    LC_Fix_table.monkey_id = NaN(height(LC_Fix_table),1);
    for i=1:height(LC_Fix_table)
        m = LC_Fix_table.monkey{i};
        if isKey(monkey_map, m)
            LC_Fix_table.monkey_id(i) = monkey_map(m);
        end
    end

    % create session_id mapping from session_file
    sess_names = unique([LC_Beep_table.session_file; LC_Fix_table.session_file]);
    sess_map = containers.Map(sess_names, 1:numel(sess_names));
    LC_Beep_table.session_id = zeros(height(LC_Beep_table),1);
    for i=1:height(LC_Beep_table)
        LC_Beep_table.session_id(i) = sess_map(LC_Beep_table.session_file{i});
    end
    LC_Fix_table.session_id = zeros(height(LC_Fix_table),1);
    for i=1:height(LC_Fix_table)
        LC_Fix_table.session_id(i) = sess_map(LC_Fix_table.session_file{i});
    end

    % use legacy loop-order unit ids if available
    if ismember('legacy_unit_id', LC_Beep_table.Properties.VariableNames)
        LC_Beep_table.unit_id = LC_Beep_table.legacy_unit_id;
    else
        LC_Beep_table.unit_id = NaN(height(LC_Beep_table),1);
    end
    if ismember('legacy_unit_id', LC_Fix_table.Properties.VariableNames)
        LC_Fix_table.unit_id = LC_Fix_table.legacy_unit_id;
    else
        LC_Fix_table.unit_id = NaN(height(LC_Fix_table),1);
    end

    % rename trial_time -> fix_global_start_time for compatibility
    if ismember('trial_time', LC_Beep_table.Properties.VariableNames)
        LC_Beep_table.fix_global_start_time = LC_Beep_table.trial_time;
    else
        LC_Beep_table.fix_global_start_time = NaN(height(LC_Beep_table),1);
    end
    if ismember('trial_time', LC_Fix_table.Properties.VariableNames)
        LC_Fix_table.fix_global_start_time = LC_Fix_table.trial_time;
    else
        LC_Fix_table.fix_global_start_time = NaN(height(LC_Fix_table),1);
    end

    % Preserve baseline-subtracted evoked columns as provided by processing
    % (do not re-subtract baseline here).
    if ismember('pupil_evoked', LC_Beep_table.Properties.VariableNames)
        LC_Beep_table.pupil_bs_evoked = LC_Beep_table.pupil_evoked;
    end
    if ismember('spike_evoked', LC_Beep_table.Properties.VariableNames)
        LC_Beep_table.spike_bs_evoked = LC_Beep_table.spike_evoked;
    end
    % also provide raw evoked values (baseline + baseline-subtracted evoked)
    if ismember('pupil_bs_evoked', LC_Beep_table.Properties.VariableNames) && ismember('pupil_baseline', LC_Beep_table.Properties.VariableNames)
        LC_Beep_table.raw_pupil_evoked = LC_Beep_table.pupil_baseline + LC_Beep_table.pupil_bs_evoked;
    end
    if ismember('spike_bs_evoked', LC_Beep_table.Properties.VariableNames) && ismember('spike_baseline', LC_Beep_table.Properties.VariableNames)
        LC_Beep_table.raw_spike_evoked = LC_Beep_table.spike_baseline + LC_Beep_table.spike_bs_evoked;
    end

    % compute per-unit drift residuals using baseline columns
    all_units = unique(LC_Beep_table.unit_id);
    LC_Beep_table.pupil_drift_residuals = NaN(height(LC_Beep_table),1);
    LC_Beep_table.spike_drift_residuals = NaN(height(LC_Beep_table),1);
    LC_Fix_table.pupil_drift_residuals = NaN(height(LC_Fix_table),1);
    LC_Fix_table.spike_drift_residuals = NaN(height(LC_Fix_table),1);
    for u = 1:numel(all_units)
        uid = all_units(u);
        idx_b = LC_Beep_table.unit_id == uid;
        idx_f = LC_Fix_table.unit_id == uid;
        times_b = LC_Beep_table.fix_global_start_time(idx_b);
        times_f = LC_Fix_table.fix_global_start_time(idx_f);
        pd_b = NaN(sum(idx_b),1);
        pd_f = NaN(sum(idx_f),1);
        fr_b = NaN(sum(idx_b),1);
        fr_f = NaN(sum(idx_f),1);
        if ismember('pupil_baseline', LC_Beep_table.Properties.VariableNames)
            pd_b = LC_Beep_table.pupil_baseline(idx_b);
        end
        if ismember('pupil_fix_baseline', LC_Fix_table.Properties.VariableNames)
            pd_f = LC_Fix_table.pupil_fix_baseline(idx_f);
        end
        if ismember('spike_baseline', LC_Beep_table.Properties.VariableNames)
            fr_b = LC_Beep_table.spike_baseline(idx_b);
        end
        if ismember('spike_fix_baseline', LC_Fix_table.Properties.VariableNames)
            fr_f = LC_Fix_table.spike_fix_baseline(idx_f);
        end
        all_times = [times_b; times_f];
        all_pd = [pd_b; pd_f];
        all_fr = [fr_b; fr_f];
        if numel(all_times) >= 2 && any(isfinite(all_pd))
            try
                mdl = fitlm(all_times, all_pd);
                res = mdl.Residuals.Raw;
                LC_Beep_table.pupil_drift_residuals(idx_b) = res(1:sum(idx_b));
                LC_Fix_table.pupil_drift_residuals(idx_f) = res(sum(idx_b)+(1:sum(idx_f)));
            catch
                % leave NaNs
            end
        end
        if numel(all_times) >= 2 && any(isfinite(all_fr))
            try
                mdl2 = fitlm(all_times, all_fr);
                res2 = mdl2.Residuals.Raw;
                LC_Beep_table.spike_drift_residuals(idx_b) = res2(1:sum(idx_b));
                LC_Fix_table.spike_drift_residuals(idx_f) = res2(sum(idx_b)+(1:sum(idx_f)));
            catch
                % leave NaNs
            end
        end
    end

    % write back into outputs: RAW
    outputs.raw.LC_Beep_table = LC_Beep_table;
    outputs.raw.LC_Fix_table = LC_Fix_table;

    % build Z-SCORED version from the same compatible tables so both raw
    % and z caches expose identical schema.
    z_compat = zscore_tables(struct('beep', LC_Beep_table, 'fix', LC_Fix_table));
    outputs.z.LC_Beep_table = z_compat.beep;
    outputs.z.LC_Fix_table = z_compat.fix;

    % Persist compatible caches with version metadata
    try
        LC_Beep_table = outputs.raw.LC_Beep_table; %#ok<NASGU>
        LC_Fix_table = outputs.raw.LC_Fix_table; %#ok<NASGU>
        save(raw_mat, 'LC_Beep_table', 'LC_Fix_table', 'processing_version', '-v7.3');

        LC_Beep_table = outputs.z.LC_Beep_table; %#ok<NASGU>
        LC_Fix_table = outputs.z.LC_Fix_table; %#ok<NASGU>
        save(z_mat, 'LC_Beep_table', 'LC_Fix_table', 'processing_version', '-v7.3');
    catch
        % ignore save errors
    end
catch ME
    warning(ME.identifier, '%s', ME.message);
end
end
