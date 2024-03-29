function jticks(jtix, varargin)
%% jticks: wrapper to set properties for colorbar
% Uses similar inputs as x/y/z-label, but for the colorbar. The function cticks
% was already taken, so I'm using the letter 'j' for my name.

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

if nargin < 1; jtix = []; end

%% Get colorbar if not given, but exists
if isempty(jbar)
    if ~contains(class(jbar), 'colorbar', 'IgnoreCase', 1)
        jbar = get(gca, 'colorbar');
    else
        jbar = colorbar;
    end
end

% Set Properties
if isempty(jtix); jtix = interpolateVector(jbar.Limits, 5); end
jbar.Ticks = jtix;
end


function args = parseInputs(varargin)
%% Parse input parameters

p = inputParser;
p.addOptional('jbar', []);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end