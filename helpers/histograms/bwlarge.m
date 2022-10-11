function [Mout] = bwlarge(Min,n,conn)
if nargin == 1
    n = 1;
end

if nargin < 3;conn = 8;end

Mout = zeros(size(Min));

CC = bwconncomp(Min,conn);

R = regionprops(CC,'PixelIdxList','Area');

for e = 1:min(numel(R),n)

    R = regionprops(CC,'PixelIdxList','Area');
    [J,midx] = max([R.Area]);

    Mout(R(midx).PixelIdxList) = 1;
    Min(R(midx).PixelIdxList) = 0;

    CC = bwconncomp(Min,conn);
end
Mout = logical(Mout);
end