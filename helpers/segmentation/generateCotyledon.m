function [cpatch , cdata] = generateCotyledon(img, mcrd, tcrd, mth, tscl, tlen, nwid, dres)
%% generateCotyledon
%
% Usage:
%   [cpatch , cdata] = generateCotyledon(img, mcrd, tcrd, ...
%       mth, tscl, tlen, nwid, dres)
%
% Input:
%   img: image to sample onto
%   mcrd: apex coordinate of midine
%   tcrd: tangent vector from midline apex
%   mth: disk a distance from tangent (1) [default] or square along tangent (2)
%   tscl: tangent scalar to define length from apex [default 60]
%   tlen: number of tangent coordinates [default 20]
%   nwid: width for normals along tangent [default 30]
%   dres: resolution of disk [default 100 x 100]
%
% Output:
%   cpatch: image patch of cotyledon
%   cdata: miscellaneous data from sampling

if nargin < 4; mth  = 1;           end
if nargin < 5; tscl = 40;          end
if nargin < 6; tlen = 40;          end
if nargin < 7; nwid = 60;          end
if nargin < 8; dres = [100 , 100]; end

switch mth
    case 1
        %% Split into individual patches
        dscl                = [tlen , nwid];
        [scls , doms , dsz] = setupParams( ...
            'myShps', 1, 'diskScale', dscl, 'diskDomain', dres);

        % Sample image
        tcrds = [mcrd ; (tcrd * tscl) + mcrd];
        tline = interpolateOutline(tcrds, tlen);
        tidx  = size(tline, 1);
        zline = curve2framebundle(tline);

        [~ , cpatch , cdata] = sampleAtDomain(img, zline(tidx,:), ...
            scls{1}, doms{1}, dsz{1});

        cdata = cdata(1 : 2,:)';
    case 2
        %% Generate from midline
        tcrds = [mcrd ; (tcrd * tscl) + mcrd];
        tline = interpolateOutline(tcrds, tlen);

        [cpatch , cdata] = sampleMidline(img, tline, 1, nwid, 'full');

        cdata = [cdata.OuterData.eCrds ; cdata.InnerData.eCrds];
end
end