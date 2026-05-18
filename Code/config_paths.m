function paths = config_paths()
% CONFIG_PATHS  Default configuration for dataset paths and outputs.
% Edit this file to match your environment if needed.

    % Path to root folder containing the raw .mat data (Box location you provided)
    % e.g. '/Users/lowell/Library/CloudStorage/Box-Box/GoldLab/Data/Physiology/PD_Fixation/Recording'
    paths.data_root = '/Users/lowell/Library/CloudStorage/Box-Box/GoldLab/Data/Physiology/PD_Fixation/Recording';

    % Output directory for paper figures (PDF). These will be created if missing.
    repo_root = fileparts(mfilename('fullpath'));
    paths.output_figures = fullfile(repo_root, 'Figures', 'Paper');

    % Directory for intermediate results / cached stats (optional)
    paths.results_dir = fullfile(repo_root, 'Results');

    % Default monkey names used in the repo (may be overridden by getData)
    paths.monkeys = {'Cicero','Oz'};
end
