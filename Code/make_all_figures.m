function make_all_figures()
% MAKE_ALL_FIGURES  Run the figure wrappers in order and log progress.
try
    addpath(genpath(fileparts(mfilename('fullpath'))));
catch
end
paths = config_paths();
% Ensure results dir exists
if ~isfield(paths,'results_dir') || isempty(paths.results_dir)
    repo_root = fileparts(mfilename('fullpath'));
    paths.results_dir = fullfile(repo_root, 'Results');
end
if ~exist(paths.results_dir,'dir')
    mkdir(paths.results_dir);
end

logpath = fullfile(paths.results_dir, 'make_figures.log');
% open for append; create file if it doesn't exist
logfid = fopen(logpath,'a');
if logfid == -1
    error('Could not open log file %s for writing', logpath);
end
fprintf(logfid, 'Starting figure generation: %s\n', datestr(now));
try
    fprintf(logfid, 'Figure 2: examples...\n');
    Figure_02_examples(paths);
    fprintf(logfid, 'Figure 2 done.\n');

    fprintf(logfid, 'Figure S2: LLR...\n');
    Figure_S2_LLR(paths);
    fprintf(logfid, 'Figure S2 done.\n');

    fprintf(logfid, 'Figure 3: pooled...\n');
    Figure_03_pooled(paths);
    fprintf(logfid, 'Figure 3 done.\n');

    fprintf(logfid, 'Figure S1 summary row...\n');
    Figure_S1_summary(paths);
    fprintf(logfid, 'Figure S1 summary done.\n');

    fprintf(logfid, 'Figure S1 combined...\n');
    Figure_S1_combined(paths);
    fprintf(logfid, 'Figure S1 combined done.\n');

    fprintf(logfid, 'Figure S3 subset summary...\n');
    Figure_S3_sig_baseline_subset(paths);
    fprintf(logfid, 'Figure S3 subset summary done.\n');

    fprintf(logfid, 'Figure S4 range impact...\n');
    Figure_S4_range_impact(paths);
    fprintf(logfid, 'Figure S4 range impact done.\n');

    fprintf(logfid, 'All figures complete: %s\n', datestr(now));

catch ME
    fprintf(logfid, 'Error: %s\n', ME.message);
    rethrow(ME);
end
fclose(logfid);
end
