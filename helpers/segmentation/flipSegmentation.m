function seg = flipSegmentation(seg, seg_lengths, isz, img, escore, vsn)
%% flipSegmentation: flip all curves from a segmentation result
%
% Usage:
%   seg = flipSegmentation(seg, seg_lengths, isz, img, mscore, vsn)
%
% Input:
%   seg: result from hypoquantyl segmentation
%   seg_lengths: segment lengths
%   isz: image size
%   img: image
%   mscore: function to compute probability
%   vsn: version of curve to flip [init|opt] (default 'init')
%
% Output:
%   seg: same result with flipped results

%% Parse Arguments
if nargin < 2; seg_lengths = [53 , 52 , 53 , 51]; end
if nargin < 3; isz         = 101;                 end
if nargin < 4; img         = [];                  end
if nargin < 5; escore      = [];                  end
if nargin < 6; vsn         = 'init';              end

% Upper Region
uc = seg.uhyp.(vsn).c;
um = seg.uhyp.(vsn).m;
ub = seg.uhyp.(vsn).b;
uz = seg.uhyp.(vsn).z;
ug = seg.uhyp.(vsn).g;
fc = flipAndSlide(uc, seg_lengths, isz);
fm = flipLine(um, isz);
fb = flipLine(ub, isz);
fz = flipZVector(uz, seg_lengths(end));
fz = [fz(:,1:2) + fb , fz(:,3:end)];

% Re-Compute score
if ~isempty(escore); fg = escore(img, fc); else; fg = ug; end

% Lower Region [doesn't need to flip]
% lc = seg.lhyp.c;
% lm = seg.lhyp.m;
% gc = flipAndSlide(lc, seg_lengths, isz);
% gm = flipLine(lm, isz);

% Replace with Flipped
seg.uhyp.(vsn).c = fc;
seg.uhyp.(vsn).m = fm;
seg.uhyp.(vsn).b = fb;
seg.uhyp.(vsn).z = fz;
seg.uhyp.(vsn).g = fg;
% seg.lhyp.c       = gc;
% seg.lhyp.m       = gm;
end