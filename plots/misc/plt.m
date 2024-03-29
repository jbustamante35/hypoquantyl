function p = plt(crd, typ, sz)
% function p = plt(varargin)
%% plt: my general plotting function for data with x-/y-coordinates
% I've needed this shortcut enough to justify writing a full function for it. User defines the data
% containing [x y] coordinates as main parameter. Optional are the marker type, marker color, and
% marker size. Default values for marker are the default for the plot() function.
%
% Usage:
%   p = plt(D, typ, sz)
%
% Input:
%   D: 2D data containing x-/y-coordinate
%   typ: marker color and/or marker type (optional)
%   sz: marker size (optional)
%
% Output:
%   p: figure handle for plotted data

if nargin < 2; typ = []; end
if nargin < 3; sz  = []; end

%% Parse marker types and sizes
D = parseCoords(crd);
M = parseMarkers(typ);
S = parseSizes(sz);

% Remove LineWidth if not being used
if strcmpi(M{end}, 'none') && ~isempty(S); S(3:4) = []; end

switch numel(D)
    case 3
        p = plot3(D{:}, M{:}, S{:});
    otherwise
        p = plot(D{:}, M{:}, S{:});
end
end

function D = parseCoords(crd)
%% parseCoords: parse coordinates to determine single or double columns
nd = size(crd,2);
switch nd
    case 1
        % Coordinates are a single column
        D{nd} = crd;

    case 2
        % Data are x-/y-coordinates as column
        D = {crd(:,1) , crd(:,2)};

    case 3
        % 3-D data
        D = {crd(:,1) , crd(:,2) , crd(:,3)};

    case nd > 3
        % Check if transposing would work
        crd2 = crd';
        nd2  = size(crd2,2);

        switch nd2
            case 1
                D{nd2} = crd2;
            case 2
                D = {crd2(:,1) , crd2(:,2)};
            otherwise
                % There's something wrong with the input
                D = {crd2};
        end

    otherwise
        % There's something wrong with the input
        D = {crd};
end
end

function M = parseMarkers(typ)
%% parseMarkers: parse marker argument to figure out Marker and Line type
% try args = cellstr(typ'); catch; args = {}; end

% Defaults
clrstr = 'Color';
mrkstr = 'Marker';
lnstr  = 'LineStyle';
clr    = {};
% mrk    = {mrkstr , '.'};
mrk    = {mrkstr , 'none'};
ln     = {lnstr , 'none'};

% Manifests
% clrman = ['b' , 'r' , 'g' , 'c' , 'm' , 'y' , 'k' , 'w' , 'none'];
clrman = ['b' , 'r' , 'g' , 'c' , 'm' , 'y' , 'k' , 'w'];
mrkman = ['o' , '+' , '*' , '.' , 'x' , 's' , 'd' , ...
    '^' , 'v' , '>' , '<' , 'p' , 'h'];
lnman  = ['-' , ':'];

% Check for Color | Marker | LineStyle
clrchk = ismember(typ, clrman);
mrkchk = ismember(typ, mrkman);
lnchk  = ismember(typ, lnman);

% Return marker types
if any(clrchk); clr = {clrstr , typ(clrchk)}; end
if any(mrkchk); mrk = {mrkstr , typ(mrkchk)}; end
if any(lnchk);  ln  = {lnstr  , typ(lnchk)};  end

% Convert color from hex code
if ~isempty(typ) && startsWith(typ, '#')
    fchk = ~sum([clrchk ; mrkchk ; lnchk]);
    chex = typ(fchk);
    clr  = {clrstr , chex};
end

M = [clr , mrk , ln];
end

function S = parseSizes(sz)
%% parseSizes: parse size argument to determine marker size line width
nargs = numel(sz);
mstr  = 'MarkerSize';
lstr  = 'LineWidth';

switch nargs
    case 1
        % If only 1 argument, set both to same size
        marg = {mstr , sz};
        larg = {lstr , sz};

    case 2
        % [MarkerSize , LineWidth]
        marg = {mstr , sz(1)};
        larg = {lstr , sz(2)};

    otherwise
        % Use Matlab's default sizes
        marg = {};
        larg = {};
end

% Return marker sizes
S = [marg , larg];
end

