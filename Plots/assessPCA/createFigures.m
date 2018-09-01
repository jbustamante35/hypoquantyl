function [figs, fnms] = createFigures
%% createFigures: generate desired number of figures with corresponding figure names
% Input:
%
%
% Output:
%
%

fig1 = figure; % Rasterized segment data
fig2 = figure; % Validate rasterized data
fig3 = figure; % Overlay Input vs Simulated PCA data by individual segments
fig4 = figure; % Overlay Input vs Simulated PCA data of entire contour
fig5 = figure; % Overlay Input vs Simulated PCA data of entire converted contour

fnm1 = sprintf('%s_RasterizedSegmentData', datestr(now, 'yymmdd'));
fnm2 = sprintf('%s_ValidateRasterizedData', datestr(now, 'yymmdd'));
fnm3 = sprintf('%s_InputSim_SingleSegment', datestr(now, 'yymmdd'));
fnm4 = sprintf('%s_InputSim_NormalContour', datestr(now, 'yymmdd'));
fnm5 = sprintf('%s_InputSim_ConvertedContour', datestr(now, 'yymmdd'));

figs = [fig1 fig2 fig3 fig4 fig5];
fnms = {fnm1, fnm2, fnm3, fnm4, fnm5};
set(figs, 'Color', 'w');

end