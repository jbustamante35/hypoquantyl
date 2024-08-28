function len = midline2lengths(mid, pix2mm, msmth)
%% midline2lengths: pipeline to convert midline to arclength to length
%
% Usage:
%   len = midline2lengths(mid, pix2mm)
%
% Input:
%   mid: midline or cell array of midlines
%   pix2mm: function to convert pixels to mm
%   msmth: smoothing interpolation of arclengths [default 5]
%
% Output:
%   len: length in pixels
%
if nargin < 2; pix2mm = []; end
if nargin < 3; msmth  = 0;  end

if iscell(mid)
    crv  = cellfun(@(x) smoothCurve(x), mid, 'UniformOutput', 0);
    alen = cellfun(@(x) x.getArcLength, crv, 'UniformOutput', 0);
    alen = cat(2, alen{:});

    [msz , nfrms] = size(alen);
    alen = interpolateGrid(alen, 'xtrp', nfrms, 'ytrp', msz, 'fsmth', msmth);
    alen = alen(end,:);
else
    % mid = cell2mat(cellfun(@(x) x(end,:), EM{1}{1}, 'UniformOutput', 0));
    nfrms = size(mid,1);
    crv   = smoothCurve(mid);
    alen  = crv.getArcLength;
    alen  = interpolateVector(alen, nfrms, msmth, 'sgolay');

end

if ~isempty(pix2mm)
    len = pix2mm(alen);
else
    len = alen;
end
end