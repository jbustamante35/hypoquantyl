function D = runSweepAnalysis(BW, numX, numY, stps, vis, sv)
%% runSweepAnalysis: extract contours from dataset, run PCA, then sweep through PCs
% This function runs a pipeline in which the user loads a cell array of bw images, then defines the
% number of Principal Components (PCs) to extract from PCA on the x-/y-coordinates. The number of
% respective PCs to use for the x and y coordinate are set by the numX and numY parameters.
%
% The data from PCA then go through the sweeping function, where each PC from the x-/y-coordinates
% are iteratively swept up or down by a standard deviation, up to the number of steps defined by the
% stps parameter.
%
% Additional data can be visualized if the boolean vis parameter is set to 1; otherwise only the
% figures from the PC sweep will be shown. The boolean sv parameter saves the figure handles as both
% .fig and .tif files, and the PCA output and PC sweep output as a single .mat file.
%
% Usage:
%   D = runSweepAnalysis(BW, numX, numY, stps, vis, sv)
%
% Input:
%   BW: cell array of bw images to be analyzed
%   numX: number of PCs to extract for PCA on the x-coordinates
%   numY: number of PCs to extract for PCA on the y-coordinates
%   stps: number of steps above/below standard deviations to sweep through
%   vis: boolean to show only sweep figures (0) or additional figures (1)
%   sv: boolean to save figure handles as .fig and .tif files and data as a .mat file
%
% Output:
%   D: structure containing PCA data and PC sweep data
%
% Examples:
%   dat = '/mnt/tetra/JulianBustamante/HypoQuantyl/Contours';
%   C   = load(sprintf('%s/180830_scott/180830_carrotPCA.mat', dat)); % 700 roots unaligned dataset
%   C   = C.CARROT;
%   BW  = C.bw';
%   D   = runSweepAnalysis(BW, 5, 5, 7, 0, 0)
%
%   dat = '/mnt/tetra/JulianBustamante/HypoQuantyl/Contours';
%   V   = load(sprintf('%s/180830_scott/carrotPCAb.mat', dat)); % 328 roots aligned dataset
%   BW  = V.bw';
%   W   = runSweepAnalysis(BW, 3, 2, 5, 1, 1)
%

%% Prepare empty figure plots
if vis
    figs = [];
    fnms = {};
    
    figs(1) = figure; % Reconvert simulated contours
    figs(2) = figure; % Mean contour vs random contours
    figs(3) = figure; % All Sweeps on Mean Contour
    figs(4) = 4; % Sweep through x-coordinate PCs
    figs(5) = 5; % Sweep through y-coordinate PCs
    
    fnms{1} = sprintf('%s_ReconvertedOnImage', datestr(now, 'yymmdd'));
    fnms{2} = sprintf('%s_MeanVsRandomContours', datestr(now, 'yymmdd'));
    fnms{3} = sprintf('%s_SweepsOnMeanContour', datestr(now, 'yymmdd'));
    fnms{4} = sprintf('%s_PCSweep_xCoords', datestr(now, 'yymmdd'));
    fnms{5} = sprintf('%s_PCSweep_yCoords', datestr(now, 'yymmdd'));
    
    set(figs(1:3), 'Color', 'w');
    
else
    figs = [];
    fnms = {};
    
    figs = 1 : 5; % PC sweep figures are figs(4:5)
    
    fnms{1} = '';
    fnms{2} = '';
    fnms{3} = '';
    fnms{4} = sprintf('%s_PCSweep_xCoords', datestr(now, 'yymmdd'));
    fnms{5} = sprintf('%s_PCSweep_yCoords', datestr(now, 'yymmdd'));
    
end

%% Extract and Rasterize normalized contours from BW images
m  = @(x) randi([1 length(x)], 1);
[X, Y, CNTR] = extractAndRasterize(BW);

%% Run PCA on x-/y-coordinates
sz        = [size(CNTR{1}.NormalizedOutline,1) 1];
[pcaX, ~] = pcaAnalysis(X, numX, sz, 0, 'xCoords', 0);
[pcaY, ~] = pcaAnalysis(Y, numY, sz, 0, 'yCoords', 0);

%% Sweep through all PCs
[scFull, smFull, fg] = performSweep('pcaX', pcaX, 'pcaY', pcaY, 'nsteps', stps, 'sv', 0);
figs(4:5) = fg;

%% Set x-/y-limits equal [figure out how to set this dynamically]
% xl = [-900 200];
% yl = [-150 150];
xl = getMax(pcaX);
yl = getMax(pcaY);

% x-coordinates
set(0, 'CurrentFigure', figs(4));
for s = 1 : numX
    subplot(2, 2, s);
%     xlim(xl);
%     ylim(yl);
end

% y-coordinates
set(0, 'CurrentFigure', figs(5));
for s = 1 : numY
    subplot(2, 1, s);
%     xlim(xl);
%     ylim(yl);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END OF MAIN PIPELINE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot re-converted simulated contour onto bw image
if vis
    set(0, 'CurrentFigure', figs(1));
    cla;clf;
    
    numCV = 16;
    rows  = numCV/4;
    cols  = numCV/4;
    for p = 1 : numCV
        set(0, 'CurrentFigure', figs(1));
        subplot(rows, cols, p);
        hold on;
        
        % Get random index and extract data
        rIdx = m(BW);
        img  = BW{rIdx};
        apt  = CNTR{rIdx}.getAnchorPoint;
        aid  = CNTR{rIdx}.getAnchorIndex;
        
        % Convert normalized input and simulated contour to raw image coordinates
        nInp = [pcaX.InputData(rIdx,:) ; pcaY.InputData(rIdx,:)]';
        cInp = norm2raw(nInp, apt, aid);
        nSim = [pcaX.SimData(rIdx,:) ; pcaY.SimData(rIdx,:)]';
        cSim = norm2raw(nSim, apt, aid);
        
        % Overlay converted input and simulated contour on bw image
        imagesc(img);
        plt(cInp, 'g-', 1);
        plt(cSim, 'y-', 1);
        
        colormap gray;
        axis ij;
        axis tight;
        ttl = sprintf('Contour %d', rIdx);
        title(ttl);
    end
    
    %% Compare mean contour with actual contours
    set(0, 'CurrentFigure', figs(2));
    cla;clf;
    hold on;
    
    CT    = cat(1, CNTR{:});
    numCT = numel(CNTR) / 10;
    for c = 1 : numCT
        set(0, 'CurrentFigure', figs(2));
        rand_contour = CT(m(CT)).NormalizedOutline;
        plt(rand_contour, 'm--', 1);
    end
    
    mean_contour = smFull{1}{1}.mean;
    plt(mean_contour, 'k-', 5);
    
    axis ij;
    xll = [-1800 50];
    yll = [-120 120];
    xlim(xll);
    ylim(yll);
    ttl = sprintf('%d contours on mean contour', numCT);
    title(ttl);
    
    %% Plot all PC sweeps on single mean contour
    set(0, 'CurrentFigure', figs(3));
    cla;clf;
    hold on;
    
    for d = 1 : size(smFull, 1)
        dim = smFull(d,:);
        for p = 1 : size(dim, 2)
            pc = dim{p};
            for s = 1 : size(pc, 2)
                try
                    set(0, 'CurrentFigure', figs(3));
                    swp = pc{s};
                    plt(swp.up, 'g--', 1);
                    plt(swp.down, 'r--', 1);
                catch
                    continue;
                end
            end
        end
    end
    
    plt(mean_contour, 'k-', 5);
    
    axis ij;
    xlim(xll);
    ylim(yll);
    ttl = sprintf('%d Swept PCs on mean contour', stps);
    title(ttl);
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVE DATA HERE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Figures and Dataset
D  = v2struct(pcaX, pcaY, scFull, smFull, CNTR);

if sv
    for g = 1 : numel(figs)
        try
            savefig(figs(g), fnms{g});
            saveas(figs(g), fnms{g}, 'tiffn');
        catch
            continue;
        end
    end
    
    D  = v2struct(pcaX, pcaY, scFull, smFull, CNTR);
    nm = sprintf('%s_carrotPCA_analysis_%dRoots', datestr(now, 'yymmdd'), numel(CNTR));
    save(nm, '-v7.3', 'D');
end
end


function [X, Y, CNTR] = extractAndRasterize(BW)
%% subfunction to create ContourJB objects from contours then split and rasterize x-/y-coordinates

sz   = 800;
CNTR = cellfun(@(x) extractContour(x, sz), BW, 'UniformOutput', 0);
BNDS = cellfun(@(x) x.NormalizedOutline, CNTR, 'UniformOutput', 0);
bndX = cellfun(@(x) getDim(x,1), BNDS, 'UniformOutput', 0);
bndY = cellfun(@(x) getDim(x,2), BNDS, 'UniformOutput', 0);
X    = rasterizeImagesHQ(bndX);
Y    = rasterizeImagesHQ(bndY);

end