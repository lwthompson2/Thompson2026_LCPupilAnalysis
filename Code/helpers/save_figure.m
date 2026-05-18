function save_figure(figHandle, outpath, opts)
% SAVE_FIGURE  Save figure handle to PDF (or other formats) using exportgraphics/print.
%   save_figure(figHandle, outpath, opts)
% where opts is the struct from export_settings().

if nargin < 3 || isempty(opts)
    opts = export_settings();
end

[outdir, ~, ~] = fileparts(outpath);
if ~exist(outdir, 'dir')
    mkdir(outdir);
end

% Ensure figure has desired units and size
try
    figHandle.Units = opts.units;
    figHandle.Position = opts.paper_position;
    ax = findall(figHandle, 'Type', 'axes');
    set(ax, 'FontName', opts.font, 'FontSize', opts.font_size);
catch
    % ignore if figure doesn't have these properties
end

% Save using exportgraphics if available (R2020a+)
try
    if strcmpi(opts.format, 'pdf')
        exportgraphics(figHandle, outpath, 'ContentType', 'vector');
    else
        exportgraphics(figHandle, outpath, 'Resolution', opts.dpi);
    end
catch
    % fallback to print
    try
        if strcmpi(opts.format, 'pdf')
            print(figHandle, outpath, '-dpdf', sprintf('-r%d', opts.dpi));
        else
            print(figHandle, outpath, ['-d' opts.format], sprintf('-r%d', opts.dpi));
        end
    catch ME
        warning(ME.identifier, '%s', ME.message);
    end
end
end
