function opts = export_settings()
% EXPORT_SETTINGS  Centralized figure export settings for paper figures.
% Returns a struct with defaults. Call and modify fields as needed.

opts = struct();
opts.width_in = 7;            % figure width in inches (paper requirement)
opts.dpi = 300;               % raster DPI for any raster export
opts.font = 'Arial';
opts.font_size = 10;
opts.units = 'inches';
opts.paper_position = [0 0 opts.width_in opts.width_in*0.6]; % default aspect
opts.format = 'pdf';         % output file format for paper figures
opts.renderer = 'painters';  % use vector renderer for PDF when possible
end
