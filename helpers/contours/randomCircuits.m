function CRCS = randomCircuits(Ein, Ncrcs, typ, flp, sav, fidxs)
%% randomCircuits: obtain and normalize random set of manually-drawn contours
% This function takes in a fully-generated Experiment object as input and
% extracts random frames from random Hypocotyl objects to use as training data
% for the machine learning segmentation algorithm. The user is prompted to trace
% a manually-drawn contour around a hypocotyl, which will be stored as a
% CircuitJB object. The full array of CircuitJB objects is returned as well,
% although it has been de-referenced from all parent objects.
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
%   Ncrcs: number of random Seedlings to analyze [default 8]
%   typ: extract contour from Seedling (0) or Hypocotyl (1) [default 1]
%   flipme: boolean to inflate dataset with flipped versions of each Hypocotyl
%   sav: save figures as .png files
%   fidxs: figures handle indices
%
% Output:
%   CRCS: CircuitJB array of manually-drawn contours from Experiment Ein
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

if nargin < 2; Ncrcs  = 8;     end
if nargin < 3; typ    = 1;     end
if nargin < 4; flp    = 1;     end
if nargin < 5; sav    = 0;     end
if nargin < 6; fidxs  = 1 : 2; end

%% Initialize object array of Seedlings/Hypocotyl to draw contours for
if typ; S    = Ein.combineHypocotyls;   else; S    = Ein.combineSeedlings; end
if flp; CRCS = makeCircuits(Ncrcs * 2); else; CRCS = makeCircuits(Ncrcs);  end
sIdx = pullRandom(S, Ncrcs, 0);

%% Draw contours at random frame from random Seedling/Hypocotyl
% If flipme parameter set to true, then CircuitJB array is stored in n x 2,
% where the flipped version is stored in dimension 2 of a Hypocotyl object
cIdx = 1;
for k = sIdx
    rs = S(k);

    if flp
        [org , flp] = getCircuit(rs, typ, flp);
        CRCS(cIdx)  = org;
        cIdx        = cIdx + 1;
        CRCS(cIdx)  = flp;
        cIdx        = cIdx + 1;
    else
        CRCS(cIdx) = getCircuit(rs, typ, flp);
        cIdx       = cIdx + 1;
    end
    figclr(fidxs);
end

if sav
    arrayfun(@(x) x.DerefParents, CRCS, 'UniformOutput', 0);
    nm = sprintf('%s_%drandomCircuits_circuits', tdate('s'), Ncrcs);
    save(nm, '-v7.3', 'CRCS');
    arrayfun(@(x) x.ResetReference(Ein), CRCS, 'UniformOutput', 0);
end

%% Show 8 first images and masks, unless < 8 contours drawn
if fidxs
    if Ncrcs < 8; N = numel(CRCS); else; N = 8; end

    fidx1 = fidxs(1);
    fidx2 = fidxs(2);
    for nidx = 1 : N
        try
            rts = CRCS(nidx).getRoute;

            % Draw Routes on grayscale image
            showImage(nidx, fidx1, CRCS(nidx).getImage('gray'));
            hold on;
            arrayfun(@(x) drawRoutesAndMidPoints(x), rts, 'UniformOutput', 0);

            % Draw Routes bw image
            showImage(nidx, fidx2, CRCS(nidx).getImage('bw'));
            hold on;
            arrayfun(@(x) drawRoutesAndMidPoints(x), rts, 'UniformOutput', 0);
        catch e
            fprintf(2, 'Skipping Circuit %d\n%s\n', nidx, e.message);
        end
    end

    if sav
        fnm = sprintf('%s_%02ddrandomCircuits', tdate, N);
        saveFiguresJB(fidxs, fnm);
    end
end
end

function c = makeCircuits(n)
%% makeCircuits: subfunction to create n number of individual CircuitJB objects
% The repmat creates multiple copies of the same handle to an individual object,
% instead of creating multiple handles to individual objects.
c = repmat(CircuitJB, 1, n);
for i = 1 : n; c(i) = CircuitJB; end
end

function [crc, flp] = getCircuit(rndS, typ, flipme)
%% getCircuit: subfunction to manually-draw contour on random frame of Seedling

% Get all un-trained random good frames from Seedling's lifetime
if typ
    % Get randomly selected untrained frame for Hypocotyl object
    frms = getUntrained(rndS.Parent);
    rFrm = frms(randi(length(frms), 1));
    org  = sprintf('%s_%s_%s_%s_Frm{%d}', rndS.ExperimentName, ...
        rndS.GenotypeName, rndS.SeedlingName, rndS.HypocotylName, rFrm);
else
    % Get randomly selected untrained frame for Hypocotyl object
    frms = getUntrained(rndS);
    rFrm = frms(randi(length(frms), 1));
    org  = sprintf('%s_%s_%s_Frm{%d}', rndS.ExperimentName, ...
        rndS.GenotypeName, rndS.SeedlingName, rFrm);
end

% Set original orientation of Circuit or Contour for this object
crc = drawCircuit(rndS, org);
if typ
    rndS.setCircuit(rFrm, crc, 'org');
else
    rndS.setContour(rFrm, crc);
end

% Set flipped orientation of Circuit or Contour for this object
if flipme
    forg = sprintf('flip_%s', org);
    flp  = drawCircuit(rndS, forg);

    if typ
        rndS.setCircuit(rFrm, flp, 'flp');
    else
        rndS.setContour(rFrm, flp);
    end
end
end

function untrainedFrames = getUntrained(s)
%% Returns frames that have already been trained
goodFrms        = s.getGoodFrames;
h               = s.MyHypocotyl;
all_circuits    = arrayfun(@(x) h.getCircuit(x, 'org'), ...
    goodFrms, 'UniformOutput', 0);
untrainedFrames = find(cellfun(@isempty, all_circuits));
end

function crc = drawCircuit(rndS, org)
%% Create CircuitJB and prompt user to draw contour
% Set image and origin data for CircuitJB
crc = CircuitJB('Origin', org, 'Parent', rndS);
crc.setParent(rndS);
crc.checkFlipped;
%
% Draw Outline and AnchorPoints and normalize coordinates
% NOTE: At this point, I decided don't want to buffer images anymore. Instead,
% I will just set out-of-frame coordinates as the median background intensity.
crc.DrawOutline(0);
crc.DrawAnchors(0, 'auto'); % Use of AnchorPoints is deprecated [02-05-2020]
crc.ConvertRawPoints;
% crc.CreateRoutes; % Use of Routes is deprecated [01-23-2019]
end

function showImage(num, fidx, img)
%% Show image on given plot of figure
% Default expects only 8 subplots [4 rows, 2 columns]
set(0,'CurrentFigure',fidx);
subplot(4, 2, num);
myimagesc(img);
hold on;
end

function drawRoutesAndMidPoints(r)
%% Plot single Route onto figure
crd = r.getInterpTrace;
mid = r.getMidPoint;
plt([crd(:,1) , crd(:,2)], '-', 2);
plt([mid(1)   , mid(2)],   'o', 7);
hold on;
end