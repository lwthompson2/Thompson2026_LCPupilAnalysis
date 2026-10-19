function [dir_, fnames_] = getLCP_cleanDataDir_core(monkey, site)
% GETLCP_CLEANDATADIR_CORE  Resolve cleaned LC-pupil data directories.
% [dir_, fnames_] = getLCP_cleanDataDir_core(monkey, site)

if nargin < 1 || isempty(monkey)
    error('monkey is required');
end
if nargin < 2 || isempty(site)
    site = 'LC';
end

paths = config_paths();
if ~isfield(paths, 'data_root') || isempty(paths.data_root)
    error('config_paths().data_root is required to locate cleaned data files.');
end

dir_ = fullfile(paths.data_root, monkey, site, 'clean');
if nargout > 1
    D = dir(fullfile(dir_, '*.mat'));
    fnames_ = {D.name};
end
end
