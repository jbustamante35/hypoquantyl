function [fa , tpt] = domainFinder(isrc, itrg, msrc, mtrg, psrc, varargin)
%% domainFinder
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
%   fa: [tracked percentage , tracked stretch]
%   tpt: tracked coordinate

%% Parse inputs, Load models, Separate sets
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

% ---------------------------------------------------------------------------- %
% Prep domain [disk]
[scls , doms , dszs] = setupParams('myShps', 1, ...
    'diskScale', [dsk , dsk], 'diskDomain', [dres , dres]);
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
[~ , ~ , xsrc] = sampleAtDomain(isrc, zsrc, scl, rdom, dsz, 0);
dsrc           = [(xsrc(1:2,:))' - vsrc , ones(size(xsrc,2),1)];

% Function handles for stretching, sampling, and grading
S      = makeOperations;
dstc   = @(mid,v) (squeeze(mid.eval(v(1), 'normalized')) * S(v(2),1) * dsrc')';
dsmpl  = @(img,mid,v) sampleDomain(img,dstc(mid,v));
dgrade = @(is,ms,it,mt,ps)@(tp) norm(dsmpl(is,ms,[ps,1]) - dsmpl(it,mt,tp));

% d for lower bound --> 20 pixels [should be distance to previous point]
% [UPDATE 05.04.2023] Don't allow any negative velocities
n    = 1000;
alen = ws.calculatelength(psrc, 1, n);

if ~isempty(ppct)
    % Set lower bound to the distance to previous percentage + delta
    % UPDATE [03.11.2022]
    %   Dynamically set delta (dlt) based on distance from tip. This would limit
    %   the size of jumps along the bottom - where less differentiation is
    %   expected - and larger jumps around the hook - where we expect more cell
    %   division events to be occur.
    %     blen = ws.calculatelength(ppct, 1, n);
    %     if     psrc >= 0.7 && psrc < 1.0; pdlt = 1;
    %     elseif psrc >= 0.4 && psrc < 0.7; pdlt = 5;
    %     elseif psrc > 0    && psrc < 0.4; pdlt = 8;
    %     else;                             pdlt = 5;
    %     end

    %     dlt = (blen - alen) / pdlt; 
else
    ppct = 0;
end

% Bounds based on pixels from source point
lb = [wt.getApexLength(alen + dlt) , symin];
ub = [wt.getApexLength(alen - dlt) , symax];

% Very loose bounds
% ub = [1 , symax];
% lb = [0 , symin];

% Minimization optimization to find optimial percentage on target
topts = optimset('Display', 'off', 'MaxIter', itrs, ...
    'TolFun', tolf, 'TolX', tolx);
fa    = patternsearch(dgrade(isrc, ws, itrg, wt, psrc), [psrc , symin], ...
    [], [], [], [], lb, ub, [], topts);
tpt   = wt.evalCurve(fa(1), 'normalized');

%% Show tracking domains
if fidx
    if ~psrc
        figclr(fidx);
        myimagesc(itrg);
        hold on;
        plt(msrc, 'b-', 3);
        plt(mtrg, 'r-', 2);
    end

    % Plot pervious percentage on source and target midlines
    plt(ws.evalCurve(ppct, 'normalized'), 'g*', 15);
    plt(wt.evalCurve(ppct, 'normalized'), 'g.', 15);

    % Plot source percentage on source and target midlines
    plt(ws.evalCurve(psrc, 'normalized'), 'y*', 25);
    plt(wt.evalCurve(psrc, 'normalized'), 'y.', 25);

    % Plot Upper Bounds
    plt(ws.evalCurve(ub(1), 'normalized'), 'bd', 15);
    plt(wt.evalCurve(ub(1), 'normalized'), 'bo', 15);

    % Plot Lower Bounds
    plt(ws.evalCurve(lb(1), 'normalized'), 'cd', 10);
    plt(wt.evalCurve(lb(1), 'normalized'), 'co', 10);

    if ~psrc
        esrc = drawellipse('Center', ws.evalCurve(psrc, 'normalized'), ...
            'SemiAxes', [dsk , dsk], 'Color', 'r'); %#ok<NASGU>
        etrg = drawellipse('Center', wt.evalCurve(fa(1), 'normalized'), ...
            'SemiAxes', [dsk , (dsk * fa(2))], 'Color', 'g'); %#ok<NASGU>
    else
        chl  = arrayfun(@(x) x.Children, gca, 'UniformOutput', 0);
        chls = arrayfun(@(x) class(x), chl{1}, 'UniformOutput', 0);
        didx = cellfun(@(x) contains(x, 'Ellipse'), chls);
        di   = chl{1}(didx);
        etrg = di(1);
        esrc = di(2);

        esrc.Center   = ws.evalCurve(psrc, 'normalized');
        esrc.SemiAxes = [dsk , dsk];
        etrg.Center   = wt.evalCurve(fa(1), 'normalized');
        etrg.SemiAxes = [dsk , (dsk * fa(2))];
    end
    drawnow;
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;
p.addOptional('dsk', 12);    % Size of disk domain
p.addOptional('dres', 130);  % Resolution for disk domain
p.addOptional('rmin', -5);   % Min range from source index
p.addOptional('rmax', 5);    % Max range from source index
p.addOptional('tpts', 10);   % Interpolation size for target window
p.addOptional('spts', 20);   % Interpolation size for stretch array
p.addOptional('symin', 1.0); % Min stretch value
p.addOptional('symax', 1.3); % Max stretch value
p.addOptional('itrs', 500);  % Maximum iterations
p.addOptional('tolf', 1e-8); % Termination tolerance for function value
p.addOptional('tolx', 1e-8); % Termination tolerance for x-value
p.addOptional('ppct', []);   % Percentage for previous point
p.addOptional('dlt', 20);    % Default distance to set lower bound above point
p.addOptional('fidx', 0);    % Figure handle index

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
