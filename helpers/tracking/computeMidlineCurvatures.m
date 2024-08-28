function [k , j] = computeMidlineCurvatures(mid, varargin)
%% computeMidlineCurvatures: compute curvature of midline
%
% Usage:
%   kmid = computeMidlineCurvatures(mid, varargin)
%
% Input:
%   mid: midline coordinates
%   varargin: various options [see below]
%       mtrp: size to interpolate midline [default []]
%       smth: curvature smoothing filter size [default 8]
%       mth: curvature method [default 'open']
%       ofix: remove string of zeros [default 0]
%
% Output:
%   k: midline curvatures
%   j: misc curvature data
%


%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

if isempty(mtrp); mtrp = size(mid,1); end
mid = interpolateOutline(mid, mtrp);
switch alg
    case 'cwt'
        %
        [j , k] = cwtK(mid, smth, mth);
        k       = abs(k);

        % Remove string of zeros and interpolate
        if ofix; k = interpolateVector(k(k ~= 0), numel(k)); end
    case 'dev'
        % Compute first derivatives
        dx = gradient(mid(:,1));
        dy = gradient(mid(:,2));

        % Compute second derivatives
        ddx = gradient(dx);
        ddy = gradient(dy);

        % Compute curvature
        k = abs(dx .* ddy - dy .* ddx) ./ (dx.^2 + dy.^2) .^ (3/2);
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Misc Options
p.addOptional('mtrp', []);   % Midline interpolation size
p.addOptional('smth', 8);     % Curvature smoothing size
p.addOptional('mth', 'open'); % Curvature method
p.addOptional('ofix', 0);     % Remove string of zeros
p.addOptional('alg', 'cwt');  % Curvature algorithm

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
