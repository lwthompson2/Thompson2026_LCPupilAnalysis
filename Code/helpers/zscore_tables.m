function ztabs = zscore_tables(tabs)
% ZSCORE_TABLES  Return tables with legacy spike z-scoring only.
% ztabs = zscore_tables(tabs)

% tabs is a struct with fields 'beep' and 'fix' containing tables.
% Only spike-rate columns are transformed using per-unit z-scoring across:
%   [beep baseline, beep evoked(raw), fix baseline]
% This mirrors legacy do_zscore=true behavior while keeping all non-spike
% columns unchanged.
ztabs = struct();
if ~isfield(tabs,'beep') || ~istable(tabs.beep), ztabs.beep = []; else, ztabs.beep = tabs.beep; end
if ~isfield(tabs,'fix') || ~istable(tabs.fix), ztabs.fix = []; else, ztabs.fix = tabs.fix; end

if isempty(ztabs.beep) || isempty(ztabs.fix)
    return
end

Tb = ztabs.beep;
Tf = ztabs.fix;

if ~ismember('unit', Tb.Properties.VariableNames)
    % No per-unit key available; keep tables unchanged.
    ztabs.beep = Tb;
    ztabs.fix = Tf;
    return
end

if ~ismember('spike_baseline', Tb.Properties.VariableNames)
    ztabs.beep = Tb;
    ztabs.fix = Tf;
    return
end

if ~ismember('spike_evoked', Tb.Properties.VariableNames) && ~ismember('spike_bs_evoked', Tb.Properties.VariableNames)
    ztabs.beep = Tb;
    ztabs.fix = Tf;
    return
end

% Normalize fix baseline column naming for assignment.
if ~ismember('spike_fix_baseline', Tf.Properties.VariableNames) && ismember('spike_baseline', Tf.Properties.VariableNames)
    Tf.spike_fix_baseline = Tf.spike_baseline;
end

units = unique(Tb.unit);
for u = units(:)'
    idx_b = Tb.unit == u;
    idx_f = false(height(Tf),1);
    if ismember('unit', Tf.Properties.VariableNames)
        idx_f = Tf.unit == u;
    end

    b_base = Tb.spike_baseline(idx_b);
    if ismember('raw_spike_evoked', Tb.Properties.VariableNames)
        b_ev_raw = Tb.raw_spike_evoked(idx_b);
    elseif ismember('spike_evoked', Tb.Properties.VariableNames)
        b_ev_raw = Tb.spike_baseline(idx_b) + Tb.spike_evoked(idx_b);
    else
        b_ev_raw = Tb.spike_baseline(idx_b) + Tb.spike_bs_evoked(idx_b);
    end

    if ismember('spike_fix_baseline', Tf.Properties.VariableNames)
        f_base = Tf.spike_fix_baseline(idx_f);
    else
        f_base = Tf.spike_baseline(idx_f);
    end

    all_fr = [b_base; b_ev_raw; f_base];
    all_fr_z = nan(size(all_fr));
    valid = isfinite(all_fr);
    if any(valid)
        all_fr_z(valid) = zscore(all_fr(valid));
    end

    n_b = sum(idx_b);
    n_f = sum(idx_f);
    b_base_z = all_fr_z(1:n_b);
    b_ev_raw_z = all_fr_z(n_b + (1:n_b));
    if n_f > 0
        f_base_z = all_fr_z((2*n_b) + (1:n_f));
    else
        f_base_z = [];
    end

    Tb.spike_baseline(idx_b) = b_base_z;
    if ismember('spike_evoked', Tb.Properties.VariableNames)
        Tb.spike_evoked(idx_b) = b_ev_raw_z - b_base_z;
    end
    if ismember('spike_bs_evoked', Tb.Properties.VariableNames)
        Tb.spike_bs_evoked(idx_b) = b_ev_raw_z - b_base_z;
    end
    if ismember('raw_spike_evoked', Tb.Properties.VariableNames)
        Tb.raw_spike_evoked(idx_b) = b_ev_raw_z;
    end

    if n_f > 0
        if ismember('spike_fix_baseline', Tf.Properties.VariableNames)
            Tf.spike_fix_baseline(idx_f) = f_base_z;
        end
        if ismember('spike_baseline', Tf.Properties.VariableNames)
            Tf.spike_baseline(idx_f) = f_base_z;
        end
    end
end

ztabs.beep = Tb;
ztabs.fix = Tf;
end
