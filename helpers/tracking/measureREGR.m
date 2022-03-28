function [regr , vtrp] = measureREGR(vinn, fsmth, ftrp, ltrp)
%% measureREGR: measure Elemental Growth Rate (EGR)
%
% Usage:
%   [regr , vtrp] = measureEGR(vinn, fsmth, ftrp, ltrp)
%
% Input:
%   vinn: input velocity profile
%   fsmth: smoothing disk size
%   ftrp: interpolation size for frames (x-axis)
%   ltrp: interpolation size for arclength (y-axis)
%
% Output:
%   regr: relative elemental growth rate
%   vtrp: interpolated velocity profile

if nargin < 2; fsmth = 5;    end % Disk size for smoothing
if nargin < 3; ftrp  = 500;  end % Interpolation size for frames (t)
if nargin < 4; ltrp  = 1000; end % Interpolation size for lenghts (u)

vtrp = interpolateGrid(vinn, ftrp, ltrp, fsmth);
regr = gradient(vtrp')';
end