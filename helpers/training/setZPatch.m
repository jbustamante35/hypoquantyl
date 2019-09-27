function [zpatch, patchData] = setZPatch(zSlice, img, SCL, VER)
%% setZPatch: set Z-Patch from Z-Vector slice
%
%
% Usage:
%   [zpatch, patchData] = setZPatch(zSlice, img, SCL, VER)
%
% Input:
%   zSlice: [6 x 1] vector defining midpoint-tangent-normal of a Z-Vector slice
%   img: grayscale image corresponding to zSlice
%   SCL: distance to scale up the tangent-normal vector
%   VER: use tangent 'tng' or normal 'nrm' to set base of envelope
%
% Output:
%   zpatch: [SCL*2 x SCL*2] matrix mapping coordinate patch to image
%   patchData: extra data used to generate the image patch
%

%% Set default scale factor scl to 10% of image size if not set
if nargin < 3
    SCL = ceil(size(img,1) * 0.1); % Scale by 10% of image size
    VER = 'tng';                   % Set from tangent vector
end

%% Crop Box vectors
[boxTop, boxBot] = setBoxBounds(zSlice, SCL);
mid              = zSlice(1:2);
tngTop           = boxTop(3:4);
tngBot           = boxBot(3:4);
nrmTop           = boxTop(5:6);
nrmBot           = boxBot(5:6);

%% Envelope Structure set from requested vector [tangent|normal]
env    = setEnvelopeBounds(mid, nrmTop, nrmBot, tngTop, tngBot, VER);
envTop = env.UpperPoints;
envBot = env.LowerPoints;

%% Z-Patch
hlfsz  = round(env.GridSize(2) / 2);
qrtsz  = round(hlfsz / 2);
sz     = [qrtsz , hlfsz];
zpatch = patch2img(envTop, envBot, sz, img);

%% Extra data for debugging and plotting
patchData = struct('CropBoxTop', boxTop, 'CropBoxBot', boxBot, 'Envelope', env);

end


function [boxTop, boxBot] = setBoxBounds(zSlice, scl)
%% setBoxBounds: set envelope boundaries by scaling normal and tangent vectors
% Subtract mid off of normal and tangent
mid    = zSlice(1:2);
rawtng = zSlice(3:4) - mid;
rawnrm = zSlice(5:6) - mid;

% Scale tangents and normals (and reverse vectors) to patch boundaries
scltngT = (scl * rawtng) + mid;
sclnrmT = (scl * rawnrm) + mid;
scltngB = (-scl * rawtng) + mid;
sclnrmB = (-scl * rawnrm) + mid;

% Store scaled Z-Vector slices
boxTop = [mid , scltngT , sclnrmT];
boxBot = [mid , scltngB , sclnrmB];

end

function env = setEnvelopeBounds(mid, nrmT, nrmB, tngT, tngB, ver)
%% setEnvelopeBounds: convert envelope boundaries to vectors
% Set make envelope boundaries from tangent (tng) or normal (nrm) vectors
switch ver
    case 'tng'
        % Use tangent vector to set upper and lower bounds; normal vectors are
        % used to slide vector through envelope
        topVec = tngT;
        topSld = nrmT;
        botVec = tngB;
        botSld = nrmB;
        
    case 'nrm'
        % Use normal vector to set upper and lower bounds; tangent vectors are
        % used to slide vector through envelope
        topVec = nrmT;
        topSld = tngT;
        botVec = nrmB;
        botSld = tngB;
        
    otherwise
        % Default to using tangents
        topVec = tngT;
        topSld = nrmT;
        botVec = tngB;
        botSld = nrmB;
end

% Define top-bottom points and interpolate to set 1:1 coordinates to image
endPts = [topVec ; botVec];
iscl   = round(pdist(endPts) / 2);
endVec = interpolateOutline(endPts, iscl * 2);

% Set outer envelope vectors
bndTop = (endVec - mid) + topSld;
bndBot = (endVec - mid) + botSld;

% Generate envelope
[eTop, sTop] = generateFullEnvelope(endVec, bndTop, iscl, 'cs');
[eBot, ~]    = generateFullEnvelope(endVec, bndBot, iscl, 'cs');

env = struct('UpperPoints', eTop, 'LowerPoints', eBot, 'GridSize', size(sTop));

end

function [ptcF, ptcT, ptcB] = patch2img(envTop, envBot, sz, img)
%% patch2img: map Z-Patch envelope vectors onto image
% Use patch coordinates to map onto corresponding image and replace
% out-of-bounds coordinates to the median background intensity.

% Interpolate envelope coordinates onto image coordinates
outT = ba_interp2(img, envTop(:,1), envTop(:,2));
ptcT = reshape(outT, sz);

outB = ba_interp2(img, envBot(:,1), envBot(:,2));
ptcB = reshape(outB, sz);

% Combine Top and Bottom envelope images
ptcF = handleFLIP([flipud(ptcT) ; ptcB], 3);

end

