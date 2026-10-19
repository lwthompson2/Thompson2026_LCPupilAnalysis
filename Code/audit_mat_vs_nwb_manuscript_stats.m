function ok = audit_mat_vs_nwb_manuscript_stats(paths)
% AUDIT_MAT_VS_NWB_MANUSCRIPT_STATS
% Run manuscript stats from MAT and NWB sources and require exact text match.

if nargin < 1 || isempty(paths)
    paths = config_paths();
end

if ~isfield(paths, 'results_dir') || isempty(paths.results_dir)
    error('paths.results_dir is required');
end

if ~exist(paths.results_dir, 'dir')
    mkdir(paths.results_dir);
end

mat_txt_path = fullfile(paths.results_dir, 'manuscript_stats_mat.txt');
nwb_txt_path = fullfile(paths.results_dir, 'manuscript_stats_nwb.txt');

disp('Running MAT-source stats...');
compute_data(paths, struct('force', true, 'source', 'mat', 'manuscript_filter', true));
mat_txt = evalc('compute_manuscript_stats(paths);');
write_text(mat_txt_path, mat_txt);

disp('Running NWB-source stats...');
compute_data(paths, struct('force', true, 'source', 'nwb', 'manuscript_filter', true));
nwb_txt = evalc('compute_manuscript_stats(paths);');
write_text(nwb_txt_path, nwb_txt);

ok = strcmp(mat_txt, nwb_txt);
if ok
    fprintf('PASS: MAT and NWB manuscript stats are exactly identical.\n');
else
    mismatch_path = fullfile(paths.results_dir, 'manuscript_stats_mismatch_summary.txt');
    first_diff = first_diff_index(mat_txt, nwb_txt);
    summary = sprintf(['FAIL: MAT and NWB manuscript stats differ.\n' ...
        'First differing character index: %d\n' ...
        'MAT output: %s\nNWB output: %s\n'], ...
        first_diff, mat_txt_path, nwb_txt_path);
    write_text(mismatch_path, summary);
    error('%s', summary);
end

end

function write_text(p, txt)
fid = fopen(p, 'w');
if fid < 0
    error('Could not open %s for writing', p);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', txt);
end

function idx = first_diff_index(a, b)
na = numel(a);
nb = numel(b);
n = min(na, nb);
idx = n + 1;
for i = 1:n
    if a(i) ~= b(i)
        idx = i;
        return
    end
end
if na == nb
    idx = 0;
end
end
