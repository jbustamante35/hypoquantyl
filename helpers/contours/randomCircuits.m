function [CRCS, figs] = randomCircuits(Ein, Ncrcs, typ, flipme, sv, vis)
%% randomCircuits: obtain and normalize random set of manually-drawn contours
% This function takes in a fully-generated Experiment object as input and
% extracts random frames from random Hypocotyl objects to use as training data
% for the machine learning segmentation algorithm. The user is prompted to trace
% a manually-drawn contour around a hypocotyl, which will be stored as a
% CircuitJB object. The full array of CircuitJB objects is returned as well.
%
% In order to use this function, a number of conditions must be met:
%   - The Experiment object must contain nested Genotype objects
%       * Run AddGenotypes method
%   - Each Genotype must have a nested array of sorted Seedling objects
%       * Run FindSeedlings and SortSeedlings methods
%   - Each Seedling must have a child Hypocotyl object
%       * Run FindHypocotyl and SortPreHypocotyls methods
%   - Each Seedling object must also have bad frames removed
%       * Run RemoveBadFrames method
%
% Usage:
%   CRCS = randomCircuits(Ein, Ncrcs, typ, flipme, sv, vis)
%
% Input:
%   Ein: Experiment object to draw from to generate contour data
%   Ncrcs: number of random Seedlings to analyze
%   typ: 0 to get contours of Seedlings, 1 to get contours of Hypocotyls
%   flipme: boolean to inflate dataset with flipped versions of each Hypocotyl
%   sv: save figures as .fig and .tiff files
%   vis: boolean to plot figures or not
%
% Output:
%   CRCS: CircuitJB array of manually-drawn contours from Experiment Ein
%   figs: handles to figures if vis is set to true
%
% NOTE: [11/28/2018]
%   I completely changed the methods used for extracting images from a class,
%   as well as the way Hypocotyl objects are stored in a Seedling object:
%       - Images are stored as filepath names, rather than raw image matrices
%       - Hypocotyls are stored as a single object with multiple frames, rather
%         than each frame being an individual Hypocotyl object
%
%   Because of this drastic change, I needed to change this function to extract
%   frames from Hypocotyl objects, rather than PreHypocotyl objects, as it was
%   before the change.
%
% TODO: [12/06/2018]
%   There will be a need to generate datasets of hypocotyls of specific shapes
%   or specific time points, so I need to make this more flexible to allow a
%   matrix input to draw contours around a desired hypocotyl. 
%
%   I'm imagining this as a [N x 3] input, where N is the desired number of
%   contours to draw, each with 3 integers designating a specific Genotype,
%   Seedling, and frame to show. 
%   
%   As of now, let's just focus on getting a solid algorithm established. 
%

%% Initialize object array of Seedlings/Hypocotyl to draw contours for
if typ
    S = Ein.combineHypocotyls;
else
    S = Ein.combineSeedlings;
end

sIdx = randi(numel(S), 1, Ncrcs);
if flipme
    CRCS = makeCircuits(Ncrcs * 2);
else
    CRCS = makeCircuits(Ncrcs);
end

%% Draw contours at random frame from random Seedling/Hypocotyl
% If flipme parameter set to true, then CircuitJB array is stored in n x 2, 
% where the flipped version is stored in dimension 2 of a Hypocotyl object
cIdx = 1;
for k = sIdx
    rs = S(k);
    
    if flipme
        [org, flp] = getCircuit(rs, typ, flipme);
        CRCS(cIdx) = org;
        cIdx       = cIdx + 1;
        CRCS(cIdx) = flp;
        cIdx       = cIdx + 1;
    else
        CRCS(cIdx) = getCircuit(rs, typ, flipme);
        cIdx = cIdx + 1;
    end
    cla;clf;
end

if sv
    arrayfun(@(x) x.DerefParents, CRCS, 'UniformOutput', 0);
    nm = sprintf('%s_%drandomCircuits_circuits', tdate('s'), Ncrcs);
    save(nm, '-v7.3', 'CRCS');
    arrayfun(@(x) x.ResetReference(Ein), CRCS, 'UniformOutput', 0);
end

%% Show 8 first images and masks, unless < 8 contours drawn
if vis
    if Ncrcs < 8
        N = numel(CRCS);
    else
        N = 8;
    end
    
    fig1 = figure;
    fig2 = figure;
    for i = 1 : N
        % Show grayscale image
        showImage(i, fig1, CRCS(i).getImage(1, 'gray'));
        hold on;
        
        % Draw Routes on grayscale image
        rts = CRCS(i).getRoute;
        arrayfun(@(x) drawRoutesAndMeans(x), rts, 'UniformOutput', 0);
        
        % Show masked image
        showImage(i, fig2, CRCS(i).getImage(1, 'bw'));
    end
    
    if sv
        saveFigure('gray', N, fig1);
        saveFigure('bw',   N, fig2);
    end
    
    figs = [fig1 fig2];
else
    figs = [];
end
end

function c = makeCircuits(n)
%% makeCircuits: subfunction to create n number of individual CircuitJB objects
% The repmat creates multiple copies of the same handle to an individual object,
% instead of creating multiple handles to individual objects.
c = repmat(CircuitJB, 1, n);
for i = 1 : n
    c(i) = CircuitJB;
end
end

function [crc, flp] = getCircuit(rndS, typ, flipme)
%% getCircuit: subfunction to manually-draw contour on random frame of Seedling

% Get a random good frame and image from Seedling's lifetime
if typ
    frms = rndS.Parent.getGoodFrames;
    rFrm = frms(randi(length(frms), 1));
    org  = sprintf('%s_%s_%s_%s_Frm{%d}', rndS.ExperimentName, ...
        rndS.GenotypeName, rndS.SeedlingName, rndS.HypocotylName, rFrm);
%     im  = rndS.getImage(rFrm, 'gray', 1);
else    
    frms = rndS.getGoodFrames;
    rFrm = frms(randi(length(frms), 1));
    org  = sprintf('%s_%s_%s_Frm{%d}', rndS.ExperimentName, ...
        rndS.GenotypeName, rndS.SeedlingName, rFrm);
%     im  = rndS.getImage(rFrm, 'gray');
end   

% Set image and origin data for CircuitJB
crc = CircuitJB('Origin', org, 'Parent', rndS);
crc.setParent(rndS);
% crc.setImage(1, 'gray', im); % Writes image into memory

% Draw Outline and AnchorPoints and normalize coordinates
crc.DrawOutline(1);
crc.DrawAnchors(1);
crc.ConvertRawPoints;
crc.CreateRoutes;

% Set Contour for this object
if typ
    rndS.setCircuit(rFrm, crc, 'org');
else
    rndS.setContour(rFrm, crc);
end

% Extract manual contour from flipped image
if flipme
    flpim = rndS.FlipMe(rFrm, 1);
    org = sprintf('flip_%s_%s_%s_%s_Frm{%d}', rndS.ExperimentName, ...
        rndS.GenotypeName, rndS.SeedlingName, rndS.HypocotylName, rFrm);
    
    flp = CircuitJB('Origin', org, 'Parent', rndS);
    flp.setParent(rndS);
%     flp.setImage(1, 'gray', flpim);
    
    flp.DrawOutline(1);
    flp.DrawAnchors(1);
    flp.ConvertRawPoints;
    flp.CreateRoutes;
    
    if typ
        rndS.setCircuit(rFrm, flp, 'flp');
    else
        rndS.setContour(rFrm, flp);
    end
end
end

function crc = createCircuit(rndS, org, typ)
%% Create CircuitJB and prompt user to draw contour
% Set image and origin data for CircuitJB
crc = CircuitJB('Origin', org, 'Parent', rndS);
crc.setParent(rndS);
% crc.setImage(1, 'gray', im); % Writes image into memory

% Draw Outline and AnchorPoints and normalize coordinates
crc.DrawOutline(1);
crc.DrawAnchors(1);
crc.ConvertRawPoints;
crc.CreateRoutes;

% Set Contour for this object
if typ
    rndS.setCircuit(rFrm, crc, 'org');
else
    rndS.setContour(rFrm, crc);
end

end

function showImage(num, fig, im)
%% Show image on given plot of figure
set(0,'CurrentFigure',fig);
subplot(4,2,num);
imagesc(im);
colormap gray, axis image;
hold on;
end

function drawRoutesAndMeans(r)
%% Plot single Route onto figure
plt = r.getInterpTrace(1);
mn  = r.getMean(1);

plot(plt(:,1), plt(:,2), 'LineWidth', 2);
plot(mn(1),    mn(2),    'o', 'MarkerSize', 7);
hold on;
end

function saveFigure(im, N, fig)
%% Save figure as .fig and .tiff files
nm = sprintf('%s_%drandomCircuits_%s', tdate('s'), N, im);
set(fig,'Color','w');
savefig(fig, nm);
saveas(fig, nm, 'tiffn');
end


