%% Debug legacy unit counter mapping
% Shows which files contribute to which unit IDs

clear all; close all;

fprintf('=== LEGACY UNIT ID MAPPING DEBUG ===\n\n');

% Replicate the legacy unit counter logic from compute_data.m
sites = load_site_list();
legacy_unit_counter = 0;
legacy_unit_map_debug = containers.Map('KeyType','char','ValueType','double');

fprintf('Building legacy unit map:\n');
fprintf('=========================\n\n');

for si = 1:numel(sites)
    s = sites(si);
    if isempty(s.base_dir) || isempty(s.fnames)
        continue;
    end
    fprintf('Monkey: %s\n', s.monkey);
    
    for f = 1:numel(s.fnames)
        fname = s.fnames{f};
        file_key_prefix = sprintf('%s|%s', s.monkey, fname);
        
        try
            tmp = load(fullfile(s.base_dir, fname), 'siteData');
            if isfield(tmp, 'siteData') && iscell(tmp.siteData) && numel(tmp.siteData) >= 3
                siteData = tmp.siteData;
                times = [-100 0; 0 800; -400 0; 0 200];
                
                Fbeep = find(siteData{1}(:,3)==1 & ...
                    siteData{1}(:,4)>abs(min(times(:,1))) & ...
                    siteData{1}(:,4)<size(siteData{2},2)-max(times(:,2)));
                Ffix = find(siteData{1}(:,3)==1 & ...
                    isnan(siteData{1}(:,4)) & ...
                    isnan(siteData{1}(:,9)));
                num_single_units = max(0, size(siteData{3},2)-1);
                
                % This is the gate from compute_data.m
                if ~isempty(Fbeep) && ~isempty(Ffix) && num_single_units > 0
                    units_start = legacy_unit_counter + 1;
                    for uu = 1:num_single_units
                        legacy_unit_counter = legacy_unit_counter + 1;
                        legacy_unit_map_debug(sprintf('%s|%d', file_key_prefix, uu)) = legacy_unit_counter;
                    end
                    units_end = legacy_unit_counter;
                    fprintf('  %s: %d beeps, %d fixes, %d units -> IDs %d-%d\n', ...
                        fname, numel(Fbeep), numel(Ffix), num_single_units, units_start, units_end);
                    
                    % Track unit 97 specifically
                    if units_start <= 97 && 97 <= units_end
                        unit_97_file = fname;
                        unit_97_local_id = 97 - units_start + 1;
                        fprintf('    *** UNIT 97 is local unit %d in this file ***\n', unit_97_local_id);
                    end
                else
                    fprintf('  %s: SKIPPED (Fbeep=%d, Ffix=%d, units=%d)\n', ...
                        fname, numel(Fbeep), numel(Ffix), num_single_units);
                end
            end
        catch ME
            fprintf('  %s: ERROR - %s\n', fname, ME.message);
        end
    end
    fprintf('\n');
end

fprintf('\nFinal unit counter: %d\n', legacy_unit_counter);
fprintf('Total units mapped: %d\n', legacy_unit_map_debug.Count);

% Check if unit 97 is in the map
key_97 = '';
for key = legacy_unit_map_debug.keys
    k = key{1};
    if legacy_unit_map_debug(k) == 97
        key_97 = k;
        break;
    end
end

if ~isempty(key_97)
    fprintf('\nUnit 97 found in map: %s = 97\n', key_97);
else
    fprintf('\n*** UNIT 97 NOT FOUND IN MAP ***\n');
    fprintf('This explains why it has no data!\n');
end
