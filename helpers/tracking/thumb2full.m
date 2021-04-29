
function [rcntr , rmline, minfo] = thumb2full(c, frm, cntr, mline)
%% thumb2full: remap coordinates from thumbnail image to full resolution image
% Extract Images | Rescale and Remap coordinates
%
%

%%
switch nargin
    case 1
        % Pre-Trained Curve object
        d     = c.Parent.Parent;
        frm   = d.getFrame;
        img   = c.getImage;
        cntr  = c.getTrace;
        mline = c.getMidline('int', 'auto');
        
    case 4
        % Untrained Hypocotyl object with contour and midline
        h   = c;
        d   = [];
        img = h.getImage(frm);
        
    otherwise
        fprintf(2, 'Error with %d inputs\n', nargin);
        [rcntr , rmline , minfo] = deal([]);
        return;
end

%% Meet the Parents
s = h.Parent;
g = s.Parent;

if ~isempty(d)
    % Mirror and slide coordinates if contour is flipped
    csz  = size(cntr,1);
    msz  = size(mline,1);
    isz  = size(img,1);
    
    cslide = [repmat(isz, csz, 1) , zeros(csz, 1)];
    mslide = [repmat(isz, msz, 1) , zeros(msz, 1)];
    
    % Flip and Slide coordinates if using flipped training data
    if d.isFlipped
        cntr  = (fliplr(cntr) * Rmat(90)) + cslide;
        mline = (fliplr(mline) * Rmat(90)) + mslide;
    end
end

%% Remap
% Hypocotyl on non-resized seedling image
simg = s.getImage(frm);
sbox = h.getCropBox(frm);
% scrp = s.getAnchorPoints(frm);

% Cropped seedling [non-resized hypocotyl]
himg = simg(1:sbox(4),1:sbox(3));

% Seedling on full-res image
gimg = g.getImage(frm);
gbox = s.getPData(frm).BoundingBox;
% sprj = scrp + gbox(1:2);

% Rescale thumbnail coordinates back to original
scls    = size(himg) ./ size(img);
rcntrs  = fliplr(fliplr(cntr) .* scls);
rmlines = fliplr(fliplr(mline) .* scls);

% Map seedling coordinates back to full-res image
rcntr  = rcntrs + gbox(1:2);
rmline = rmlines + gbox(1:2);

%% Get some miscellaneous data for visualizing info
minfo = struct('frm', frm, 'img', img, 'himg', himg, 'simg', simg, 'gimg', gimg, ...
    'cntr', cntr, 'mline', mline);

end
