function p = plt(varargin)
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

switch nargin
    case 1
        crd = varargin{1};
        typ = [];
        sz  = [];
        
    case 2
        crd = varargin{1};
        typ = varargin{2};
        sz  = [];
        
    case 3
        crd = varargin{1};
        typ = varargin{2};
        sz  = varargin{3};
        
    case 4
        % Drawnow [calls this function recursively, so it might screw up]
        crd = varargin{1};
        typ = varargin{2};
        sz  = varargin{3};
        
        plt(crd, typ, sz);
        drawnow;
    otherwise
        fprintf(2, 'Incorrect number of input\n');
        return;
end

%% Parse marker types and sizes
D = parseCoords(crd);
M = parseMarkers(typ);
S = parseSizes(sz);

% Remove LineWidth if not being used
if strcmpi(M{end}, 'none') && ~isempty(S)
    S(3:4) = [];
end

p = plot(D{:}, M{:}, S{:}); % Plot it

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
        
    case nd > 2
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
try
    args = cellstr(typ');
catch
    args = {};
end

%% Color
clrstr = 'Color';
clrman = {'r' , 'g' , 'b' , 'c' , 'm' , 'y' , 'k' , 'w' , 'none'};
clrchk = cell2mat(cellfun(@(c) ismember(c, clrman), args, 'UniformOutput', 0));
if any(clrchk)
    clr = {clrstr , typ(clrchk)};
else
    clr = {};
end

%% Marker
mrkstr = 'Marker';
mrkman = {'o' , '+' , '*' , '.' , 'x' , 's' , 'd' , ...
    '^' , 'v' , '>' , '<' , 'p' , 'h'};
mrkchk = cell2mat(cellfun(@(m) ismember(m, mrkman), args, 'UniformOutput', 0));
if any(mrkchk)
    mrk = {mrkstr , typ(mrkchk)};
else
    mrk = {mrkstr , '.'};
%     mrk = {};
end

%% Line Style
lnstr = 'LineStyle';
lnman = {'-' , ':'};
lnchk = cell2mat(cellfun(@(l) ismember(l, lnman), args, 'UniformOutput', 0));
if any(lnchk)
    ln = {lnstr , typ(lnchk)};
else
    ln = {lnstr , 'none'};
%     ln = {};
end

% Return marker types 
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
        msz = {mstr , sz};
        lsz = {lstr , sz};
        
    case 2
        % Marker Size should come first
        msz = {mstr , sz(1)};
        lsz = {lstr , sz(2)};
        
    otherwise
        % Use Matlab's default sizes
        msz = {};
        lsz = {};
end

% Return marker sizes 
S = [msz , lsz];

end

