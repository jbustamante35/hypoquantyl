function mpatch = sampleMidline(img, mline, midx, psz, mth)
%% sampleMidline:
%
% Usage:
%   mpatch = sampleMidline(img, mline, midx, psz, mth)
%
% Input:
%   img: image
%   mline: midline
%   midx: index from midline to sample [default 1]
%   psz: size of patch (patch) or distance to envelope (full) [default 20]
%   mth: sampling by single patches ('patch'), full midline ('full', default)
%
% Output:
%   mpatch: cell array of patches (mth = 'patch') or full patch (mth = 'full')
%

%% Defaults
if nargin < 3; midx = 1;      end
if nargin < 4; psz  = 20;     end
if nargin < 5; mth  = 'full'; end

switch mth
    case 'patch'
        %% Split into individual patches
        % Generate square domains to use for sampling image
        toRemove            = [1 , 3 , 4]; % Omit domains for disk and lines
        [sq , s]            = deal([psz , psz]);
        [scls , doms , dsz] = setupParams( ...
            'toRemove', toRemove, 'squareScale', sq, 'squareDomain', s);

        %% Sample image
        zm     = curve2framebundle(mline);
        cm     = sampleAtDomain(img, zm(midx,:), scls{1}, doms{1}, dsz{1}, 0);
        mpatch = reshape(cm, [sq , numel(midx)]);

    case 'full'
        %% Patch from entire midline
        mpatch = getStraightenedMask(mline, img, 0, psz);

    otherwise
        fprintf(2, 'Method %s must be [patch|full]\n', mth);
        mpatch = [];
end
end
