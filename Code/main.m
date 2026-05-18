cd('/Users/lowell/Documents/GitHub/LCPupil_Joshi_Analysis/Code');
addpath(genpath(pwd));
paths = config_paths();           % must exist and have results_dir
outputs = compute_data(paths, struct('force', true));  % force rebuild           % create cached MATs
make_all_figures();              % generates PDFs and logs progress
compute_manuscript_stats(paths); % prints manuscript stats for validation