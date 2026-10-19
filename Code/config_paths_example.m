function paths = config_paths_example()
% CONFIG_PATHS_EXAMPLE  Example configuration for dataset paths and outputs.
% Copy this file to config_paths.m and edit data_root for your machine.

% Root containing cleaned data folders by monkey, e.g.:
% <data_root>/Oz/LC/clean/*.mat
% <data_root>/Cicero/LC/clean/*.mat
paths.data_root = '/path/to/Recording';

repo_root = fileparts(mfilename('fullpath'));
paths.output_figures = fullfile(repo_root, 'Figures', 'Paper');
paths.results_dir = fullfile(repo_root, 'Results');
paths.monkeys = {'Cicero','Oz'};
end
