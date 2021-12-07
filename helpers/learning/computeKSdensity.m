function F = computeKSdensity(scrs, bwid)
%% computeKSdensity:
%
%
% Usage:
%   F = computeKSdensity(scrs, bwid)
%   [F , f , g , ga , gb] = computeKSdensity(scrs, bwid, npts, pcA, pcB) [OLD]
%
% Input:
%   scrs:
%   bwid:
%   npts: [old]
%   pcA:  [old]
%   pcB:  [old]
%
% Output:
%   F:
%   f:  [old]
%   G:  [old]
%   gA: [old]
%   gB: [old]
%

%% Defaults
if nargin < 2; bwid = 0.5; end
% if nargin < 3; npts = 100; end
% if nargin < 4; pcA  = 1;   end
% if nargin < 5; pcB  = 2;   end


%% Density of Z-Score normalized PC scores
zs = std(scrs,1,1);
z  = scrs .* (zs .^ -1);
F  = @(x) -log(mvksdensity(z, x .* (zs .^ -1), 'bandwidth', bwid));

% %% Version that only gets distribution of 2 PCs [deprecated]
% minA = min(scrs(:,pcA));
% maxA = max(scrs(:,pcA));
% minB = min(scrs(:,pcB));
% maxB = max(scrs(:,pcB));
%
% %
% sA        = linspace(minA, maxA, npts);
% sB        = linspace(minB, maxB, npts);
% [ga , gb] = ndgrid(sA, sB);
% g         = [ga(:) , gb(:)];
% f         = mvksdensity(scrs(:,[pcA , pcB]), g, 'Bandwidth', bwid);
% f         = reshape(f, [npts , npts]);

end
