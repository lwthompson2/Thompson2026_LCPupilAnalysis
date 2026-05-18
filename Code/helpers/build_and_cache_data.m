function outputs = build_and_cache_data(paths, force)
% BUILD_AND_CACHE_DATA  Convenience wrapper to build and cache data.
% outputs = build_and_cache_data(paths, force)

if nargin < 1 || isempty(paths)
    if exist('config_paths.m','file')
        paths = config_paths();
    else
        error('Paths not provided and config_paths.m not found.');
    end
end
if nargin < 2
    force = false;
end

options = struct('force', logical(force));
outputs = compute_data(paths, options);
end
