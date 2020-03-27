function [CRCS, figs] = trainCircuits(Ein, cin, typ, flipme, sav, vis, fIdxs)
%% randomCircuits: obtain and normalize random set of manually-drawn contours
% This function takes in a fully-generated Experiment object as input and
% extracts Hypocotyl objects to use as training data (defined in cin matrix)
% for the machine learning segmentation algorithm. The user is prompted to trace
% a manually-drawn contour around a hypocotyl, which will be stored as a
% CircuitJB object. The full array of CircuitJB objects is returned as well,
% although it has been de-referenced from all parent objects to decrease the
% size of the output.
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
% [NOTE] Selecting training data:
% Input is in the form of indexed values in an Experiment object. Indices
% in the cin parameter should map to a frame containing a Seedling or Hypocotyl
% object in a given Genotype object.
%
% The following example would train 4 objects
% [ [ 8 3 10 ];  % 8th genotype , 3rd seedling , 10th frame
%   [ 1 2 1  ];  % 1st genotype , 2nd seedling , 1st  frame
%   [ 3 5 25 ];  % 3rd genotype , 5th seedling , 25th frame
%   [ 5 4 20 ] ] % 5th genotype , 4th seedling , 20th frame
%
% Usage:
%   CRCS = trainCircuits(Ein, cin, typ, flipme, sav, vis)
%
% Input:
%   Ein: Experiment object to draw from to generate contour data
%   cin: matrix mapping to data to train
%   typ: 0 to get contours of Seedlings, 1 to get contours of Hypocotyls
%   flipme: boolean to inflate dataset with flipped versions of each Hypocotyl
%   sav: save figures as .fig and .tiff files
%   vis: boolean to plot figures or not
%   fIdxs: figure indices to plot onto
%
% Output:
%   CRCS: CircuitJB array of manually-drawn contours from Experiment Ein
%   figs: handles to figures if vis is set to true
%

%% Set defaults
if nargin < 3
    typ    = 1;     % [0 to train Seedlings     | 1 to train Hypocotyls]
    flipme = 1;     % [0 to train only original | 1 to train original and flipped]
    sav    = 1;     % [1 to save trained CircuitJB object]
    vis    = 1;     % [1 to show trained contour]
    fIdxs  = 1 : 2; % [figure indices to plot if vis == 1]
end

%% Initialize object array of Seedlings/Hypocotyl to draw contours for
% Select [Genotype , Seedling | Hypocotyl , frame]
nCrcs = size(cin, 1);

% Initialize empty object array
if flipme
    CRCS = makeCircuits(nCrcs * 2);
else
    CRCS = makeCircuits(nCrcs);
end

%% Draw contours at random frame from random Seedling/Hypocotyl
% If flipme parameter set to true, then CircuitJB array is stored in n x 2,
% where the flipped version is stored in dimension 2 of a Hypocotyl object
OBJS = retrieveDataObjects(cin, Ein, typ);
cIdx = 1;
for o = 1 : numel(OBJS)
    obj = OBJS(o);
    frm = cin(o, 3);
    if flipme
        [org, flp] = getCircuit(obj, frm, typ, flipme);
        CRCS(cIdx) = org;
        cIdx       = cIdx + 1;
        CRCS(cIdx) = flp;
        cIdx       = cIdx + 1;
    else
        CRCS(cIdx) = getCircuit(obj, frm, typ, flipme);
        cIdx       = cIdx + 1;
    end
    cla;clf;
end

if sav
    arrayfun(@(x) x.DerefParents, CRCS, 'UniformOutput', 0);
    nm = sprintf('%s_%drandomCircuits_circuits', tdate('s'), nCrcs);
    save(nm, '-v7.3', 'CRCS');
    arrayfun(@(x) x.ResetReference(Ein), CRCS, 'UniformOutput', 0);
end

%% Show 8 first images and masks, unless < 8 contours drawn
if vis
    % Get figure indices or generate new figures
    if isempty(fIdxs)
        fig1 = figure;
        fig2 = figure;
    else
        fig1 = figure(fIdxs(1));
        fig2 = figure(fIdxs(2));
    end
    
    figclr(fig1);
    figclr(fig2);
    
    %% Gallery of Hypocotyls with contours on image
    [n , o] = deal(1 : numel(CRCS));
    p       = deal(horzcat(n,o));
    tot     = numel(CRCS);
    rows    = ceil(tot / 10); % Rows of 10
    cols    = ceil(tot / rows);
    
    for slot = 1 : tot
        try
            % Draw Routes on grayscale image
            set(0, 'CurrentFigure', fig1);
            subplot(rows, cols, slot);
            myimagesc(CRCS(slot).getImage('gray'));
            hold on;
            plt(CRCS(slot).getOutline,    'b.', 4);
            plt(CRCS(slot).getOutline(1), 'r.', 10);
            ttl = sprintf('%s\nSeedling %d Frame %d', ...
                fixtitle(CRCS(slot).GenotypeName), ...
                cin(p(slot),2), cin(p(slot),3));
            title(ttl, 'FontSize', 6)
            
            % Draw Routes bw image
            set(0, 'CurrentFigure', fig2);
            subplot(rows, cols, slot);
            myimagesc(CRCS(slot).getImage('bw'));
            hold on;
            plt(CRCS(slot).getOutline,    'b.', 4);
            plt(CRCS(slot).getOutline(1), 'r.', 10);
            ttl = sprintf('%s\nSeedling %d Frame %d', ...
                fixtitle(CRCS(slot).GenotypeName), ...
                cin(p(slot),2), cin(p(slot),3));
            title(ttl, 'FontSize', 6)
            
        catch e
            fprintf(2, 'Skipping Circuit %d\n%s\n', slot, e.message);
        end
        
    end
    
    if sav
        saveFigure('gray', tot, fig1);
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

function dout = retrieveDataObjects(cin, ex, typ)
%% retrieveDataObjects: return data objects defined by [3 3] input matrix
% Input is in the form of indexed values in an Experiment object. Indices
% in the cin parameter should map to a frame containing a Seedling or Hypocotyl
% object in a given Genotype object.
%
% Example:
% [
%   [ 8 3 10 ] % 8th genotype , 3rd seedling , 10th frame
%   [ 1 2 1  ] % 1st genotype , 2nd seedling , 1st  frame
%   [ 3 5 25 ] % 3rd genotype , 5th seedling , 25th frame
%   [ 5 4 20 ] % 5th genotype , 4th seedling , 20th frame
%               ]

try
    if typ
        dtyp = 'Hypocotyl';
    else
        dtyp = 'Seedling';
    end
    
    dttl = size(cin, 1);
    dout = repmat(eval(dtyp), 1, dttl);
    for d = 1 : dttl
        g = ex.getGenotype(cin(d,1));
        s = g.getSeedling(cin(d,2));
        
        if typ
            dout(d) = s.MyHypocotyl;
        else
            dout(d) = s;
        end
    end
catch e
    x = cin(d,:);
    fprintf('Error extracting %s [ %d %d %d ]\n%s\n', dtyp, x, e.message);
    dout = [];
end

end

function [crc, flp] = getCircuit(obj, frm, typ, flipme)
%% getCircuit: subfunction to manually-draw contour on random frame of Seedling

% Get all un-trained random good frames from Seedling's lifetime
if typ
    % Get selected frame for Hypocotyl object
    org  = sprintf('%s_%s_%s_%s_Frm{%d}', obj.ExperimentName, ...
        obj.GenotypeName, obj.SeedlingName, obj.HypocotylName, frm);
else
    % Get selected frame for Seedling object
    org  = sprintf('%s_%s_%s_Frm{%d}', obj.ExperimentName, ...
        obj.GenotypeName, obj.SeedlingName, frm);
end

% Set original orientation of Circuit or Contour for this object
crc = drawCircuit(obj, org);
if typ
    obj.setCircuit(frm, crc, 'org');
else
    obj.setContour(frm, crc);
end

% Set flipped orientation of Circuit or Contour for this object
if flipme
    forg = sprintf('flip_%s', org);
    flp  = drawCircuit(obj, forg);
    
    if typ
        obj.setCircuit(frm, flp, 'flp');
    else
        obj.setContour(frm, flp);
    end
end
end

function crc = drawCircuit(obj, org)
%% Create CircuitJB and prompt user to draw contour
% Set image and origin data for CircuitJB
crc = CircuitJB('Origin', org, 'Parent', obj);
crc.setParent(obj);
crc.checkFlipped;

% Draw Outline and AnchorPoints and normalize coordinates
% NOTE: At this point, I decided don't want to buffer images anymore. Instead,
% I will just set out-of-frame coordinates as the median background intensity.
crc.DrawOutline(0);
crc.DrawAnchors(0);
crc.ConvertRawPoints;

end

function saveFigure(im, N, fig)
%% Save figure as .fig and .tiff files
nm = sprintf('%s_ManualTraining_%s_%dImages', tdate('s'), im, N);
set(fig, 'Color', 'w');
savefig(fig, nm);
saveas(fig, nm, 'tiffn');

end


