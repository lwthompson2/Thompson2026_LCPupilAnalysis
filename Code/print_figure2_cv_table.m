function out_tbl = print_figure2_cv_table(paths, opts)
% PRINT_FIGURE2_CV_TABLE
% Print a publication-style table for Figure 2 CV results using cached outputs.
% Does not recompute analysis.

if nargin < 1 || isempty(paths)
    paths = config_paths();
end
if nargin < 2 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'output_tag') || isempty(opts.output_tag)
    opts.output_tag = '';
end
suffix = output_suffix_local(opts.output_tag);

if isfield(opts, 'cv_mat') && ~isempty(opts.cv_mat)
    cv_mat = char(opts.cv_mat);
else
    cv_mat = fullfile(paths.results_dir, sprintf('Figure2_cv_metrics%s.mat', suffix));
end
if ~exist(cv_mat, 'file')
    error('CV metrics not found at %s. Run run_figure2_cv_analysis first.', cv_mat);
end

s = load(cv_mat, 'cv_tbl', 'opts');
if ~isfield(s, 'cv_tbl') || isempty(s.cv_tbl)
    error('cv_tbl missing or empty in %s', cv_mat);
end
cv_tbl = s.cv_tbl;
method_label = 'kfold';
if isfield(s, 'opts') && isfield(s.opts, 'cv_method') && ~isempty(s.opts.cv_method)
    method_label = char(s.opts.cv_method);
end

long_tbl = table('Size', [0 10], ...
    'VariableTypes', {'double','string','string','double','double','double','double','string','double','double'}, ...
    'VariableNames', {'row_num','analysis','monkey','N', ...
    'cv_r2_iqr_lo','cv_r2_iqr_hi','cv_r2_median','cv_r2_p', ...
    'n_perm_sig','n_perm_tested'});

for rr = 1:6
    rr_tbl = cv_tbl(cv_tbl.row_num == rr, :);
    if isempty(rr_tbl)
        continue
    end
    analysis_label = string(rr_tbl.row_label(1));

    for mm = 1:2
        mm_tbl = rr_tbl(rr_tbl.monkey_id == mm, :);
        r2_vals = mm_tbl.cv_r2(isfinite(mm_tbl.cv_r2));

        if isempty(r2_vals)
            continue
        end

        p_r2 = NaN;
        if ~isempty(r2_vals)
            try
                p_r2 = signrank(r2_vals);
            catch
            end
        end
        n_perm_sig = NaN;
        n_perm_tested = NaN;
        if ismember('cv_r2_perm_p', mm_tbl.Properties.VariableNames)
            perm_p = mm_tbl.cv_r2_perm_p(isfinite(mm_tbl.cv_r2_perm_p));
            n_perm_tested = numel(perm_p);
            n_perm_sig = sum(perm_p < 0.05);
        end

        r2_q = quantile(r2_vals, [0.25 0.75]);

        long_tbl = [long_tbl; {rr, analysis_label, monkey_short(mm), ...
            numel(r2_vals), ...
            r2_q(1), r2_q(2), ...
            median(r2_vals, 'omitnan'), p_to_sci_str(p_r2), ...
            n_perm_sig, n_perm_tested}]; %#ok<AGROW>
    end
end

% Build wide publication table: one row per analysis, monkey-specific columns.
out_tbl = table('Size', [0 16], ...
    'VariableTypes', {'double','string', ...
    'double','double','double','double','string','double','double', ...
    'double','double','double','double','string','double','double'}, ...
    'VariableNames', {'row_num','analysis', ...
    'Oz_N','Oz_cv_r2_iqr_lo','Oz_cv_r2_iqr_hi','Oz_cv_r2_median','Oz_cv_r2_p','Oz_n_perm_sig','Oz_n_perm_tested', ...
    'Ci_N','Ci_cv_r2_iqr_lo','Ci_cv_r2_iqr_hi','Ci_cv_r2_median','Ci_cv_r2_p','Ci_n_perm_sig','Ci_n_perm_tested'});

row_ids = unique(long_tbl.row_num);
for i = 1:numel(row_ids)
    rr = row_ids(i);
    rr_tbl = long_tbl(long_tbl.row_num == rr, :);
    if isempty(rr_tbl)
        continue
    end
    analysis_label = string(rr_tbl.analysis(1));

    oz = rr_tbl(rr_tbl.monkey == "Oz", :);
    ci = rr_tbl(rr_tbl.monkey == "Ci", :);

    out_tbl = [out_tbl; {rr, analysis_label, ...
        scalar_or_nan(oz.N), scalar_or_nan(oz.cv_r2_iqr_lo), scalar_or_nan(oz.cv_r2_iqr_hi), scalar_or_nan(oz.cv_r2_median), scalar_or_na_str(oz.cv_r2_p), scalar_or_nan(oz.n_perm_sig), scalar_or_nan(oz.n_perm_tested), ...
        scalar_or_nan(ci.N), scalar_or_nan(ci.cv_r2_iqr_lo), scalar_or_nan(ci.cv_r2_iqr_hi), scalar_or_nan(ci.cv_r2_median), scalar_or_na_str(ci.cv_r2_p), scalar_or_nan(ci.n_perm_sig), scalar_or_nan(ci.n_perm_tested)}]; %#ok<AGROW>
end

% Export publication table with two-row super-column headers for Excel/Word.
super_xlsx = fullfile(paths.results_dir, sprintf('Figure2_CV_publication_table_superheader%s.xlsx', suffix));
if exist(super_xlsx, 'file')
    delete(super_xlsx);
end

header_row1 = {
    'Analysis', ...
    'CV R2 median', '', ...
    'CV R2 IQR', '', ...
    'CV R2 p-value', '', ...
    'Perm. p < 0.05', '' ...
    };

header_row2 = {
    '', ...
    'Oz', 'Ci', ...
    'Oz', 'Ci', ...
    'Oz', 'Ci', ...
    'Oz', 'Ci' ...
    };

data_cells = cell(height(out_tbl), 9);
for i = 1:height(out_tbl)
    data_cells{i,1} = analysis_label_short_local(out_tbl.row_num(i));

    data_cells{i,2} = out_tbl.Oz_cv_r2_median(i);
    data_cells{i,3} = out_tbl.Ci_cv_r2_median(i);

    data_cells{i,4} = sprintf('[%.3f, %.3f]', out_tbl.Oz_cv_r2_iqr_lo(i), out_tbl.Oz_cv_r2_iqr_hi(i));
    data_cells{i,5} = sprintf('[%.3f, %.3f]', out_tbl.Ci_cv_r2_iqr_lo(i), out_tbl.Ci_cv_r2_iqr_hi(i));

    data_cells{i,6} = format_p_display_local(out_tbl.Oz_cv_r2_p(i));
    data_cells{i,7} = format_p_display_local(out_tbl.Ci_cv_r2_p(i));

    data_cells{i,8} = sprintf('%d/%d', out_tbl.Oz_n_perm_sig(i), out_tbl.Oz_n_perm_tested(i));
    data_cells{i,9} = sprintf('%d/%d', out_tbl.Ci_n_perm_sig(i), out_tbl.Ci_n_perm_tested(i));

end

writecell([header_row1; header_row2; data_cells], super_xlsx);

fprintf('\nFigure 2 Prediction/Generalization (%s)\n', upper(method_label));
fprintf('%s\n', repmat('-', 1, 120));
fprintf('%-2s | %-33s | %-2s | %4s | %10s | %10s | %10s | %10s | %8s\n', ...
    '#', 'Analysis', 'M', 'N', 'R2_q25', 'R2_q75', 'R2_med', 'R2_p', 'perm_sig');
fprintf('%s\n', repmat('-', 1, 120));
for i = 1:height(long_tbl)
    fprintf('%-2d | %-33s | %-2s | %4d | %10.3f | %10.3f | %10.3f | %10s | %3d/%-4d\n', ...
        long_tbl.row_num(i), ...
        char(long_tbl.analysis(i)), ...
        char(long_tbl.monkey(i)), ...
        long_tbl.N(i), ...
        long_tbl.cv_r2_iqr_lo(i), ...
        long_tbl.cv_r2_iqr_hi(i), ...
        long_tbl.cv_r2_median(i), ...
        char(long_tbl.cv_r2_p(i)), ...
        long_tbl.n_perm_sig(i), long_tbl.n_perm_tested(i));
end
fprintf('%s\n\n', repmat('-', 1, 120));
fprintf('Saved publication table (super-header xlsx): %s\n', super_xlsx);
fprintf('\n');
end

function suffix = output_suffix_local(output_tag)
tag = strtrim(char(output_tag));
if isempty(tag)
    suffix = '';
    return
end
tag = regexprep(tag, '[^A-Za-z0-9_\-]', '_');
if startsWith(tag, '_')
    suffix = tag;
else
    suffix = ['_' tag];
end
end

function m = monkey_short(mm)
if mm == 1
    m = 'Oz';
else
    m = 'Ci';
end
end

function s = p_to_sci_str(p)
if ~isfinite(p)
    s = "n/a";
else
    s = sprintf('%.3g', p);
end
end

function v = scalar_or_nan(x)
if isempty(x)
    v = NaN;
else
    v = x(1);
end
end

function s = scalar_or_na_str(x)
if isempty(x)
    s = "n/a";
else
    s = string(x(1));
end
end

function label = analysis_label_short_local(row_num)
switch row_num
    case 1
        label = 'B. Pupil vs. Ev. Pupil';
    case 2
        label = 'B. LC vs. Ev. LC';
    case 3
        label = 'B. Pupil vs. B. LC';
    case 4
        label = 'Ev. Pupil vs. Ev. LC';
    case 5
        label = 'B. Pupil vs. Ev. LC';
    case 6
        label = 'Ev. Pupil vs. B. LC';
    otherwise
        label = sprintf('Row %d', row_num);
end
end

function out = format_p_display_local(p_str)
if strcmpi(strtrim(char(p_str)), 'n/a')
    out = 'n/a';
    return
end
p = str2double(char(p_str));
if ~isfinite(p)
    out = 'n/a';
elseif p < 1e-3
    out = '<0.001';
else
    out = sprintf('%.3f', p);
end
end
