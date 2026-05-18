function outputs = compute_data(paths, options)
% COMPUTE_DATA  Build and cache LC/pupil tables (raw + z-scored) using
% modular helpers in Code/helpers. This replaces running the legacy
% `getData.m` script.

if nargin < 1 || isempty(paths)
    if exist('config_paths.m','file')
        paths = config_paths();
    else
        error('Paths not provided and config_paths.m not found.');
    end
end
if nargin < 2, options = struct(); end
if ~isfield(options,'force'), options.force = false; end

results_dir = paths.results_dir;
if ~exist(results_dir,'dir'), mkdir(results_dir); end

raw_mat = fullfile(results_dir, 'LC_data_raw.mat');
z_mat = fullfile(results_dir, 'LC_data_zscored.mat');
processing_version = 'trial_filter_absz_lt8_combinedz_v2';

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

% Build site list (monkeys default inside helper)
sites = load_site_list();
all_beep = table();
all_fix = table();
legacy_unit_counter = 0;
legacy_unit_map = containers.Map('KeyType','char','ValueType','double');
for si = 1:numel(sites)
    s = sites(si);
    if isempty(s.base_dir) || isempty(s.fnames), continue; end
    for f = 1:numel(s.fnames)
        fname = s.fnames{f};
        file_key_prefix = sprintf('%s|%s', s.monkey, fname);
        try
            tmp = load(fullfile(s.base_dir, fname), 'siteData');
            if isfield(tmp, 'siteData') && iscell(tmp.siteData) && numel(tmp.siteData) >= 3
                siteData = tmp.siteData; %#ok<NASGU>
                times = [-100 0; 0 800; -400 0; 0 200];
                Fbeep = find(siteData{1}(:,3)==1 & ...
                    siteData{1}(:,4)>abs(min(times(:,1))) & ...
                    siteData{1}(:,4)<size(siteData{2},2)-max(times(:,2)));
                Ffix = find(siteData{1}(:,3)==1 & ...
                    isnan(siteData{1}(:,4)) & ...
                    isnan(siteData{1}(:,9)));
                num_single_units = max(0, size(siteData{3},2)-1);
                if ~isempty(Fbeep) && ~isempty(Ffix) && num_single_units > 0
                    for uu = 1:num_single_units
                        legacy_unit_counter = legacy_unit_counter + 1;
                        legacy_unit_map(sprintf('%s|%d', file_key_prefix, uu)) = legacy_unit_counter;
                    end
                end
            end
        catch
            % leave unmapped; processing path will still try to read file
        end
        try
            [b,fk] = process_site_file(s.base_dir, fname, s.monkey);
            if ~isempty(b)
                b.legacy_unit_id = NaN(height(b),1);
                for ii = 1:height(b)
                    key = sprintf('%s|%s|%d', b.monkey{ii}, b.session_file{ii}, b.unit(ii));
                    if isKey(legacy_unit_map, key)
                        b.legacy_unit_id(ii) = legacy_unit_map(key);
                    end
                end
                all_beep = [all_beep; b];
            end
            if ~isempty(fk)
                fk.legacy_unit_id = NaN(height(fk),1);
                for ii = 1:height(fk)
                    key = sprintf('%s|%s|%d', fk.monkey{ii}, fk.session_file{ii}, fk.unit(ii));
                    if isKey(legacy_unit_map, key)
                        fk.legacy_unit_id(ii) = legacy_unit_map(key);
                    end
                end
                all_fix = [all_fix; fk];
            end
        catch ME
            % include full report to aid debugging
            rpt = getReport(ME,'extended','hyperlinks','off');
            warning('process_site_file failed for %s:\n%s', fname, rpt);
        end
    end
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
