function save_cached_tables(results_dir, raw_tables, z_tables, processing_version)
% SAVE_CACHED_TABLES  Save raw and z-scored tables to results_dir
if ~exist(results_dir,'dir')
    mkdir(results_dir);
end
if nargin < 4 || isempty(processing_version)
    processing_version = 'unknown';
end
raw_mat = fullfile(results_dir,'LC_data_raw.mat');
z_mat = fullfile(results_dir,'LC_data_zscored.mat');
if ~isempty(raw_tables)
    LC_Beep_table = raw_tables.beep; %#ok<NASGU>
    LC_Fix_table = raw_tables.fix; %#ok<NASGU>
    save(raw_mat,'LC_Beep_table','LC_Fix_table','processing_version','-v7.3');
end
if ~isempty(z_tables)
    LC_Beep_table = z_tables.beep; %#ok<NASGU>
    LC_Fix_table = z_tables.fix; %#ok<NASGU>
    save(z_mat,'LC_Beep_table','LC_Fix_table','processing_version','-v7.3');
end
end
