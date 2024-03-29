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
%       rep: remove negative REGR and high outliers
%
% Output:
%   regr: relative elemental growth rate
%   vtrp: interpolated velocity profile

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

vtrp = interpolateGrid(vinn, 'xtrp', xtrp, 'ytrp', ytrp, 'fsmth', fsmth);
regr = gradient(vtrp')';

if rep
    % Remove negative REGR
    regr(regr < 0) = 0;

    if rep == 2
        % Remove high outliers
        ustd                 = mean(regr, 'all');
        rstd                 = std(regr, [], 'all');
        rthrsh               = ustd + (rstd * 1);
        regr(regr >= rthrsh) = rthrsh;
    end
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Misc Options
p.addOptional('xtrp', 1000);
p.addOptional('ytrp', 500);
p.addOptional('fsmth', 5);
p.addOptional('rep', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
