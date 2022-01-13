function [rcntr , rmline , minfo] = thumb2full(c, frm, cntr, mline, rgn, rev)
%% thumb2full: remap coordinates from thumbnail image to full resolution image
% Extract Images | Rescale and Remap coordinates
%
% Usage:
%   [rcntr , rmline , minfo] = thumb2full(c, frm, cntr, mline, rev)
%
% Input:
%   c: Curve or CircuitJB Object
%   frm: frame to remap
%   cntr: contour associated with image
%   mline: midline associated with image
%   rgn: remap 'upper' or 'lower' region (default 'upper')
%   rev: reverse direction of remapping [full2thumb] (default 0)
%
% Output:
%   rcntr: contour remapped to full resolution image (reversed if rev == 1)
%   rmline: midline remapped to full resolution image (reversed if rev == 1)
%   minfo: miscellaneous information about remapping
%

%%
switch class(c)
    case 'Curve'
        d   = c.Parent.Parent;
        img = c.getImage;

        if nargin < 2; frm   = d.getFrame;                  end
        if nargin < 3; cntr  = c.getTrace;                  end
        if nargin < 4; mline = c.getMidline('auto', 'int'); end
        if nargin < 5; rgn   = 'upper';                     end
        if nargin < 6; rev   = 0;                           end

        if d.isFlipped
            % Mirror and slide coordinates if contour is flipped
            csz  = size(cntr,1);
            msz  = size(mline,1);
            isz  = size(img,1);

            cslide = [repmat(isz, csz, 1) , zeros(csz, 1)];
            mslide = [repmat(isz, msz, 1) , zeros(msz, 1)];

            % Flip and Slide coordinates if using flipped training data
            cntr  = (fliplr(cntr) * Rmat(90)) + cslide;
            mline = (fliplr(mline) * Rmat(90)) + mslide;
        end

    case 'Hypocotyl'
        % Untrained Hypocotyl object with contour and midline
        h   = c;
        img = h.getImage(frm);

        if nargin < 2; frm   = 1;       end
        if nargin < 3; cntr  = [];      end
        if nargin < 4; mline = [];      end
        if nargin < 5; rgn   = 'upper'; end
        if nargin < 6; rev   = 0;       end

    otherwise
        [rcntr , rmline , minfo] = deal([]);
        return;
end

% switch nargin
%     case 1
%         % Pre-Trained Curve object
%         d     = c.Parent.Parent;
%         frm   = d.getFrame;
%         img   = c.getImage;
%         cntr  = c.getTrace;
%         mline = c.getMidline('auto', 'int');
%         rgn   = 'upper';
%
%     case 4
%         % Untrained Hypocotyl object with contour and midline
%         h   = c;
%         d   = [];
%         img = h.getImage(frm);
%         rgn = 'upper';
%
%     otherwise
%         fprintf(2, 'Error with %d inputs\n', nargin);
%         [rcntr , rmline , minfo] = deal([]);
%         return;
% end

%% Meet the Parents
s = h.Parent;
g = s.Parent;

% if ~isempty(d)
%     % Mirror and slide coordinates if contour is flipped
%     csz  = size(cntr,1);
%     msz  = size(mline,1);
%     isz  = size(img,1);
%
%     cslide = [repmat(isz, csz, 1) , zeros(csz, 1)];
%     mslide = [repmat(isz, msz, 1) , zeros(msz, 1)];
%
%     % Flip and Slide coordinates if using flipped training data
%     if d.isFlipped
%         cntr  = (fliplr(cntr) * Rmat(90)) + cslide;
%         mline = (fliplr(mline) * Rmat(90)) + mslide;
%     end
% end

%% Remap
% Hypocotyl on non-resized seedling image
simg = s.getImage(frm);
sbox = h.getCropBox(frm, rgn);

% Cropped seedling [non-resized hypocotyl]
switch rgn
    case 'upper'
        himg = simg(1:sbox(4),1:sbox(3));
    case 'lower'
        himg = simg(sbox(2):end,:);
    otherwise
        fprintf(2, 'Region (%s) must be [upper|lower]\n', rgn);
        [rcntr , rmline , minfo] = deal([]);
        return;
end

% Seedling on full-res image
gimg = g.getImage(frm);
gbox = s.getPData(frm).BoundingBox;

% Rescale thumbnail coordinates back to original
scls    = size(himg) ./ size(img);
rcntrs  = fliplr(fliplr(cntr) .* scls);
rmlines = fliplr(fliplr(mline) .* scls);

% Map seedling coordinates back to full-res image
rcntr  = rcntrs + (gbox(1:2) + sbox(1:2));
rmline = rmlines + (gbox(1:2) + sbox(1:2));

%% Get some miscellaneous data for visualizing info
minfo = struct('frm', frm, 'img', img, 'himg', himg, 'simg', simg, 'gimg', gimg, ...
    'cntr', cntr, 'mline', mline);

end
