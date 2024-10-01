function [dir_, fnames_] = getLCP_cleanDataDir(monkey, site)

% dir_ = fullfile(dirnames('local'), 'Data', 'Projects', '2013_LCPupil', ...
%     'Data', 'Recording', monkey, site, 'clean');
% dir_ = fullfile('Users', 'jigold', 'GoldWorks', 'Mirror_jigold', 'Manuscripts', '2016_JoshiEtAl_LCPupil', ...
%    'Data', 'Recording', monkey, site, 'clean');
dir_ = fullfile('/Users', 'lowell', 'Library', 'CloudStorage', 'Box-Box', 'GoldLab', ...
    'Data', 'Physiology', 'PD_Fixation', 'Recording', monkey, site, 'clean');
if nargout > 1
    D = dir(fullfile(dir_, '*.mat'));
    fnames_ = {D.name};
end