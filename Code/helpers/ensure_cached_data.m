function outputs = ensure_cached_data(paths, options)
% ENSURE_CACHED_DATA  Ensure cached data exists by running compute_data.
% outputs = ensure_cached_data(paths, options)

if nargin < 1 || isempty(paths)
    if exist('config_paths.m','file')
        paths = config_paths();
    else
        error('Paths not provided and config_paths.m not found.');
    end
end
if nargin < 2
    options = struct();
end

outputs = compute_data(paths, options);
end
