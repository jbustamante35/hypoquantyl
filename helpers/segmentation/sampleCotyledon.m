function [tpatch , tdata] = sampleCotyledon(img, trc, slens, tscl, tlen, nwid, tres, twid, tmth)
%% sampleCotyledon: set ellipse domains at cotyledon ends
% Generate disks from ends of left-right sections
%
% Usage:
%   [tpatch , tdata] = sampleCotyledon(img, trc, slens, ...
%       tscl, tlen, nwid, tres, twid, tmth)
%
% Input:
%   img: image to sample from
%   trc: clipped contour [must have left-right sections]
%   slens: segment lengths of contour (default [53 , 52 , 53 , 51])
%   tscl: tangent scalar to define length from apex [default 5]
%   tlen: number of tangent coordinates [default 50]
%   nwid: width for normals along tangent [default 20]
%   tres: resolution of disk [default 30 x 30]
%   twid: length of segment to compute tangent [default 3]
%   tmth: norm of small window (1) or pca-estimate tangent (2) [default 1]
%
% Output:
%   tpatch: image patch of cotyledon
%   tdata: miscellaneous data from sampling

if nargin < 3; slens = [53 , 52 , 53 , 51]; end
if nargin < 4; tscl  = 5;                   end
if nargin < 5; tlen  = 50;                  end
if nargin < 6; nwid  = 20;                  end
if nargin < 7; tres  = [30 , 30];           end
if nargin < 8; twid  = 3;                   end
if nargin < 9; tmth  = 1;                   end

%% Get points and angles of left and right sections
ltrc = getSegment(trc, 1, slens, [0 , 2]);
rtrc = flipud(getSegment(trc, 3, slens, [0 , 1]));
ttrc = flipud(getSegment(trc, 2, slens, [1 , 1]));
lcrd = ltrc(end,:);
rcrd = rtrc(end,:);

%
[~ , tnrm] = getTangent(ttrc, 0, 2);
tnrm       = tnrm * tscl;
ltng       = getTangent(ltrc, twid, tmth, tnrm);
rtng       = getTangent(rtrc, twid, tmth, tnrm);

%
[lpatch , ldata] = generateCotyledon(img, lcrd, ltng, ...
    1, tscl/tscl, tlen, nwid, tres);
[rpatch , rdata] = generateCotyledon(img, rcrd, rtng, ...
    1, tscl/tscl, tlen, nwid, tres);

%
tpatch      = [lpatch , rpatch];
tdata.ecrds = [ldata  ; rdata];
tdata.tngs  = {[lcrd + (ltng * tscl) ; lcrd] , [rcrd + (rtng * tscl) ; rcrd]};
end

function [tng , nrm] = getTangent(trc, twid, tmth, vcorr)
%% getTangent: estimate tangent of curve
if nargin < 4; vcorr = []; end

if ~twid; twid = size(trc,1) - 1; end
twin  = trc(end - twid : end,:);
if isempty(vcorr); vcorr = twin(end,:) - twin(1,:); end

switch tmth
    case 1
        % Estimate with pca of small segement
        pt    = PcaJB(twin, 1);
        tvecs = pt.EigVecs;
        tng   = sign(vcorr * tvecs) * tvecs';
    case 2
        % Norm of small segment
        tng = vcorr / norm(vcorr);
end

nrm = [-tng(2) , tng(1)];
end