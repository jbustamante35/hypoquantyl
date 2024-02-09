function mstc = shapeMPatch(pinn, pout, pzero)
%% shapeMPatch: stitch and re-order inner-outer midline patch
%
% Usage:
%   mstc = shapeMPatch(pinn, pout, pzero)
%
% Input:
%   pinn: inner patch
%   pout: outer patch
%   pzero: zero-center around bottom center point
%
% Output:
%   mstc: stitched and re-shaped patch

minn = reshape(pinn, [20 , 50 , 2]);
mout = reshape(pout, [20 , 50 , 2]);
mstc = [flip(minn, 1) ; mout];

if pzero
    % Center to bottom center point
    ux = mstc(20,1,1);
    uy = mstc(20,1,2);

    mstc(:,:,1) = mstc(:,:,1) - ux;
    mstc(:,:,2) = mstc(:,:,2) - uy;
end
end