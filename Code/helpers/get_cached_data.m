function data = get_cached_data(paths)
% GET_CACHED_DATA  Load cached LC/pupil tables if present.
%  data = get_cached_data(paths)

if nargin < 1 || isempty(paths)
    if exist('config_paths.m','file')
        paths = config_paths();
    else
        error('Paths not provided and config_paths.m not found.');
    end
end

results_dir = paths.results_dir;
data = struct();
raw_mat = fullfile(results_dir, 'LC_data_raw.mat');
z_mat = fullfile(results_dir, 'LC_data_zscored.mat');

if exist(raw_mat, 'file')
    s = load(raw_mat);
    data.raw = s;
else
    data.raw = [];
end

if exist(z_mat, 'file')
    s = load(z_mat);
    data.z = s;
else
    data.z = [];
end
end
