function side_tbl = export_cv_method_side_by_side(paths, kfold_tag, loocv_tag)
% EXPORT_CV_METHOD_SIDE_BY_SIDE
% Build a side-by-side Figure 2 table comparing k-fold vs LOOCV CV outputs.

if nargin < 1 || isempty(paths)
    paths = config_paths();
end
if nargin < 2 || isempty(kfold_tag)
    kfold_tag = 'kfold';
end
if nargin < 3 || isempty(loocv_tag)
    loocv_tag = 'loocv';
end

k_tbl = print_figure2_cv_table(paths, struct('output_tag', kfold_tag));
l_tbl = print_figure2_cv_table(paths, struct('output_tag', loocv_tag));

keep = {'row_num','analysis', ...
    'Oz_cv_r2_median','Oz_cv_r2_iqr_lo','Oz_cv_r2_iqr_hi','Oz_n_perm_sig','Oz_n_perm_tested', ...
    'Ci_cv_r2_median','Ci_cv_r2_iqr_lo','Ci_cv_r2_iqr_hi','Ci_n_perm_sig','Ci_n_perm_tested'};

k_sub = k_tbl(:, keep);
l_sub = l_tbl(:, keep);

k_sub.Properties.VariableNames = rename_with_prefix_local(k_sub.Properties.VariableNames, 'kfold_');
l_sub.Properties.VariableNames = rename_with_prefix_local(l_sub.Properties.VariableNames, 'loocv_');

k_sub.Properties.VariableNames{1} = 'row_num';
k_sub.Properties.VariableNames{2} = 'analysis';
l_sub.Properties.VariableNames{1} = 'row_num';
l_sub.Properties.VariableNames{2} = 'analysis';

side_tbl = join(k_sub, l_sub, 'Keys', {'row_num','analysis'});
side_tbl = sortrows(side_tbl, 'row_num');

out_xlsx = fullfile(paths.results_dir, 'Figure2_CV_method_side_by_side.xlsx');
writetable(side_tbl, out_xlsx);
fprintf('Saved side-by-side CV method table: %s\n', out_xlsx);
end

function names_out = rename_with_prefix_local(names_in, prefix)
names_out = names_in;
for i = 3:numel(names_in)
    names_out{i} = [prefix names_in{i}];
end
end
