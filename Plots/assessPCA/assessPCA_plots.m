function [A, figs] = assessPCA_plots(typ, numC, sv, vis)
%% assessPCA_plots: daily preparation of important variables for today
% Make sure you're in the correct directory when you run me!
% See conv2vars for commands to load variables into workspace

%% Load CircuitJB objects
lab = '/home/jbustamante/LabData/HypoQuantyl';
cLR = sprintf('%s/%s', lab, 'Contours/180827/scripts/180827_randomCircuitsUpdate_19circuitsLR.mat');
load(cLR);
clear lab cLR;

%% Create figures to save
[figs, fnms] = createFigures;

%% Today's code kindly sponsered by The Confederate Union's National Frisbee Golf Team
%% Get envelopes for all Curve objects in CircuitJB objects
cc = [cl ; cr];

%% Define randomized contour and segment
m = @(x) randi([1 length(x)], 1);
[n, ~, ~, u, r] = randomContourAndSegment(cc, m);

%% Rasterize all Normalized and Envelope segments to prepare for PCA
[nLx, nLy] = processCurveData(cl, typ);
[nRx, nRy] = processCurveData(cr, typ);

% Check rasterized data
nxt = 1;
set(0, 'CurrentFigure', figs(nxt)); nxt = nxt + 1;
ttl = @(f,d) sprintf('%s Segments \n %s-facing | %s-coordinates', typ, f, d);
subplot(221); imagesc(nLx); title(ttl('Left', 'x'));
subplot(222); imagesc(nLy); title(ttl('Left', 'y'));
subplot(223); imagesc(nRx); title(ttl('Right', 'x'));
subplot(224); imagesc(nRy); title(ttl('Right', 'y'));

%% Check that coordinates were rasterized correctly
s = m(nLx);

set(0, 'CurrentFigure', figs(nxt)); nxt = nxt + 1;
subplot(211);
plt([nLx(s,:) ; nLy(s,:)]', 'b.', 5);
ttl = sprintf('Segment %d | %s-facing', s, 'Left');
title(ttl);

subplot(212);
plt([nRx(s,:) ; nRy(s,:)]', 'r.', 5);
ttl = sprintf('Segment %d | %s-facing', s, 'Right');
title(ttl);

%% DO PCA
pcaA = @(X, f, d) pcaAnalysis(X, numC, size(X(1,:)), sv, ...
    sprintf('%sFacing_%sCoordinates', f, d), vis);
[pLx, ~] = pcaA(nLx, 'Left', 'x');
[pLy, ~] = pcaA(nLy, 'Left', 'y');
[pRx, ~] = pcaA(nRx, 'Right', 'x');
[pRy, ~] = pcaA(nRy, 'Right', 'y');

%% Compare Input vs Sim data
set(0, 'CurrentFigure', figs(nxt)); nxt = nxt + 1;
cla;clf;

subplot(211);
hold on;
plt([pLx.InputData(s,:) ; pLy.InputData(s,:)]', 'k--', 5);
plt([pLx.SimData(s,:) ; pLy.SimData(s,:)]', 'b', 5);
ttl = sprintf('Input vs Sim Data | %d PCs \n Segment %d | %s-facing', numC, s, 'Left');
title(ttl);

subplot(212);
hold on;
plt([pRx.InputData(s,:) ; pRy.InputData(s,:)]', 'k--', 5);
plt([pRx.SimData(s,:) ; pRy.SimData(s,:)]', 'r', 5);
ttl = sprintf('Input vs Sim Data | %d PCs \n Segment %d | %s-facing', numC, s, 'Right');
title(ttl);

%% Validate entire contour
% Split entire dataset into individual contours and choose random contour
if n > length(cc)/2
    a = n - (length(cc)/2);
else
    a = n;
end

strt = 1 : u : length(pRx.InputData);
oIdx = strt(a):(strt(a + 1) - 1); % This gives an error sometimes [drawning from larger dataset]

% Plot whole contour [Input vs Simulated]
set(0, 'CurrentFigure', figs(nxt)); nxt = nxt + 1;
cla;clf;

subplot(211); hold on;
validContourPlot(pLx, pLy, oIdx, 'b');
ttl = sprintf('Input vs Sim Data | %d PCs \n Contour %d | %s-facing', numC, r, 'Left');
title(ttl);

subplot(212); hold on;
validContourPlot(pRx, pRy, oIdx, 'r');
ttl = sprintf('Input vs Sim Data | %d PCs \n Contour %d | %s-facing', numC, r, 'Right');
title(ttl);

%% Convert contour's simulated midpoint-normalized segments to predicted raw segments
[rawL, cnvL] = convertSimulatedSegments(pLx.InputData(oIdx,:), pLy.InputData(oIdx,:), ...
    pLx.SimData(oIdx,:), pLy.SimData(oIdx,:), cl(a).Curves);
[rawR, cnvR] = convertSimulatedSegments(pRx.InputData(oIdx,:), pRy.InputData(oIdx,:), ...
    pRx.SimData(oIdx,:), pRy.SimData(oIdx,:), cr(a).Curves);

% Plot whole contour [Input vs Simulated] after conversion to raw segment coordinates
set(0, 'CurrentFigure', figs(nxt)); nxt = nxt + 1;
cla;clf;

subplot(211); hold on;
cellfun(@(x) plt(x, 'k--', 3), rawL, 'UniformOutput', 0);
cellfun(@(x) plt(x, 'b.', 3), cnvL, 'UniformOutput', 0);

subplot(212); hold on;
cellfun(@(x) plt(x, 'k--', 3), rawR, 'UniformOutput', 0);
cellfun(@(x) plt(x, 'r.', 3), cnvR, 'UniformOutput', 0);

subplot(211);
axis image;
axis ij;
ttl = sprintf('Converted Input vs Sim Data | %d PCs \n Contour %d | %s-facing', numC, r, 'Left');
title(ttl);

subplot(212);
axis image;
axis ij;
ttl = sprintf('Converted Input vs Sim Data | %d PCs \n Contour %d | %s-facing', numC, r, 'Right');
title(ttl);

%% Save CircuitJB data
nm = sprintf('%s_randomCircuitsUpdate_%dcircuitsLR', datestr(now, 'yymmdd'), numel(cl));
save(nm, '-v7.3', 'cl', 'cr');

%% Save Figures
currDir = pwd;
for g = 1 : numel(figs)
    dirName = sprintf('%s/%dPCs', pwd, numC);
    if ~isdir(dirName)        
        mkdir(dirName);
    end
    
    cd(dirName);
    try
        movefile('../*.fig', dirName);
        movefile('../*.tif', dirName);
        movefile('../*.mat', dirName);            
    catch
        fprintf('No .fig, .tif, or .mat files to move\n');
    end
    
    savefig(figs(g), fnms{g});
    saveas(figs(g), fnms{g}, 'tiffn');
    cd(currDir);
end

A = struct('pcaL', [pLx pLy], ...
    'pcaR', [pRx pRy], ...
    'segL', [rawL ; cnvL], ...
    'segR', [rawR ; cnvR]);

close all;
close force;
end
