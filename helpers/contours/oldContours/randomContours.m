function CTRS = randomContours(Ein, Nseeds, ncrds, typ, flp, p, fidx)
%% randomContours: obtain and normalize random set of contours
% This function blah
%
% Usage:
%   ctrs = randomContours(Ein, Nseeds, max_size, typ, flp, p, vis)
%
% Input:
%   exp: Experiment object to draw from
%   Nseeds: number of random Seedlings to analyze [default 8]
%   ncrds: number of coordinates to normalize contour [default 209]
%   typ: extract contour from Seedling (0) or Hypocotyl (1) [default 1]
%   flp: boolean to extract contour of flipped version [default 1]
%   p: length of pause time between plotting figure [default 0.5]
%   fidx : figure handle index to show results [default 0]
%
% Output:
%   CTRS: ContourJB objects

if nargin < 2; Nseeds = 8;   end
if nargin < 3; ncrds  = 209; end
if nargin < 4; typ    = 1;   end
if nargin < 5; flp    = 1;   end
if nargin < 6; p      = 0.5; end
if nargin < 7; fidx   = 0;   end

%% Initialize object array of Seedlings
S    = Ein.combineSeedlings;
sIdx = pullRandom(S, Nseeds, 0);
CTRS = repmat(ContourJB, 1, Nseeds);

%% Get contour at random frame from random Seedling
cIdx = 1;
for k = sIdx
    rs = S(k);
    if flp
        [org , flp] = getContour(rs, typ, flp, ncrds);
        CTRS(cIdx)  = org;
        cIdx        = cIdx + 1;
        CTRS(cIdx)  = flp;
        cIdx        = cIdx + 1;
    else
        CTRS(cIdx) = getContour(rs, typ, flp, ncrds);
        cIdx       = cIdx + 1;
    end
end

%% Visualize output
if fidx
    figclr(fidx);
    for k = 1 : Nseeds
        img = CTRS(k).getImage(1, 'gray');
        bw  = CTRS(k).getImage(1, 'bw');

        % Initial and Interpolated boundaries on grayscale image
        subplot(121);
        myimagesc(img{1});
        hold on;
        plot(CTRS(k).Outline(:,2), CTRS(k).Outline(:,1), 'rx');
        plot(CTRS(k).InterpOutline(:,2), CTRS(k).InterpOutline(:,1), 'g.');
        hold off;

        % Initial and Interpolated boundaries on bw image
        subplot(122);
        myimagesc(bw{1});
        hold on;
        plot(CTRS(k).Outline(:,2), CTRS(k).Outline(:,1), 'rx');
        plot(CTRS(k).InterpOutline(:,2), CTRS(k).InterpOutline(:,1), 'g.');
        hold off;

        pause(p);
    end
end
end

function [cntr, flp] = getContour(rs, typ, flp, sz)
%% getContour: subfunction to extract contour from image and store various data
% This function takes in either a Seedling or Hypocotyl as input and outputs a
% ContourJB object and stores grayscale and bw image data and its origin.
%
% Input:
%   rs: Seedling to extract contour
%   typ: extract contour from Seedling (0) or Hypocotyl (1) [default 1]
%   flp: boolean to extract contour of flipped version [default 1]
%   sz: number of coordinates to normalize all contours [default 209]
%
% Output:
%   ctr: contour extracted from image at random frame
%

if nargin < 2; typ = 1;   end
if nargin < 3; flp = 1;   end
if nargin < 4; sz  = 209; end

% Random frame from Seedling's lifetime
frms = rs.getGoodFrames;
rFrm = frms(randi(length(frms), 1));

% Extract original and flipped for either Seedling or Hypocotyl image
if typ
    hyp  = rs.getPreHypocotyl(rFrm);
    img  = hyp.getImage('gray');
    bw   = hyp.getImage('bw');

else
    img = rs.getImage(rFrm, 'gray');
    bw  = rs.getImage(rFrm, 'bw');
end

% Extract and set data for contour
cntr = extractContour(bw, sz);
orgn = sprintf('%s_%s_%s_Frm%d', rs.ExperimentName, rs.GenotypeName, rs.getSeedlingName, rFrm);

cntr.setImage(1, 'gray', img);
cntr.setImage(1, 'bw', bw);
cntr.setOrigin(orgn);

if flp
    % Extract and set data for flipped contour
    [flpim , flpbw] = hyp.FlipMe;
    flp             = extractContour(flpbw, sz);
    orgf            = sprintf('%s_%s_%s_Frm%d_flip', ...
        rs.ExperimentName, rs.GenotypeName, rs.getSeedlingName, rFrm);

    flp.setImage(1, 'gray', flpim);
    flp.setImage(1, 'bw', flpbw);
    flp.setOrigin(orgf);
end
end


