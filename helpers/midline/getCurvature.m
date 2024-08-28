function [k , agl , a] = getCurvature(crv, wsz, adrc, fidx)
%% getCurvature: curvature method using changes in angles from eigenvectors
%
% Usage:
%   [k , agl , a] = getCurvature(crv, wsz, adrc, fidx)
%
% Input:
%   crv: coordinates for an [n x 2] curve
%   wsz: size of window to sample
%   adrc: take absolute values of angles [default 0]
%   fidx:
%
% Output:
%   k:
%   agl:
%   a:
%

%%
if nargin < 2; wsz  = 5; end
if nargin < 3; adrc = 0; end
if nargin < 4; fidx = 0; end

% Split to windows and get eigenvectors
ncrv = size(crv,1);
nv   = 1;
pv   = zeros(2,2, (ncrv - wsz) - (wsz + 1));
for i = (wsz + 1) : (ncrv - wsz)
    seg        = crv((i - wsz) : (i + wsz), :);
    ps         = pcaAnalysis(seg, 3);
    pv(:,:,nv) = ps.EigVecs(2);
    nv         = nv + 1;
end

% Correct orientations of eigenvectors
np = size(pv,3);
for i = 2 : np
    for k = 1 : 2
        w1 = pv(:, k, i-1);
        v1 = pv(:, k, i);
        vw = w1' * v1;

        if vw < 0; v1 = -v1; end
        pv(:, k, i) = v1;
    end
end

% Compute changes in angles
w = zeros(2,(np-1));
for i = 1 : (np - 1)
    f = pv(:,:,i);
    v = pv(:,1,i+1);

    w(:,i) = f' * v;
end
agl = atan2(w(2,:),w(1,:));

% Take absolute values of angless
if adrc; agl = abs(agl); end
a = sum(agl);

% Get curvatures
dd  = diff(crv,1,1);
dl  = sum(dd .* dd, 2) .^ 0.5;
wdl = dl(wsz + 1 : (ncrv - wsz) - 1);
k   = agl ./ wdl';

% Visualize changes in angles, curvatures, and curve
if fidx
    figclr(fidx);
    subplot(221); bplt(agl, 'k'); axis square;
    subplot(223); bplt(k, 'k');   axis square;
    subplot(122); plt(crv, 'k-', 3); hold on;
    axis ij; axis square;
    plt(crv(1,:), 'r.', 30); hold off;
end
end


