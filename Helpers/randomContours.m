function CTRS = randomContours(Ein, Nseeds, max_size, typ, p, vis)
%% randomContours: obtain and normalize random set of contours
% This function blah
%
% Usage:
%   ctrs = randomContours(exp_in, num_seeds, max_size, p, vis)
%
% Input:
%   exp: Experiment object to generate contour data
%   num_seeds: number of random Seedlings to analyze
%   max_size: number of coordinates to normalize boundaries
%   typ: 0 to get contours of Seedlings, 1 to get contours of PreHypocotyl
%   p: length of pause time between plotting figure
%   vis: boolean to plot figures or not
%
% Output:
%   ctrs: various data from contours
%

%% Initialize object array of Seedlings
S    = Ein.combineSeedlings;
sIdx = randi(numel(S), 1, Nseeds);
CTRS = repmat(ContourJB, 1, Nseeds);

%% Get contour at random frame from random Seedling 
cIdx = 1;
for k = sIdx        
    rs         = S(k);
    CTRS(cIdx) = getContour(rs, typ, max_size);
    cIdx = cIdx + 1;
end

%% Visualize output if desired
if vis
    figure;
    for k = 1 : Nseeds
        im = CTRS(k).getGrayImageAtFrame(1);
        bw = CTRS(k).getBWImageAtFrame(1);
        
        % Initial and Interpolated boundaries on grayscale image
        subplot(121);
        imagesc(im), colormap gray, axis image;
        hold on;
        plot(CTRS(k).Bounds(:,2), CTRS(k).Bounds(:,1), 'rx');
        plot(CTRS(k).Interps(:,2), CTRS(k).Interps(:,1), 'g.');
        hold off;

        % Initial and Interpolated boundaries on bw image
        subplot(122);
        imagesc(bw), colormap gray, axis image;
        hold on;
        plot(CTRS(k).Bounds(:,2), CTRS(k).Bounds(:,1), 'rx');
        plot(CTRS(k).Interps(:,2), CTRS(k).Interps(:,1), 'g.');
        hold off;

        pause(p);

    end    
end

end

function ctr = getContour(rs, tp, sz)
%% getContour: subfunction to extract contour from image and store various data
% This function takes in either a Seedling or Hypocotyl as input and outputs a ContourJB object and
% stores grayscale and bw image data and its origin.
% 
% Input:
%   rs: Seedling to extract contour
%   tp: 0 to extract contour from Seedling, 1 to extract contour from that Seedling's Hypocotyl
%   sz: 
% 
% Output:
%   ctr: contour extracted from image at random frame 
% 
    % Random frame from Seedling's lifetime
    rFrm    = randi(rs.getLifetime, 1);
    
    % Extract either Seedling or Hypocotyl image
    if tp
        im      = rs.getPreHypocotyl(rFrm).getImageData('gray');
        bw      = rs.getPreHypocotyl(rFrm).getImageData('bw');
    else
        im      = rs.getImageData(rFrm, 'gray');
        bw      = rs.getImageData(rFrm, 'bw');
    end
    
    % Extract and set data for contour 
    ctr = extractContour(bw, sz);    
    orgn = sprintf('%s_%s_%s_Frm%d', rs.ExperimentName, rs.GenotypeName, rs.getSeedlingName, rFrm);
    
    ctr.setGrayImageAtFrame(im, 1);
    ctr.setBWImageAtFrame(bw, 1);       
    ctr.setOrigin(orgn);

end


