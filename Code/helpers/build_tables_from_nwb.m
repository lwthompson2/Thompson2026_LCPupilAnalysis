function [beep_tbl, fix_tbl] = build_tables_from_nwb(paths)
% BUILD_TABLES_FROM_NWB  Reconstruct analysis tables from DANDI NWB files using MATLAB only.

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
matnwb_root = fullfile(repo_root, 'external', 'matnwb');
if ~isfolder(matnwb_root)
    error('MatNWB not found at %s. Install it before using NWB source.', matnwb_root);
end
addpath(genpath(matnwb_root));

nwb_files = dir(fullfile(paths.nwb_root, '**', '*.nwb'));
beep_tbl = table();
fix_tbl = table();

for k = 1:numel(nwb_files)
    fpath = fullfile(nwb_files(k).folder, nwb_files(k).name);
    [b, f] = process_single_nwb_file(fpath);
    if ~isempty(b)
        beep_tbl = [beep_tbl; b]; %#ok<AGROW>
    end
    if ~isempty(f)
        fix_tbl = [fix_tbl; f]; %#ok<AGROW>
    end
end

if ~isempty(beep_tbl)
    if isstring(beep_tbl.monkey), beep_tbl.monkey = cellstr(beep_tbl.monkey); end
    if isstring(beep_tbl.session_file), beep_tbl.session_file = cellstr(beep_tbl.session_file); end
end
if ~isempty(fix_tbl)
    if isstring(fix_tbl.monkey), fix_tbl.monkey = cellstr(fix_tbl.monkey); end
    if isstring(fix_tbl.session_file), fix_tbl.session_file = cellstr(fix_tbl.session_file); end
end

end

function [beep_tbl, fix_tbl] = process_single_nwb_file(nwb_path)
% Mirrors process_site_file.m logic as closely as possible.

beep_tbl = table();
fix_tbl = table();

times = [-100 0; 0 800; -400 0; 0 200];
pupil_evoked_times = times(2,1):times(2,2);

nwb = nwbRead(nwb_path);

monkey = char(nwb.general_subject.subject_id);
session_file = [char(nwb.general_session_id) '.mat'];

trials = nwb.intervals_trials.toTable();
if isempty(trials)
    return
end

n_trials = height(trials);
correct = double(trials.correct);
beep_ms = double(trials.beep_time_ms);
trial_time_idx = double(trials.trial_time_index);

if ismember('stimulation_marker', trials.Properties.VariableNames)
    stim = double(trials.stimulation_marker);
else
    stim = nan(n_trials,1);
end

start_t = double(trials.start_time);
stop_t = double(trials.stop_time);
end_ms = (stop_t - start_t) * 1000;

if ~isKey(nwb.acquisition, 'pupil_value_channel4')
    return
end
pupil_flat = double(nwb.acquisition.get('pupil_value_channel4').data.load());
if mod(numel(pupil_flat), n_trials) ~= 0
    return
end
ncol = numel(pupil_flat) / n_trials;
% MAT->NWB conversion flattened [trial x time] in Python (row-major order).
% Reconstruct in MATLAB accordingly to recover the original trial rows.
pupil_mat = reshape(pupil_flat, [ncol, n_trials])';

Fbeep = find(correct == 1 & beep_ms > abs(min(times(:,1))) & beep_ms < (ncol - max(times(:,2))));
Ffix = find(correct == 1 & isnan(beep_ms) & isnan(stim));
if isempty(Fbeep) && isempty(Ffix)
    return
end

if isempty(nwb.units)
    return
end

units_tbl = nwb.units.toTable();
if isempty(units_tbl) || ~ismember('source_unit_index', units_tbl.Properties.VariableNames)
    return
end

units_tbl = sortrows(units_tbl, 'source_unit_index');

for ui = 1:height(units_tbl)
    src_idx = double(units_tbl.source_unit_index(ui));
    local_unit = src_idx - 1;
    spike_times = double(units_tbl.spike_times{ui});

    nb = numel(Fbeep);
    nf = numel(Ffix);
    pupil_data = nan(nb,2);
    pupil_fix_data = nan(nf,1);
    spike_data = nan(nb,2);
    spike_fix_data = nan(nf,1);
    trial_times = nan(nb,1);
    trial_fix_times = nan(nf,1);
    baseline_times = nan(nb,1);

    for bi = 1:nb
        bt = Fbeep(bi);
        trial_anchor = start_t(bt);
        bt_ms = beep_ms(bt);
        trial_times(bi) = trial_time_idx(bt);

        idx_bi = min(ncol, round(bt_ms) + 1);
        if idx_bi >= 1
            pupil_data(bi,1) = mean(pupil_mat(bt,1:idx_bi), 'omitnan');
        end

        ev_idx = round(bt_ms) + pupil_evoked_times + 1;
        ev_idx = ev_idx(ev_idx >= 1 & ev_idx <= ncol);
        if ~isempty(ev_idx) && isfinite(pupil_data(bi,1))
            ev = pupil_mat(bt,ev_idx) - pupil_data(bi,1);
            sm = movmean(ev, 50, 'omitnan');
            max_ev = max(sm);
            min_ev = min(sm);
            if abs(max_ev) > abs(min_ev)
                pupil_data(bi,2) = max_ev;
            else
                pupil_data(bi,2) = min_ev;
            end
        end

        spike_data(bi,1) = sum(spike_times >= trial_anchor & spike_times < trial_anchor + bt_ms/1000);
        spike_data(bi,2) = sum(spike_times >= trial_anchor + (bt_ms + times(4,1))/1000 & ...
                              spike_times <= trial_anchor + (bt_ms + times(4,2))/1000);
        baseline_times(bi) = bt_ms;
    end

    for fi = 1:nf
        ft = Ffix(fi);
        trial_anchor = start_t(ft);
        t_end = end_ms(ft);
        trial_fix_times(fi) = trial_time_idx(ft);

        idx = 1:(round(t_end)+1);
        idx = idx(idx >= 1 & idx <= ncol);
        if ~isempty(idx)
            pupil_fix_data(fi) = mean(pupil_mat(ft, idx), 'omitnan');
        end

        spike_fix_data(fi) = sum(spike_times >= trial_anchor & spike_times <= trial_anchor + t_end/1000);
    end

    spike_rate_base = nan(nb,1);
    spike_rate_ev = nan(nb,1);
    spike_rate_fix = nan(nf,1);

    Lb = baseline_times > 0 & isfinite(spike_data(:,1));
    spike_rate_base(Lb) = spike_data(Lb,1) ./ baseline_times(Lb) * 1000;

    ev_dur = diff(times(4,:));
    Le = isfinite(spike_data(:,2));
    spike_rate_ev(Le) = spike_data(Le,2) ./ ev_dur * 1000;

    for fi = 1:nf
        ft = Ffix(fi);
        if isfinite(spike_fix_data(fi)) && isfinite(end_ms(ft)) && end_ms(ft) > 0
            spike_rate_fix(fi) = spike_fix_data(fi) ./ end_ms(ft) * 1000;
        end
    end

    all_fr = [spike_rate_base; spike_rate_ev; spike_rate_fix];
    all_fr_z = nan(size(all_fr));
    V = isfinite(all_fr);
    if any(V)
        all_fr_z(V) = zscore(all_fr(V));
    end
    evoked_z = all_fr_z(nb + (1:nb));

    Lg = isfinite(spike_rate_base) & isfinite(pupil_data(:,1)) & isfinite(pupil_data(:,2)) & isfinite(evoked_z) & abs(evoked_z) < 8;
    Lg_fix = isfinite(spike_rate_fix) & isfinite(pupil_fix_data);

    validEv = isfinite(spike_rate_ev) & isfinite(spike_rate_base);
    spike_rate_ev(validEv) = spike_rate_ev(validEv) - spike_rate_base(validEv);

    nLg = sum(Lg);
    nLg_fix = sum(Lg_fix);
    if nLg == 0 && nLg_fix == 0
        continue
    end

    all_times = [trial_times(Lg); trial_fix_times(Lg_fix)];
    all_pd = [pupil_data(Lg,1); pupil_fix_data(Lg_fix)];
    all_fr2 = [spike_rate_base(Lg); spike_rate_fix(Lg_fix)];

    pd_res = nan(nLg + nLg_fix,1);
    fr_res = nan(nLg + nLg_fix,1);
    if numel(all_times) >= 2 && any(isfinite(all_pd))
        try
            mdl = fitlm(all_times, all_pd);
            pd_res = mdl.Residuals.Raw;
        catch
        end
    end
    if numel(all_times) >= 2 && any(isfinite(all_fr2))
        try
            mdl2 = fitlm(all_times, all_fr2);
            fr_res = mdl2.Residuals.Raw;
        catch
        end
    end

    if nLg > 0
        pb = pupil_data(Lg,1);
        pe = pupil_data(Lg,2);
        sb = spike_rate_base(Lg);
        se = spike_rate_ev(Lg);
        tt = trial_times(Lg);

        T = table(repmat({monkey},nLg,1), repmat({session_file},nLg,1), repmat(local_unit,nLg,1), tt, pb, pe, sb, se, ...
            'VariableNames', {'monkey','session_file','unit','trial_time','pupil_baseline','pupil_evoked','spike_baseline','spike_evoked'});
        T.pupil_drift_residuals = pd_res(1:nLg);
        T.spike_drift_residuals = fr_res(1:nLg);
        T.raw_pupil_evoked = pb + pe;
        T.raw_spike_evoked = sb + se;
        beep_tbl = [beep_tbl; T]; %#ok<AGROW>
    end

    if nLg_fix > 0
        pfix = pupil_fix_data(Lg_fix);
        sfix = spike_rate_fix(Lg_fix);
        tfix = trial_fix_times(Lg_fix);

        Tfix = table(repmat({monkey},nLg_fix,1), repmat({session_file},nLg_fix,1), repmat(local_unit,nLg_fix,1), pfix, sfix, tfix, ...
            'VariableNames', {'monkey','session_file','unit','pupil_fix_baseline','spike_fix_baseline','trial_time'});
        Tfix.pupil_drift_residuals = pd_res(nLg + (1:nLg_fix));
        Tfix.spike_drift_residuals = fr_res(nLg + (1:nLg_fix));
        fix_tbl = [fix_tbl; Tfix]; %#ok<AGROW>
    end
end

end
