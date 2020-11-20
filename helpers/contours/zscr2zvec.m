function [zvec , zmid , ztng , znrm] = zscr2zvec(zscr, nsegs, evecs, mns, scl)
%% zscr2zvec: convert Z-Vector scores to full vector
% Description
%
% Usage:
%    [zvec , zmid , ztng , znrm] = zscr2zvec(scr, nsegs, evecs, mns, scl)
%
% Input:
%   scr: pc scores of the Z-Vector
%   nsegs: number of segments to split into
%   evecs: eigenvectors from dataset
%   mns: mean values from dataset
%   scl: scalar for tangent and normal vectors (optional)
%
% Output:
%   zvec: Z-Vector expanded and converted from PC scores
%   zmid: midpoint coordinates of the converted Z-Vector
%   ztng: tangent vector coordinates of the converted Z-Vector
%   znrm: normal vector coordinates of the converted Z-Vector
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%% Project to original reference frame and convert to Z-Vector
if nargin < 5
    scl = 1;
end

zprj = pcaProject(zscr, evecs, mns, 'scr2sim');
zcnv = zVectorConversion(zprj, nsegs, 1, 'rev');

%% Add back normal vector and split into all coordinate types
[znrm , zvec] = addNormalVector(zcnv(:,1:2), zcnv(:,3:4), 0, 1);
zmid          = zvec(:,1:2);
ztng          = (zvec(:,3:4) * scl) + zmid;
znrm          = (znrm * scl) + zmid;

end
