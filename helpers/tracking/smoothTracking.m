function [nprf , nrgn] = smoothTracking(prf, GTHRESH, CSMOOTH)
%% smoothTracking:
% Multi-fix

if nargin < 2; GTHRESH = 10; end
if nargin < 3; CSMOOTH = 5; end

%
sig  = gradient(prf) < 0 | gradient(prf) > GTHRESH;
sig  = imclose(sig, ones(CSMOOTH, 1));
asig = regionprops(sig, 'PixelIdxList');
zsig = arrayfun(@(x) [ ...
    zeros(x.PixelIdxList(1),1) ; ones(numel(x.PixelIdxList),1) ; ...
    zeros(numel(sig) - numel(([zeros(x.PixelIdxList(1),1) ; ...
    ones(numel(x.PixelIdxList),1)])), 1)], asig, 'UniformOutput', 0);
nrgn = numel(zsig);

% Get indices and remove any at first and last point
ridx = arrayfun(@(x) x.PixelIdxList, asig, 'UniformOutput', 0);
ri   = cellfun(@(x) x(1) - 1, ridx, 'UniformOutput', 0);
rf   = cellfun(@(x) x(end) + 1, ridx, 'UniformOutput', 0);
igud = ~cellfun(@(x) x <= 0 || x >= numel(sig), ri);
fgud = ~cellfun(@(x) x <= 0 || x >= numel(sig), rf);
idx  = logical(igud .* fgud);
ridx = ridx(idx);
ri   = ri(idx);
rf   = rf(idx);

%
slp  = cellfun(@(i,f) (prf(f) - prf(i)) / (f - i), ri, rf, 'UniformOutput', 0);
dL   = cellfun(@(i,f) 1 : (f - i - 1), ri, rf, 'UniformOutput', 0);
iff  = @(i,s,dx) prf(i) + s * dx;
pfix = cellfun(@(i,s,dx) iff(i,s,dx), ri, slp, dL, 'UniformOutput', 0);
nprf = prf;

% Output fixed profile
nprf(cat(1, ridx{:})) = cat(2, pfix{:});
end

% If I want to switch to single-fix
% rgn  = imclose(sig, ones(7, 1));
% ridx = find(rgn);
% ri   = ridx(1) - 1;
% rf   = ridx(end) + 1;
% slp  = (prf(rf) - prf(ri)) / (rf - ri);
% iff  = @(dx) prf(ri) + slp * dx;
% dL   = 1 : (rf - ri - 1);
% pfix = iff(dL);
% nprf = prf;
% nprf(ridx) = pfix;
