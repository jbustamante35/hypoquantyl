function CRCS = randomCircuits(Ein, Ncrcs, typ, flip, sv, vis)
%% randomCircuits: obtain and normalize random set of manually-drawn contours
% This function blah
%
% Usage:
%   CRCS = randomCircuits(Ein, Ncrcs, typ, flip, sv, vis)
%
% Input:
%   Ein: Experiment object to draw from to generate contour data
%   Ncrcs: number of random Seedlings to analyze
%   typ: 0 to get contours of Seedlings, 1 to get contours of PreHypocotyl
%   flip: inflate dataset with flipped versions of each Hypocotyl
%   sv: save figures as .fig and .tiff files
%   vis: boolean to plot figures or not
%
% Output:
%   CRCS: CircuitJB array of manually-drawn contours from inputted Experiment Ein
%

%% Initialize object array of Seedlings/Hypocotyl to draw contours for
S = Ein.combineSeedlings;
sIdx = randi(numel(S), 1, Ncrcs);
if flip
    CRCS = makeCircuits(Ncrcs * 2);
else
    CRCS = makeCircuits(Ncrcs);
end

%% Draw contours at random frame from random Seedling/Hypocotyl
cIdx = 1;
for k = sIdx
    rs = S(k);
    
    if flip
        [org, flp] = getCircuit(rs, typ, flip);
        CRCS(cIdx) = org;
        cIdx       = cIdx + 1;
        CRCS(cIdx) = flp;
        cIdx       = cIdx + 1;
    else
        CRCS(cIdx) = getCircuit(rs, typ, flip);
        cIdx = cIdx + 1;
    end
    cla;clf;
end

if sv
    nm = sprintf('%s_%drandomCircuits_circuits', datestr(now, 'yymmdd'), Ncrcs);
    save(nm, '-v7.3', 'CRCS');
end

%% Show 8 first images and masks, unless < 8 contours drawn
if vis
    if Ncrcs < 8
        N = Ncrcs;
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
end
end

function c = makeCircuits(n)
%% makeCircuits: subfunction to create n number of individual CircuitJB objects
% The repmat creates multiple copies of the same handle to an individual object, instead of creating
% multiple handles to individual objects.
c = repmat(CircuitJB, 1, n);
for i = 1 : n
    c(i) = CircuitJB;
end
end

function [crc, flp] = getCircuit(rs, typ, flip)
%% getCircuit: subfunction to manually-draw contour on random frame of inputted Seedling

% Get a random good frame from Seedling's lifetime
frms = rs.getGoodFrames;
rFrm = frms(randi(length(frms), 1));

% Get image from either Seedling or Hypocotyl
if typ
    rs = rs.getPreHypocotyl(rFrm);
    im  = rs.getImage('gray');
    org = sprintf('%s_%s_%s_%s_Frm%d', rs.ExperimentName, rs.GenotypeName, rs.SeedlingName, ...
        rs.HypocotylName, rFrm);
else
    im  = rs.getImage(rFrm, 'gray');
    org = sprintf('%s_%s_%s_Frm%d', rs.ExperimentName, rs.GenotypeName, rs.SeedlingName, rFrm);
end

% Set image and origin data for CircuitJB
crc = CircuitJB('Origin', org);
crc.setImage(1, 'gray', im);

% Draw Outline and AnchorPoints and normalize coordinates
crc.DrawOutline(1);
crc.DrawAnchors(1);
crc.ConvertRawPoints;
crc.CreateRoutes;

% Set Contour for this object
if typ
    rs.setContour(crc, 'org');
else
    rs.setContour(rFrm, crc)
end

% Extract manual contour from flipped image
if flip
    flpim = rs.FlipMe;
    org = sprintf('flip_%s_%s_%s_%s_Frm%d', rs.ExperimentName, rs.GenotypeName, rs.SeedlingName, ...
        rs.HypocotylName, rFrm);
    
    flp = CircuitJB('Origin', org);
    flp.setImage(1, 'gray', flpim);
    
    flp.DrawOutline(1);
    flp.DrawAnchors(1);
    flp.ConvertRawPoints;
    flp.CreateRoutes;
    
    if typ
        rs.setContour(flp, 'flp');
    else
        rs.setContour(rFrm, flp)
    end
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
nm = sprintf('%s_%drandomCircuits_%s', datestr(now, 'yymmdd'), N, im);
set(fig,'Color','w');
savefig(fig, nm);
saveas(fig, nm, 'tiffn');
end


