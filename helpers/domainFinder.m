function [fa , tpt] = domainFinder(isrc, itrg, msrc, mtrg, psrc, varargin)
%%
% Mapping points from the source frame onto the target should not search through
% fixed coordinates, since we're expecting differential growth throughout the
% hypocotyl. So the search window should contain:
%   1) A start point (Ws)
%   2) An end point  (We)
%   3) Interpolation size (Wi)
%   4) Domain parameters (Wd)
%
% The algorithm should work something like:
%   A) Get source midpoint coordinate (Ms)
%   B) Create domain from source coordinate (Ds)
%   C) Interpolate window W from Ws to We to be Wi points
%   D) Sample domains from each point of the window using Wd parameters
%   E) Iterate through all stretch values S and perform operation on source
%   F) Compare corellation score of stretch source (Dt) on target windows (W)
%   G) Map source to target with best corellation score
%
% Usage:
%   [nopt , sopt , scorr , S , T] = domainFinder( ...
%       isrc, itrg, msrc, mtrg, nsrc, varargin)
%
% Input:
%   isrc: source image
%   itrg: target image
%   msrc: source midline
%   mtrg: target midline
%   psrc: percentage along source midline
%
% Output:
%   nopt: optimal matching index on target midline
%   sopt: optimal stretch value for source domain
%   scorr: corellation matrix comparing stretched source with target image
%   S: stretched source images and domains
%   T: target images and domains
%

%% Parse inputs, Load models, Separate sets
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

% ---------------------------------------------------------------------------- %
% Prep domain
[scls , doms , dszs] = setupParams('toRemove', 2:4, ...
    'diskScale', [ds , ds], 'diskDomain', [dd , dd]);
scl  = scls{1};
rdom = doms{1};
dsz  = dszs{1};

% Get fiber bundle of midline
ws   = fiberBundle1d(msrc);
wt   = fiberBundle1d(mtrg);
zs   = ws.eval(psrc, 'normalized');
zsrc = [zs(:,1:2,3) , zs(:,1:2,1) , zs(:,1:2,2)];
vsrc = zsrc(1:2);

% Sample source image to get source domain
[~ , ~ , dsrc]  = sampleAtDomain(isrc, zsrc, scl, rdom, dsz);
xdom            = [(dsrc(1:2,:))' - vsrc , ones(size(dsrc,2),1)];

% Function handles for stretching, sampling, and grading
S      = makeOperations;
dstc   = @(mid,v) (squeeze(mid.eval(v(1), 'normalized')) * S(v(2),1) * xdom')';
dsmpl  = @(img,mid,v) sampleDomain(img,dstc(mid,v));
dgrade = @(is,ms,it,mt,ps)@(tp) norm(dsmpl(is,ms,[ps,1]) - dsmpl(it,mt,tp));

%
% d for lower bound --> 20 pixels [should be distance to previous point
slen = 1.5;
n    = 1000;
alen = ws.calculatelength(psrc, 1, n);

if isempty(ppct)
    dlt = 20; % Default distance to set lower bound
else
    % Set lower bound to the distance to previous percentage
    blen = ws.calculatelength(ppct, 1, n);
    dlt  = blen - alen;
end

ub = [wt.getApexLength(alen) , slen];
lb = [wt.getApexLength(alen + dlt) , 1];

% Minimization optimization to find optimial percentage on target
% fa  = fminsearch(dgrade(isrc, ws, itrg, wt, psrc), [psrc , 1]);
% fa  = patternsearch(dgrade(isrc, ws, itrg, wt, psrc), [psrc , 1]);
options = optimset('Display', 'off');
fa  = patternsearch(dgrade(isrc, ws, itrg, wt, psrc), [psrc , 1], ...
    [], [], [], [], lb, ub, options);
tpt = ws.evalCurve(fa(1), 'normalized');
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;
p.addOptional('ds', 15);     % Size of disk domain
p.addOptional('dd', 150);    % Resolution for disk domain
p.addOptional('rmin', -5);   % Min range from source index
p.addOptional('rmax', 5);    % Max range from source index
p.addOptional('tpts', 10);   % Interpolation size for target window
p.addOptional('spts', 20);   % Interpolation size for stretch array
p.addOptional('symin', 0.9); % Min stretch value
p.addOptional('symax', 1.2); % Max stretch value
p.addOptional('ppct', []);   % Percentage for previous point
% p.addOptional('psrc', 0.0);  % Max stretch value

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
