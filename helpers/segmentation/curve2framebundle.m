function fb = curve2framebundle(crv)
%% curve2framebundle: generates a frame bundle from a curve
% This function computes the frame bundle - or tangent bundle - that defines the
% tangents of the points along a curve.
%
% Usage:
%   z = curve2framebundle(crv)
%
% Input:
%   crv: x-/y-coordinates of the curve
%
% Output:
%   z: frame bundle of the curve
%

%%
len = size(crv,1);
tmp = [crv' , crv' , crv']';

%% Compute the tangents vectors along the curve
dc = gradient(tmp')';
dl = sum(dc .* dc, 2).^-0.5;
dc = bsxfun(@times, dc, dl);
dn = [dc(:,2) , -dc(:,1)];
fb = [tmp , dc , dn];

%
fb = fb(len+1 : 2*len, :);

end

