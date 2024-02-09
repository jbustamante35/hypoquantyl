function fb = curve2framebundle(crv)
%% curve2framebundle: generates a frame bundle from a curve
% This function computes the frame bundle - or tangent bundle - that defines the
% tangents of the points along a curve.
%
% Usage:
%   fb = curve2framebundle(crv)
%
% Input:
%   crv: x-/y-coordinates of the curve
%
% Output:
%   fb: frame bundle of the curve
%

%%
len = size(crv,1);
tmp = [crv' , crv' , crv']';

%% Compute the tangents vectors along the curve
dg = gradient(tmp')';
dl = sum(dg .* dg, 2).^-0.5;
dt = bsxfun(@times, dg, dl);
dn = [dt(:,2) , -dt(:,1)];
fb = [tmp , dt , dn];
fb = fb(len + 1 : 2 * len, :);
end