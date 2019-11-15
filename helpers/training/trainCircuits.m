function [CRCS, figs] = trainCircuits(Ein, cin, typ, flipme, sav, vis)
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
%
% Output:
%   CRCS: CircuitJB array of manually-drawn contours from Experiment Ein
%   figs: handles to figures if vis is set to true
%

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
    if numel(CRCS) < 8
        N = numel(CRCS);
    else
        N = 8;        
    end
    
    rows = ceil(N / 2);
    cols = 2;
    fig1 = figure;
    fig2 = figure;
    for i = 1 : N        
        try
            % Draw Routes on grayscale image
            showImage(CRCS(i).getImage('gray'), fig1, rows, cols);
            hold on;
            plt(CRCS(i).getRawOutline, 'm.', 14);
            plt(CRCS(i).getOutline, 'b-', 3);
            plt(CRCS(i).getRawPoints, 'y+', 14);
            plt(CRCS(i).getAnchorPoints, 'co', 14);
            
            % Draw Routes bw image
            showImage(CRCS(i).getImage('bw'), fig2, rows, colss);
            hold on;
            plt(CRCS(i).getRawOutline, 'm.', 14);
            plt(CRCS(i).getOutline, 'b-', 3);
            plt(CRCS(i).getRawPoints, 'y+', 14);
            plt(CRCS(i).getAnchorPoints, 'co', 14);
            
        catch e
            fprintf(2, 'Skipping Circuit %d\n%s\n', i, e.message);
        end
        
    end
    
    if sav
        saveFigure('gray', N, fig1);
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

function dout = retrieveDataObjects(din, ex, typ)
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
    
    dttl = size(din, 1);
    dout = repmat(eval(dtyp), 1, dttl);
    for d = 1 : dttl
        g = ex.getGenotype(din(d,1));
        s = g.getSeedling(din(d,2));
        
        if typ
            dout(d) = s.MyHypocotyl;
        else
            dout(d) = s;
        end
    end
catch e
    x = din(d,:);
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
% crc.CreateRoutes; % Use of Routes is deprecated [01-23-2019]

end

function showImage(img, fIdx, rows, cols)
%% Show image on given plot of figure
% Default expects only 8 subplots [4 rows, 2 columns]
set(0, 'CurrentFigure', fIdx);
subplot(rows, cols, fIdx);
myimagesc(img);

end

function saveFigure(im, N, fig)
%% Save figure as .fig and .tiff files
nm = sprintf('%s_%dtrainedCircuits_%s', tdate('s'), N, im);
set(fig, 'Color', 'w');
savefig(fig, nm);
saveas(fig, nm, 'tiffn');

end


