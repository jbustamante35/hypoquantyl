function mline = pcaMidline(crv, pcv, pmv, slens, mpts, ncv, nmv)
%% pcaMidline: generate midline through PCA regression from dataset
%
% Usage:
%   mline = pcaMidline(crv, pcv, pmv, slens, mpts, ncv, nmv)
%
% Input:
%   crv:
%   cpc: PCA object for contours
%   mpc: PCA object for midlines
%   slens:
%   mpts:
%   ncv:
%   nmv:
%
% Output:
%   mline:

if nargin < 4; slens = [53 , 52 , 53 ,51]; end
if nargin < 5; mpts  = 50;                 end
if nargin < 6; ncv   = pcv.NumberOfPCs;    end
if nargin < 7; nmv   = pmv.NumberOfPCs;    end

%
if ncv ~= pcv.NumberOfPCs
    cscrs = pcv.PCAScores(':', ncv);
    cvecs = pcv.EigVecs(ncv);
else
    cscrs = pcv.PCAScores;
    cvecs = pcv.EigVecs;
end

if nmv ~= pmv.NumberOfPCs
    mscrs = pmv.PCAScores(':', nmv);
    mvecs = pmv.EigVecs(nmv);
else
    mscrs = pmv.PCAScores;
    mvecs = pmv.EigVecs;
end

cscr = pcaProject(crv(:)', cvecs, pcv.MeanVals, 'sim2scr');

% PCA Regression and Re-Project to midline space
mslv  = cscrs \ mscrs;
mpre  = cscr * mslv;
mprj  = pcaProject(mpre, mvecs, pmv.MeanVals, 'scr2sim');
msz   = round(size(pmv.InputData,2) / 2);
mline = [mprj(1 : msz)  ; mprj(msz + 1 : end)]';

% Anchor start to contour's base point and end point
[~ , tidx]   = getSegment(crv, 2, slens);
[~ , bidx]   = getSegment(crv, 4, slens);
mline(1,:)   = crv(bidx(round(numel(bidx) / 2)),:);
mline(end,:) = crv(tidx(round(numel(tidx) / 2)),:);

% Interpolate
mline = interpolateOutline(mline, mpts);
end
