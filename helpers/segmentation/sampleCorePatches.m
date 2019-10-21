function X = sampleCorePatches(img, Z, scls, dom, domSize, vis)
%% sampleCorePatches: sample image from tangent bundle points
%
%
% Usage:
%   X = sampleCorePatches(img, Z, scls, dom, domSize, vis)
%
% Input:
%   img:
%   Z:
%   scls:
%   dom:
%   domSize:
%   vis:
%
% Output:
%   X:
%

%%
if vis
    cla;clf;
end

X = [];
for d = 1 : numel(dom)
    % Affine transform of Tangent Bundles
    aff = tb2affine(Z, scls{d});
    
    % Sample image at affines
    smpl = tbSampler(double(img), double(aff), dom{d}, domSize{d}, vis);
    
    % Return Patches sampled from the Core and Displacements along the Core
    szS  = size(smpl);
    tmpX = reshape(smpl, [szS(1) , prod(szS(2:end))]);
    X    = [X , tmpX];
end

end

