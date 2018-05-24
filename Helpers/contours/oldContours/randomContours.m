function CTRS = randomContours(Ein, Nseeds, max_size, typ, flip, p, vis)
%% randomContours: obtain and normalize random set of contours
% This function blah
%
% Usage:
%   ctrs = randomContours(exp_in, num_seeds, max_size, p, vis)
%
% Input:
%   exp: Experiment object to draw from to generate contour data
%   num_seeds: number of random Seedlings to analyze
%   max_size: number of coordinates to normalize boundaries
%   typ: 0 to get contours of Seedlings, 1 to get contours of PreHypocotyl
%   flip: boolean to extract contour with flipped image to expand dataset
%   p: length of pause time between plotting figure
%   vis: boolean to plot figures or not
%
% Output:
%   CTRS: various data from contours
%

%% Initialize object array of Seedlings
S    = Ein.combineSeedlings;
sIdx = randi(numel(S), 1, Nseeds);
CTRS = repmat(ContourJB, 1, Nseeds);

%% Get contour at random frame from random Seedling
cIdx = 1;
for k = sIdx
    rs = S(k);
    
    if flip
        [org, flp] = getContour(rs, typ, flip, max_size);
        CTRS(cIdx) = org;
        cIdx       = cIdx + 1;
        CTRS(cIdx) = flp;
        cIdx       = cIdx + 1;
    else
        CTRS(cIdx) = getContour(rs, typ, flip, max_size);
        cIdx       = cIdx + 1;
    end
end

%% Visualize output if desired
if vis
    figure;
    for k = 1 : Nseeds
        im = CTRS(k).getImage(1, 'gray');
        bw = CTRS(k).getImage(1, 'bw');
        
        % Initial and Interpolated boundaries on grayscale image
        subplot(121);
        imagesc(im{1}), colormap gray, axis image;
        hold on;
        plot(CTRS(k).Outline(:,2), CTRS(k).Outline(:,1), 'rx');
        plot(CTRS(k).InterpOutline(:,2), CTRS(k).InterpOutline(:,1), 'g.');
        hold off;
        
        % Initial and Interpolated boundaries on bw image
        subplot(122);
        imagesc(bw{1}), colormap gray, axis image;
        hold on;
        plot(CTRS(k).Outline(:,2), CTRS(k).Outline(:,1), 'rx');
        plot(CTRS(k).InterpOutline(:,2), CTRS(k).InterpOutline(:,1), 'g.');
        hold off;
        
        pause(p);        
    end
end
end

function [ctr, flp] = getContour(rs, typ, flip, sz)
%% getContour: subfunction to extract contour from image and store various data
% This function takes in either a Seedling or Hypocotyl as input and outputs a ContourJB object and
% stores grayscale and bw image data and its origin.
%
% Input:
%   rs: Seedling to extract contour
%   typ: 0 to extract contour from Seedling, 1 to extract contour from that Seedling's Hypocotyl
%   flp: boolean to expand dataset by extracting contour of flipped version
%   sz: number of coordinates to normalize all contours
%
% Output:
%   ctr: contour extracted from image at random frame
%
% Random frame from Seedling's lifetime

frms = rs.getGoodFrames;
rFrm = frms(randi(length(frms), 1));

% Extract original and flipped for either Seedling or Hypocotyl image
if typ
    hyp = rs.getPreHypocotyl(rFrm);
    im  = hyp.getImage('gray');
    bw  = hyp.getImage('bw');
    
else
    im = rs.getImage(rFrm, 'gray');
    bw = rs.getImage(rFrm, 'bw');
end

% Extract and set data for contour
ctr  = extractContour(bw, sz);
orgn = sprintf('%s_%s_%s_Frm%d', rs.ExperimentName, rs.GenotypeName, rs.getSeedlingName, rFrm);

ctr.setImage(1, 'gray', im);
ctr.setImage(1, 'bw', bw);
ctr.setOrigin(orgn);

if flip
    % Extract and set data for flipped contour
    [flpim, flpbw] = hyp.FlipMe;
    flp  = extractContour(flpbw, sz);
    orgf = sprintf('%s_%s_%s_Frm%d_flip', rs.ExperimentName, rs.GenotypeName, ...
        rs.getSeedlingName, rFrm);
    
    flp.setImage(1, 'gray', flpim);
    flp.setImage(1, 'bw', flpbw);
    flp.setOrigin(orgf);
end

end


