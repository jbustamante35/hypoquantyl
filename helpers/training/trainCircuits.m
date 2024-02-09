function [CRCS , CRVS] = trainCircuits(Ein, cin, typ, mth, rgn, mbuf, abuf, scl, lb, toPrime, sav, fidxs)
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
% cin = ...
%     [ [ 8 3 10 ];  % 8th genotype , 3rd seedling , 10th frame
%       [ 1 2 1  ];  % 1st genotype , 2nd seedling , 1st  frame
%       [ 3 5 25 ];  % 3rd genotype , 5th seedling , 25th frame
%       [ 5 4 20 ] ] % 5th genotype , 4th seedling , 20th frame
%
% Usage:
%   [CRCS , CRVS] = trainCircuits( ...
%       Ein, cin, typ, mth, rgn, mbuf, abuf, scl, lb, toPrime, sav, fidxs)
%
% Input:
%   Ein: Experiment object to draw from to generate contour data
%   cin: matrix mapping to data to train
%   typ: extract contour from Seedling (0) or Hypocotyl (1) [default 1]
%   sav: save figures [default 0]
%   fidxs: figure indices to plot onto [default 1:2]
%
% Output:
%   CRCS: CircuitJB array of manually-drawn contours from Experiment Ein
%   CRVS: Curve objects used to manipulate contour data from CircuitJB

%% Set defaults
if nargin < 3;  typ     = 1;       end % [0 to train Seedlings     | 1 to train Hypocotyls]
if nargin < 4;  mth     = 'man';   end % Automated (auto) or Manual (man) tracing
if nargin < 5;  rgn     = 'upper'; end % Trace upper or lower regions
if nargin < 6;  mbuf    = 0;       end % Crop box buffering
if nargin < 7;  abuf    = 0;       end % Artificial buffering
if nargin < 8;  scl     = 0;       end % Image scaling size from 101 x 101
if nargin < 9;  lb      = 5;       end % Lower bound to set contour cut-off
if nargin < 10; toPrime = 0;       end % Interpolation size to prime contour
if nargin < 11; sav     = 0;       end % boolean to save CircuitJB objects
if nargin < 12; fidxs   = 1 : 2;   end % figure handle indices to plot

%% Initialize object array of Seedlings/Hypocotyl to draw contours for
nCrcs = size(cin, 1);        % Select [Genotype , Seedling | Hypocotyl , frame]
CRCS  = makeCircuits(nCrcs); % Initialize empty object array

%% Draw contours at random frame from random Seedling/Hypocotyl
% If flipme parameter set to true, then CircuitJB array is stored in n x 2,
% where the flipped version is stored in dimension 2 of a Hypocotyl object
OBJS = retrieveDataObjects(cin, Ein, typ);
cIdx = 1;
for o = 1 : numel(OBJS)
    obj = OBJS(o);
    frm = cin(o, 3);
    CRCS(cIdx) = getCircuit(obj, frm, ...
        typ, mth, rgn, mbuf, abuf, scl, lb, toPrime, fidxs);
    cIdx       = cIdx + 1;
    figclr(fidxs);
end

CRVS = arrayfun(@(x) x.Curves, CRCS);

if sav
    arrayfun(@(x) x.DerefParents, CRCS, 'UniformOutput', 0);
    nm = sprintf('%s_%drandomCircuits_circuits', tdate('s'), nCrcs);
    save(nm, '-v7.3', 'CRCS');
    arrayfun(@(x) x.ResetReference(Ein), CRCS, 'UniformOutput', 0);
end

%% Show 8 first images and masks, unless < 8 contours drawn
if fidxs
    % Gallery of Hypocotyls with contours on image
    showCircuits(CRCS, cin, fidxs);

    if sav
        fnms{1} = sprintf('%s_ManualTraining_gray_%dImages', tdate, nCrcs);
        fnms{2} = sprintf('%s_ManualTraining_bw_%dImages'  , tdate, nCrcs);
        saveFiguresJB(fidxs, fnms);
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

function dout = retrieveDataObjects(cin, ex, typ)
%% retrieveDataObjects: return data objects defined by [3 3] input matrix
% Input is in the form of indexed values in an Experiment object. Indices
% in the cin parameter should map to a frame containing a Seedling or Hypocotyl
% object in a given Genotype object.
%
% Example:
% cin = ...
%   [ [ 8 3 10 ]   % 8th genotype , 3rd seedling , 10th frame
%     [ 1 2 1  ]   % 1st genotype , 2nd seedling , 1st  frame
%     [ 3 5 25 ]   % 3rd genotype , 5th seedling , 25th frame
%     [ 5 4 20 ] ] % 5th genotype , 4th seedling , 20th frame

try
    if typ; dtyp = 'Hypocotyl'; else; dtyp = 'Seedling'; end

    dttl = size(cin, 1);
    dout = repmat(eval(dtyp), 1, dttl);
    for d = 1 : dttl
        g = ex.getGenotype(cin(d,1));
        s = g.getSeedling(cin(d,2));

        if typ; dout(d) = s.MyHypocotyl; else; dout(d) = s; end
    end
catch e
    x = cin(d,:);
    fprintf('Error extracting %s [ %d , %d , %d ]\n%s\n', dtyp, x, e.message);
    dout = [];
end
end

function crc = getCircuit(obj, frm, typ, mth, rgn, mbuf, abuf, scl, lb, toPrime, fidxs)
%% getCircuit: manually-draw contour on random frame of Seedling
if nargin < 3;  typ     = 1;       end
if nargin < 4;  mth     = 'man';   end
if nargin < 5;  rgn     = 'upper'; end
if nargin < 6;  mbuf    = 0;       end
if nargin < 7;  abuf    = 0;       end
if nargin < 8;  scl     = 0;       end
if nargin < 9;  lb      = 5;       end
if nargin < 10; toPrime = 0;       end
if nargin < 11; fidxs   = 1:2;     end

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
crc = drawCircuit(obj, org, mth, rgn, mbuf, abuf, scl, lb, toPrime, fidxs);
if typ; obj.setCircuit(frm, crc); else; obj.setContour(frm, crc); end
end

function crc = drawCircuit(obj, org, mth, rgn, mbuf, abuf, scl, lb, toPrime, fidxs)
%% Create CircuitJB and prompt user to draw contour
if nargin < 3;  mth     = 'man';   end
if nargin < 4;  rgn     = 'upper'; end
if nargin < 5;  mbuf    = 0;       end
if nargin < 6;  abuf    = 0;       end
if nargin < 7;  scl     = 0;       end
if nargin < 8;  lb      = 5;       end
if nargin < 9;  toPrime = 0;       end
if nargin < 10; fidxs   = 1:2;     end

% Set image and origin data for CircuitJB
crc = CircuitJB('Origin', org, 'Parent', obj);
crc.setParent(obj);
crc.checkFlipped;
crc.setProperty('MANBUF', mbuf);
crc.setProperty('ARTBUF', abuf);
crc.setProperty('IMGSCL', scl);
crc.setProperty('LBOUND', lb);

% Draw Outline and AnchorPoints and normalize coordinates
% NOTE: At this point, I decided don't want to buffer images anymore. Instead,
% I will just set out-of-frame coordinates as the median background intensity.
crc.DrawOutline(rgn, [], mbuf, abuf, scl, toPrime, fidxs(1));
crc.ConvertRawOutlines(lb, 'gray', rgn, [], mbuf, abuf, scl);
crc.DrawAnchors(mth, rgn, [], mbuf, abuf, scl, fidxs(2));
crc.ConvertRawPoints(lb, 'gray', rgn, [], mbuf, abuf, scl);
crc.ReconfigInterpOutline('Full');
crc.ConvertRawPoints(lb, 'gray', rgn, [], mbuf, abuf, scl);
crc.Full2Clipped;
crc.CreateCurves('redo');
end

function showCircuits(crcs, cin, fidxs)
%% showCircuits: display tracing results
if nargin < 3; fidxs = 1 : 2; end
figclr(fidxs);
[n , o] = deal(1 : numel(crcs));
p       = deal(horzcat(n,o));
tot     = numel(crcs);
rows    = ceil(tot / 10); % Rows of 10
cols    = ceil(tot / rows);

for slot = 1 : tot
    try
        % Draw Routes on grayscale image
        figclr(fidxs(1), 1);
        subplot(rows, cols, slot);
        myimagesc(crcs(slot).getImage('gray'));
        hold on;
        plt(crcs(slot).getOutline(':', 'Full'),    'g-', 2);
        plt(crcs(slot).getOutline(':', 'Clip'),    'y-', 2);
        plt(crcs(slot).getAnchorPoints, 'r.', 10);
        ttl = sprintf('%s\nSeedling %d Frame %d', ...
            fixtitle(crcs(slot).GenotypeName), ...
            cin(p(slot),2), cin(p(slot),3));
        title(ttl, 'FontSize', 6);

        % Draw Routes bw image
%         figclr(fidxs(2), 1);
%         subplot(rows, cols, slot);
%         myimagesc(crcs(slot).getImage('bw'));
%         hold on;
%         plt(crcs(slot).getOutline(':', 'Full'),    'g-', 2);
%         plt(crcs(slot).getOutline(':', 'Clip'),    'y-', 2);
%         plt(crcs(slot).getAnchorPoints, 'r.', 10);
%         ttl = sprintf('%s\nSeedling %d Frame %d', ...
%             fixtitle(crcs(slot).GenotypeName), ...
%             cin(p(slot),2), cin(p(slot),3));
%         title(ttl, 'FontSize', 6);

        drawnow;
    catch e
        fprintf(2, 'Skipping Circuit %d\n%s\n', slot, e.message);
    end
end
end