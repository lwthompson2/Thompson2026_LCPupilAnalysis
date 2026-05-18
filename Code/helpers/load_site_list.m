function sites = load_site_list(monkeys)
% LOAD_SITE_LIST  Return cleaned data directories and filenames for monkeys
% sites = load_site_list(monkeys)

if nargin < 1 || isempty(monkeys)
    monkeys = {'Oz','Cicero'};
end

sites = struct('monkey',{},'base_dir',{},'fnames',{});
for i = 1:numel(monkeys)
    m = monkeys{i};
    try
        [base_dir, fnames] = getLCP_cleanDataDir(m, 'LC');
    catch
        base_dir = '';
        fnames = {};
    end
    if isempty(fnames)
        fnames = {};
    end
    sites(end+1) = struct('monkey', m, 'base_dir', base_dir, 'fnames', {fnames}); %#ok<AGROW>
end
end
