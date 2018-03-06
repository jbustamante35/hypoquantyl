function CTRS = randomContours(exp_in, num_seeds, max_size, p, vis)
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
%   p: length of pause time between plotting figure
%   vis: boolean to plot figures or not
%
% Output:
%   ctrs: various data from contours
%

%% Initialize object array of Seedlings
S    = exp_in.combineSeedlings;
sIdx = randi(numel(S), 1, num_seeds);
CTRS = repmat(ContourJB, 1, num_seeds);

%% Get contour at random frame from random Seedling 
for i = 1 : num_seeds
    rs      = S(sIdx(i));
    rFrm    = randi(rs.getLifetime, 1);
    im      = rs.getImageData(rFrm, 'gray');
    bw      = rs.getImageData(rFrm, 'bw');
    CTRS(i) = extractContour(bw, max_size);
    
%     [bnds, dL, L, I] = extractContour(bw, max_size);
%     CTRS(i).Bounds  = bnds;
%     CTRS(i).Dists   = dL;
%     CTRS(i).Sums    = L;
%     CTRS(i).Interps = I;

    CTRS(i).setGrayImageAtFrame(im, 1);
    CTRS(i).setBWImageAtFrame(bw, 1);
end

%% Visualize output if desired
if vis
    figure;
    for i = 1 : num_seeds
        im = CTRS(i).getGrayImageAtFrame(1);
        bw = CTRS(i).getBWImageAtFrame(1);
        
        % Initial and Interpolated boundaries on grayscale image
        subplot(121);
        imagesc(im), colormap gray, axis image;
        hold on;
        plot(CTRS(i).Bounds(:,2), CTRS(i).Bounds(:,1), 'rx');
        plot(CTRS(i).Interps(:,2), CTRS(i).Interps(:,1), 'g.');
        hold off;

        % Initial and Interpolated boundaries on bw image
        subplot(122);
        imagesc(bw), colormap gray, axis image;
        hold on;
        plot(CTRS(i).Bounds(:,2), CTRS(i).Bounds(:,1), 'rx';
        plot(CTRS(i).Interps(:,2), CTRS(i).Interps(:,1), 'g.');
        hold off;

        pause(p);

    end    
end

end




