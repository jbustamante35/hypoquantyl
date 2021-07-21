function [WVECS , wsz , wfrms] = projectTargets(WTRGS, ZVECS, affInv)
%% projectTargets: project segments into Z-Vector reference frames
%
% 
% Usage:
%   [WVECS , wsz , wfrms] = projectTargets(WTRGS, ZVECS, affInv)
%
% Input:
%   WTRGS:
%   ZVECS:
%   affInv:
%   
% Output:
%   WVECS:
%   wsz:
%   wfrms: raw output
%

%% Default projection direction is image to reference frame
if nargin < 3
    affInv = 0;
end

% Projection Direction
tproject = @(z,w) (reconstructPmat(z,0,affInv) * [w , ones(size(w,1),1)]')';

%% Projection Enaction
nsplt = size(WTRGS,1);
midx  = round(nsplt / 2);
nsegs = size(WTRGS,3);
ncrvs = size(WTRGS,4);
wfrms = zeros(nsplt , 2 , nsegs , ncrvs);
for cidx = 1 : ncrvs
    for sidx = 1 : nsegs
        wfrm = tproject(ZVECS(sidx,:,cidx), WTRGS(:,:,sidx,cidx));
        wfrms(:,:,sidx,cidx) = wfrm(:,1:2);
    end
end

% Determine output shape
if ~affInv
    % Extract middle indices to generate contours
    WVECS = permute(squeeze(wfrms(midx,:,:,:)), [2 , 1 , 3]);
    wsz   = size(wfrms);
else
    % Reshape and Vectorize into stacked X-Y
    % nclps: total curves | zttl: total segments | nsplt: size of segments
    wprm  = permute(wfrms, [3 , 4 , 1 , 2]);
    wsz   = size(wprm);
    WVECS = reshape(wprm, [ncrvs * nsegs , nsplt * 2]);
end

end