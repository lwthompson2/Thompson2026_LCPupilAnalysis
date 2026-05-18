function [beep_tbl, fix_tbl] = process_site_file(base_dir, fname, monkey)
% PROCESS_SITE_FILE  Extract per-unit trial summaries from a cleaned site file
% [beep_tbl, fix_tbl] = process_site_file(base_dir, fname, monkey)

% Default times (match legacy code)
times = [-100 0; 0 800; -400 0; 0 200];
pupil_evoked_times = times(2,1):times(2,2);

beep_tbl = table();
fix_tbl = table();
if nargin < 2 || isempty(fname)
    return
end

function vec = extract_pupil_vector(sd2, trialIdx, fieldIdx)
% Try multiple common indexing patterns to extract a time series vector for
% a given trial and candidate field index. Returns [] if no valid vector
% could be extracted.
vec = [];
if isempty(sd2)
    return
end
try
    % Pattern 1: sd2(trial, :, field)
    if ndims(sd2) >= 3 && size(sd2,1) >= trialIdx && size(sd2,3) >= fieldIdx
        tmp = squeeze(sd2(trialIdx, :, fieldIdx));
        if isvector(tmp) && numel(tmp) > 1
            vec = tmp;
            return
        end
    end
    % Pattern 2: sd2(trial, field, :)
    if ndims(sd2) >= 3 && size(sd2,1) >= trialIdx && size(sd2,2) >= fieldIdx
        tmp = squeeze(sd2(trialIdx, fieldIdx, :));
        if isvector(tmp) && numel(tmp) > 1
            vec = tmp;
            return
        end
    end
    % Pattern 3: sd2(trial, :)
    if size(sd2,1) >= trialIdx && size(sd2,2) > 1
        tmp = squeeze(sd2(trialIdx, :));
        if isvector(tmp) && numel(tmp) > 1
            vec = tmp;
            return
        end
    end
    % Pattern 4: sd2(:, trial)
    if size(sd2,2) >= trialIdx && size(sd2,1) > 1
        tmp = squeeze(sd2(:, trialIdx));
        if isvector(tmp) && numel(tmp) > 1
            vec = tmp;
            return
        end
    end
catch
    vec = [];
end
end
try
    s = load(fullfile(base_dir, fname));
    siteData = s.siteData;
catch ME
    warning('Failed to load %s: %s', fullfile(base_dir,fname), ME.message);
    return
end

% Validate siteData structure
if ~iscell(siteData) || numel(siteData) < 3
    warning('Unexpected siteData format in %s', fname);
    return
end

% safe size helpers for pupil matrix
sz2 = size(siteData{2});

% find valid beep/fix trials using legacy-like criteria, guarded
try
    ncol = sz2(2);
catch
    ncol = 0;
end
Fbeep = find(siteData{1}(:,3)==1 & siteData{1}(:,4)>abs(min(times(:,1))) );
% further filter beeps if pupil data length is available
if ncol > 0
    Fbeep = Fbeep(siteData{1}(Fbeep,4) < ncol - max(times(:,2)));
end
Ffix = find(siteData{1}(:,3)==1 & isnan(siteData{1}(:,4)) & isnan(siteData{1}(:,9)));
num_single_units = max(0, size(siteData{3},2)-1);

if isempty(Fbeep) && isempty(Ffix)
    return
end

% Follow original getData.m behavior: compute pupil baseline/evoked using
% value channel (field 4), compute raw spike rates, apply legacy trial
% filtering masks, then append rows to output tables.
if ~isempty(Fbeep) && ~isempty(Ffix) && num_single_units > 0
    nb = numel(Fbeep);
    nf = numel(Ffix);
    % Preallocate arrays
    pupil_data = nan(nb,2); % [baseline, evoked]
    pupil_fix_data = nan(nf,1);
    spike_data = nan(nb,2,num_single_units);
    spike_fix_data = nan(nf,num_single_units);
    trial_times = nan(nb,1);
    trial_fix_times = nan(nf,1);
    baseline_times = nan(nb, num_single_units);

    % Gather beep-trial pupil and spike counts
    for bb = 1:nb
        bt = Fbeep(bb);
        beep_time = siteData{1}(bt,4);
        trial_times(bb) = siteData{1}(bt,7);
        bi = round(beep_time) + 1; % match getData.m indexing

        % pupil value channel (field 4) preferred
        pd = extract_pupil_vector(siteData{2}, bt, 4);
        if ~isempty(pd)
            % baseline: mean from fix onset to beep (samples 1:bi)
            bi_idx = min(numel(pd), bi);
            pupil_data(bb,1) = mean(pd(1:bi_idx), 'omitnan');
            % evoked: running mean of baseline-subtracted evoked window
            ev_idx = bi + pupil_evoked_times;
            ev_idx = ev_idx(ev_idx >= 1 & ev_idx <= numel(pd));
            if ~isempty(ev_idx)
                sm = movmean(pd(ev_idx) - pupil_data(bb,1), 50, 'omitnan');
                if isempty(sm)
                    pupil_data(bb,2) = NaN;
                else
                    max_evoked = max(sm);
                    min_evoked = min(sm);
                    if abs(max_evoked) > abs(min_evoked)
                        pupil_data(bb,2) = max_evoked;
                    else
                        pupil_data(bb,2) = min_evoked;
                    end
                end
            else
                pupil_data(bb,2) = NaN;
            end
        else
            pupil_data(bb,:) = [NaN NaN];
        end

        % spikes per unit
        for uu = 1:num_single_units
            sp = [];
            try
                if iscell(siteData{3}) && size(siteData{3},1) >= bt && size(siteData{3},2) >= uu+1
                    sp = siteData{3}{bt, uu+1};
                end
            catch
                sp = [];
            end
            % Legacy behavior: empty spike vector yields zero counts
            % (sum on empty logical arrays returns 0), not NaN.
            if isempty(sp)
                baseline_count = 0;
                evoked_count = 0;
            else
                % baseline uses whole period up to beep (new method in getData)
                baseline_count = sum(sp >= 0 & sp < beep_time + times(3,2));
                % evoked window
                evoked_count = sum(sp >= beep_time + times(4,1) & sp <= beep_time + times(4,2));
            end
            spike_data(bb,1,uu) = baseline_count;
            spike_data(bb,2,uu) = evoked_count;
            baseline_times(bb,uu) = beep_time;
        end
    end

    % Gather fix-trial pupil and spike counts
    for bb = 1:nf
        ft = Ffix(bb);
        end_time = siteData{1}(ft,2);
        trial_fix_times(bb) = siteData{1}(ft,7);
        fix_times = 0:round(end_time);

        pd = extract_pupil_vector(siteData{2}, ft, 4);
        if ~isempty(pd)
            idx = 1 + fix_times;
            idx = idx(idx >= 1 & idx <= numel(pd));
            if ~isempty(idx)
                pupil_fix_data(bb) = mean(pd(idx), 'omitnan');
            else
                pupil_fix_data(bb) = NaN;
            end
        else
            pupil_fix_data(bb) = NaN;
        end

        for uu = 1:num_single_units
            sp = [];
            try
                if iscell(siteData{3}) && size(siteData{3},1) >= ft && size(siteData{3},2) >= uu+1
                    sp = siteData{3}{ft, uu+1};
                end
            catch
                sp = [];
            end
            % Legacy behavior: empty spike vector yields zero baseline count.
            if isempty(sp)
                baseline_count = 0;
            else
                baseline_count = sum(sp >= 0 & sp <= end_time);
            end
            spike_fix_data(bb,uu) = baseline_count;
        end
    end

    % Convert counts to rates (ms -> Hz scaling consistent with getData)
    spike_rate_data = nan(size(spike_data)); % same shape nb x 2 x units
    spike_rate_fix = nan(size(spike_fix_data));
    for uu = 1:num_single_units
        % baseline rate: divide by baseline_times (ms) then *1000
        denom = baseline_times(:,uu);
        valid = denom > 0 & ~isnan(spike_data(:,1,uu));
        spike_rate_data(valid,1,uu) = spike_data(valid,1,uu) ./ denom(valid) .* 1000;
        % evoked rate: divide by evoked window duration
        ev_dur = diff(times(4,:));
        valid_ev = ~isnan(spike_data(:,2,uu));
        spike_rate_data(valid_ev,2,uu) = spike_data(valid_ev,2,uu) ./ ev_dur .* 1000;
        % fix trial baseline rates
        for ff = 1:nf
            if ~isnan(spike_fix_data(ff,uu)) && isfinite(siteData{1}(Ffix(ff),2))
                spike_rate_fix(ff,uu) = spike_fix_data(ff,uu) ./ siteData{1}(Ffix(ff),2) .* 1000;
            else
                spike_rate_fix(ff,uu) = NaN;
            end
        end
    end

    % Build masks for filtering trials (legacy Lg/Lg_fix behavior)
    % NOTE: z-scoring is NOT applied here; it happens later in zscore_tables.m
    % This ensures consistency with legacy getData.m behavior:
    % - Raw data is returned by process_site_file
    % - Z-scoring is applied per-unit on the filtered data in zscore_tables
    evoked_z_thresh = 8;
    for uu = 1:num_single_units
        % Build z-scored spike rates per unit from the full distribution:
        %   [beep baseline, beep evoked(raw), fix baseline]
        % and apply threshold on abs(z) of evoked beep trials.
        b_base_raw = spike_rate_data(:,1,uu);
        b_ev_raw = spike_rate_data(:,2,uu);
        f_base_raw = spike_rate_fix(:,uu);
        all_fr_raw = [b_base_raw; b_ev_raw; f_base_raw];
        all_fr_z = nan(size(all_fr_raw));
        valid_all = isfinite(all_fr_raw);
        if any(valid_all)
            all_fr_z(valid_all) = zscore(all_fr_raw(valid_all));
        end
        n_b = numel(b_base_raw);
        evoked_z = all_fr_z(n_b + (1:n_b));

        Lg = isfinite(spike_rate_data(:,1,uu)) & isfinite(pupil_data(:,1)) & isfinite(pupil_data(:,2)) & isfinite(evoked_z) & (abs(evoked_z) < evoked_z_thresh);
        Lg_fix = isfinite(spike_rate_fix(:,uu)) & isfinite(pupil_fix_data);

        % Make evoked be baseline-subtracted (evoked - baseline)
        % This is done on RAW firing rates before z-scoring
        validEv = ~isnan(spike_rate_data(:,2,uu)) & ~isnan(spike_rate_data(:,1,uu));
        spike_rate_data(validEv,2,uu) = spike_rate_data(validEv,2,uu) - spike_rate_data(validEv,1,uu);
        nLg = sum(Lg);
        nLg_fix = sum(Lg_fix);
        if nLg == 0 && nLg_fix == 0
            continue
        end

        % compute drifts across filtered trials only (legacy behavior)
        all_times = [trial_times(Lg); trial_fix_times(Lg_fix)];
        all_pd = [pupil_data(Lg,1); pupil_fix_data(Lg_fix)];
        all_fr = [squeeze(spike_rate_data(Lg,1,uu)); spike_rate_fix(Lg_fix,uu)];
        pupil_drift_res = NaN(nLg + nLg_fix,1);
        spike_drift_res = NaN(nLg + nLg_fix,1);
        if numel(all_times) >= 2 && any(isfinite(all_pd))
            try
                mdl = fitlm(all_times, all_pd);
                pupil_drift_res = mdl.Residuals.Raw;
            catch
            end
        end
        if numel(all_times) >= 2 && any(isfinite(all_fr))
            try
                mdl2 = fitlm(all_times, all_fr);
                spike_drift_res = mdl2.Residuals.Raw;
            catch
            end
        end

        % Beep table rows (filtered by Lg)
        if nLg > 0
            pupil_baseline = pupil_data(Lg,1);
            pupil_evoked = pupil_data(Lg,2); % baseline-subtracted evoked pupil
            spike_baseline = spike_rate_data(Lg,1,uu); % firing rates
            spike_evoked = spike_rate_data(Lg,2,uu);   % baseline-subtracted evoked FR
            T = table(repmat({monkey},nLg,1), repmat({fname},nLg,1), repmat(uu,nLg,1), trial_times(Lg), pupil_baseline, pupil_evoked, spike_baseline, spike_evoked, ...
                'VariableNames', {'monkey','session_file','unit','trial_time','pupil_baseline','pupil_evoked','spike_baseline','spike_evoked'});
            T.pupil_drift_residuals = pupil_drift_res(1:nLg);
            T.spike_drift_residuals = spike_drift_res(1:nLg);
            T.raw_pupil_evoked = pupil_baseline + pupil_evoked;
            T.raw_spike_evoked = spike_baseline + spike_evoked;
            beep_tbl = [beep_tbl; T]; %#ok<AGROW>
        end

        % Fix table rows (filtered by Lg_fix) and stored as firing rates
        if nLg_fix > 0
            Tfix = table(repmat({monkey},nLg_fix,1), repmat({fname},nLg_fix,1), repmat(uu,nLg_fix,1), pupil_fix_data(Lg_fix), spike_rate_fix(Lg_fix,uu), trial_fix_times(Lg_fix), ...
                'VariableNames', {'monkey','session_file','unit','pupil_fix_baseline','spike_fix_baseline','trial_time'});
            Tfix.pupil_drift_residuals = pupil_drift_res(nLg + (1:nLg_fix));
            Tfix.spike_drift_residuals = spike_drift_res(nLg + (1:nLg_fix));
            fix_tbl = [fix_tbl; Tfix]; %#ok<AGROW>
        end
    end
end
end
