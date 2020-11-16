function [cntr , mline] = cmscr2cmvec(cmscr, evecs, mns, csize, msize, bk)
%% cmscr2cmvec
% Description
%
% Usage:
%   [cntr , mline] = cmscr2cmvec(cmscr, evecs, mns, csize, msize, bk)
%
% Input:
%   cmscr: PC score for contour-midline complexes
%   evecs: eigenvectors for contour-midlines
%   mns: mean values for contour-midlines
%   csize: number of coordinates used for the contour
%   msize: number of coordinates used for the midline
%   bk: coordinate to add back to original reference frame (optional)
%
% Output:
%   cntr: reconstructed contour
%   mline: reconstructed midline
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%%
if nargin < 6
    bk = 0;
end

v     = pcaProject(cmscr, evecs, mns, 'scr2sim');
r     = reshape(v, [csize + msize , 2]) + bk;
cntr  = r(1 : csize, :);
mline = r(csize + 1 : end, :);

end

