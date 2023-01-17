function cout = remapCoordinates(timg, oimg, tbox, ocntr, drc)
%% remapCoordinates
%
%
% Usage:
%   cout = remapCoordinates(timg, oimg, tbox, ocntr, drc)
%
% Input:
%   oimg: image of origin step
%   timg: image of target step
%   tbox: cropbox from target (for rev) or origin (for fwd) step image
%   ocntr: contour of origin step
%   drc: direction of step [h2s|s2g|g2s|s2h]
%
% Output:
%   cout: output coordinates after adjustment [scaling/translating]
%

%%
if nargin < 5; drc = 'fwd'; end

switch drc
    case 'g2s'
        ebuf = 1;
        edrc = 'fwd';
        aimg = timg;
        bimg = oimg;
    case 's2h'
        ebuf = 0;
        edrc = 'fwd';
        aimg = timg;
        bimg = oimg;
    case 's2g'
        ebuf = 1;
        edrc = 'rev';
        aimg = oimg;
        bimg = timg;
    case 'h2s'
        ebuf = 1;
        edrc = 'rev';
        aimg = oimg;
        bimg = timg;
    otherwise
        fprintf(2, 'Direction [%s] should be [g2s|s2h|s2g|h2s]\n', drc);
        return;
end

%% Map seedling coordinates back to full-res image
ccorr = size(aimg) - (fliplr(tbox(3:4)) + ebuf);
sz    = size(aimg) - ccorr;
scl   = round(sz ./ size(bimg), 2);

switch edrc
    case 'fwd'
        cout = fliplr(fliplr(ocntr) ./ scl) - tbox(1:2);
    case 'rev'
        cout = fliplr(fliplr(ocntr) .* scl) + tbox(1:2);
end
end

