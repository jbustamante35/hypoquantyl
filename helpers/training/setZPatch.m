function [zpatch, patchData] = setZPatch(zSlice, img, SCL, DIM, VER, dom)
%% setZPatch: set Z-Patch from Z-Vector slice
%
%
% Usage:
%   [zpatch, patchData] = setZPatch(zSlice, img, SCL, DIM, VER)
%
% Input:
%   zSlice: [6 x 1] vector defining midpoint-tangent-normal of a Z-Vector slice
%   img: grayscale image corresponding to zSlice
%   SCL: distance to scale up the tangent-normal vector
%   DIM: use tangent 'tng' or normal 'nrm' to set base of envelope [for VER 1]
%   MTH: method to run [old|new]
%
% Output:
%   zpatch: [SCL*2 x SCL*2] matrix mapping coordinate patch to image
%   patchData: extra data used to generate the image patch
%

%% Set default scale factor scl to 10% of image size if not set
if nargin < 3
    VER = 2;                       % Default to version 2
    SCL = ceil(size(img,1) * 0.1); % Scale by 10% of image size
    DIM = 'tng';                   % Set from tangent vector
end

switch VER
    case 1
        [zpatch, patchData] = runVersion1(zSlice, img, SCL, DIM);
        
    case 2
        [zpatch, patchData] = runVersion2(zSlice, img, SCL);
        
    case 3
        scls    = SCL;
        domSize = DIM;
        [zpatch, patchData] = runVersion3(zSlice, img, scls, dom, domSize);
        
    case 4
        % Scales, Domains, and Domain Sizes are now cell arrays
        scls    = SCL;
        domSize = DIM;
        [zpatch, patchData] = runVersion4(zSlice, img, scls, dom, domSize);
        
    otherwise
        fprintf(2, 'Select Method to run [1|2|3]\n');
        zpatch    = [];
        patchData = [];
end

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

function [zpatch, patchData] = runVersion1(zSlice, img, SCL, VER)
%% runVersion1: my old [less efficient] way of getting Z-Patches

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

function [zpatch, patchData] = runVersion2(zSlice, img, SCL)
%% runNewMethod: faster method for getting Z-Patches
% Set tangent and normal to unit length
m  = zSlice(1:2);
t  = zSlice(3:4) - m;
n  = zSlice(5:6) - m;
t  = t / norm(t);
n  = n / norm(n);
Pm = [[t , 0]', [n , 0]' , [m , 1]'];

% Set domain size
d1  = -SCL;
d2  =  SCL;
d3  = round(pdist([d1 ; d2]));

% Create gridded domain
[n1 , n2] = ndgrid(linspace(d1, d2, d3), linspace(d1, d2, d3));
D         = [n1(:) , n2(:) , ones(numel(n1), 1)];
Dn        = Pm * D';
% Dn        = mtimesx(Pm, D, 't', 'speed');
Dn        = double(Dn(1:2,:)');

% Sample image patch from domain coordinates
zpatch = ba_interp2(img, Dn(:,1), Dn(:,2));
zpatch = flipud(reshape(zpatch, [d3 d3])');

% Get Patch Data
boxTop          = [m ,  (SCL * t) + m ,  (SCL * n) + m];
boxBot          = [m ,  -(SCL * t) + m ,  -(SCL * n) + m];
env             = struct('UpperPoints', [], 'LowerPoints', [], 'GridSize', []);
hIdx            = ceil(size(Dn,1) / 2);
env.LowerPoints = Dn(1      : hIdx,:);
env.UpperPoints = Dn(hIdx+1 : end,:);
env.GridSize    = [ceil(size(zpatch,1) / 2) , ceil(size(zpatch,2) * 2)];

patchData = struct('CropBoxTop', boxTop, 'CropBoxBot', boxBot, 'Envelope', env);

end

function [zpatch , zdata] = runVersion3(z, img, scls, dom, domSize)
%% runVersion3: generate patches at multiple scales using general domain
VIS = 0;

% Affine transform of Tangent Bundles
aff = tb2affine(z, scls);

% Sample image at affines
smpl = tbSampler(double(img), aff, dom, domSize, VIS);

% Return Patches sampled from the Core and Displacements along the Core
szS    = size(smpl);
zpatch = reshape(smpl, [szS(1) , prod(szS(2:end))]);

%% Output zdata now has functions to return the patch and domain coordinates
getIdxs   = @(s) extractIndices(s, size(dom,1));
vec2patch = @(i,s) rot90(reshape(zpatch(i, getIdxs(s)), domSize),1);
domCrds   = @(i,s) getDim((squeeze(aff(i,:,:,s)) * dom')',1:2);

% Return the functions in a structure
zdata  = struct('vec2patch', vec2patch, 'domCrds', domCrds);

end

function [zpatch , zdata] = runVersion4(z, img, scls, dom, domSize)
%% runVersion3: generate patches at multiple scales using general domain
VIS = 0;

[zpatch , zdata] = deal(cell(1, numel(dom)));
for d = 1 : numel(dom)
    % Affine transform of Tangent Bundles
    aff = tb2affine(z, scls{d});
    
    % Sample image at affines
    smpl = tbSampler(double(img), aff, dom{d}, domSize{d}, VIS);
    
    % Return Patches sampled from the Core and Displacements along the Core
    szS       = size(smpl);
    zpatch{d} = reshape(smpl, [szS(1) , prod(szS(2:end))]);
    
    %% Output zdata now has functions to return the patch and domain coordinates
    getIdxs   = @(s) extractIndices(s, size(dom{d},1));
%     vec2patch = @(i,s) rot90(reshape(zpatch{d}(i, getIdxs(s)), domSize{d}),1);
    vec2patch = @(i,s) reshape(zpatch{d}(i, getIdxs(s)), domSize{d});
    domCrds   = @(i,s) getDim((squeeze(aff(i,:,:,s)) * dom{d}')',1:2);
    
    % Return the functions in a structure
    zdata{d}  = struct('vec2patch', vec2patch, 'domCrds', domCrds);
    
end

end




