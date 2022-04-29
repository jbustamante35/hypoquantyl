function [regr , vtrp] = measureREGR(vinn, varargin)
%% measureREGR: measure Elemental Growth Rate (EGR)
%
% Usage:
%   [regr , vtrp] = measureEGR(vinn, varargin)
%
% Input:
%   vinn: input velocity profile
%   varargin: various inputs
%       fsmth: smoothing disk size
%       xtrp: interpolation size for frames (x-axis)
%       ytrp: interpolation size for arclength (y-axis)
%
% Output:
%   regr: relative elemental growth rate
%   vtrp: interpolated velocity profile

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

vtrp = interpolateGrid(vinn, xtrp, ytrp, fsmth);
regr = gradient(vtrp')';
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Misc Options
p.addOptional('xtrp', 1000);
p.addOptional('ytrp', 500);
p.addOptional('fsmth', 5);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
