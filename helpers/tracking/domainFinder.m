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
%   [fa , tpt]] = domainFinder( ...
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
%   fa: [tracked percentage , stretch value]
%   tpt: tracked coordinate
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
[~ , ~ , dsrc] = sampleAtDomain(isrc, zsrc, scl, rdom, dsz);
xdom           = [(dsrc(1:2,:))' - vsrc , ones(size(dsrc,2),1)];

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

if ~isempty(ppct)
    % Set lower bound to the distance to previous percentage + delta
    % UPDATE [03.11.2022]
    %   Dynamically set delta (dlt) based on distance from tip. This would limit
    %   the size of jumps along the bottom - where less differentiation is
    %   expected - and larger jumps around the hook - where we expect more cell
    %   division events to be occur.
    blen = ws.calculatelength(ppct, 1, n);
    if     psrc >= 0.7 && psrc < 1.0; pdlt = 2.0;
    elseif psrc >= 0.4 && psrc < 0.7; pdlt = 1.5;
    elseif psrc > 0    && psrc < 0.4; pdlt = 1.0;
    else;                             pdlt = 1.5;
    end

    dlt  = (blen - alen) / pdlt;
else
    ppct = 0;
end

ub = [wt.getApexLength(alen) , slen];
lb = [wt.getApexLength(alen + dlt) , 1];

% Minimization optimization to find optimial percentage on target
% fa  = fminsearch(dgrade(isrc, ws, itrg, wt, psrc), [psrc , 1]);
% fa  = patternsearch(dgrade(isrc, ws, itrg, wt, psrc), [psrc , 1]);
options = optimset('Display', 'off');
fa      = patternsearch(dgrade(isrc, ws, itrg, wt, psrc), [psrc , 1], ...
    [], [], [], [], lb, ub, options);
tpt     = wt.evalCurve(fa(1), 'normalized');

%%
if fidx
    if ~psrc
        figclr(fidx);
        myimagesc(itrg);
        hold on;
        plt(msrc, 'b-', 2);
        plt(mtrg, 'r-', 2);
    end

    plt(ws.evalCurve(ub(1), 'normalized'), 'bo', 15);
    plt(wt.evalCurve(ub(1), 'normalized'), 'bo', 15);

    plt(ws.evalCurve(psrc, 'normalized'), 'r.', 25);
    plt(wt.evalCurve(psrc, 'normalized'), 'r.', 25);

    plt(ws.evalCurve(lb(1), 'normalized'), 'co', 10);
    plt(wt.evalCurve(lb(1), 'normalized'), 'co', 10);

    plt(ws.evalCurve(ppct, 'normalized'), 'g.', 15);
    plt(wt.evalCurve(ppct, 'normalized'), 'g.', 15);

    if ~psrc
        dsrc = drawellipse('Center', ws.evalCurve(psrc, 'normalized'), ...
            'SemiAxes', [15 , 15], 'Color', 'r');
        dtrg = drawellipse('Center', wt.evalCurve(fa(1), 'normalized'), ...
            'SemiAxes', [15 , (15 * fa(2))], 'Color', 'g');
    else
        chl  = arrayfun(@(x) x.Children, gca, 'UniformOutput', 0);
        chls = arrayfun(@(x) class(x), chl{1}, 'UniformOutput', 0);
        didx = cellfun(@(x) contains(x, 'Ellipse'), chls);
        dd   = chl{1}(didx);
        dtrg = dd(1);
        dsrc = dd(2);

        dsrc.Center   = ws.evalCurve(psrc, 'normalized');
        dsrc.SemiAxes = [15 , 15];
        dtrg.Center   = wt.evalCurve(fa(1), 'normalized');
        dtrg.SemiAxes = [15 , (15 * fa(2))];
    end
    drawnow;
end
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
p.addOptional('dlt', 20);    % Default distance to set lower bound above point
p.addOptional('fidx', 0);    % Default distance to set lower bound
% p.addOptional('psrc', 0.0);  % Max stretch value

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
