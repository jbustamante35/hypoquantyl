function [T , vru , vre , vri , len] = averageTracking(T, sidxs, frms, ltrp, lthr, smth, ferr)
%% averageTracking: compile tracking data and compute average REGR
%
% Usage:
%   [T , vru , vre , vri , len] = averageTracking( ...
%       T, sidxs, frms, ltrp, lthr, smth)
%
% Input:
%   T: output of trackingProcessor
%   sidxs: seedlings to exclude from averaging [default []]
%   frms: range of frames to analyze
%   ltrp: interpolation size for location (arclength) [default 1000]
%   lthr: threshold length from tip for normalization [default []]
%   smth: smooth resulting velocities and regrs [default 0]
%   ferr: function to compute error [default []]
%
% Output:
%   T: output returned with excluded seedlings
%   vru: averaged regr and velocityes
%   vre: standard errors of the mean for regr and velocity
%   vri: individual regr and velocities
%   len: reference mask for cutoff arclength

if nargin < 2; sidxs = [];   end
if nargin < 3; frms  = [];   end
if nargin < 4; ltrp  = 1000; end
if nargin < 5; lthr  = [];   end
if nargin < 6; smth  = 0;    end
if nargin < 7; ferr  = [];   end

% Exclude Seedlings
if ~isempty(sidxs); T = excludeSeedlings(T, sidxs); end

% Extract src or trg arclength and velocity
L = T.Output.Arclength.trg;
V = T.Output.Velocity;

% Exclude frames
if ~isempty(frms)
    L = cellfun(@(x) x(:,frms), L, 'UniformOutput', 0);
    V = cellfun(@(x) x(:,frms), V, 'UniformOutput', 0);
end

%%
LI = cellfun(@(x,v) interpolateGrid(x, 'xtrp', size(v,2), 'ytrp', ltrp), ...
    L, V, 'UniformOutput', 0);
if isempty(lthr); lthr = min(cellfun(@(x) x(end,1), LI)); end

% Average normalized Velocities and Compute REGR
nsdls                = numel(LI);
[ivel , iregr , len] = deal(cell(nsdls, 1));
for sidx = 1 : nsdls
    % Store midline coordinates from apex to threshold length
    li    = LI{sidx} <= lthr;
    flens = sum(li);
    nv    = cell(numel(flens),1);

    % Interpolate velocity profile to threshold length from tip
    for b = 1 : numel(nv)
        lb    = li(:,b);
        vv    = V{sidx}(lb,b);
        nv{b} = interpolateVector(vv, ltrp);
    end

    len{sidx}   = li;
    ivel{sidx}  = cat(2, nv{:});
    iregr{sidx} = gradient(ivel{sidx}')';
end

% Smooth velocities and regrs
if smth
    ivel  = cellfun(@(x) interpolateGrid(x, 'fsmth', smth), ...
        ivel, 'UniformOutput', 0);
    iregr = cellfun(@(x) interpolateGrid(x, 'fsmth', smth), ...
        iregr, 'UniformOutput', 0);
end

% Get statistics of velocities and regr [mean|var]
if isempty(ferr); ferr = @(x) computeStandardError(x,3); end
vv    = cat(3, ivel{:});
rr    = cat(3, iregr{:});
uvel  = mean(vv, 3);
uregr = mean(rr, 3);
evel  = ferr(vv);
eregr = ferr(rr);

% Fill in fields of output structure
T.Stats.UVEL  = uvel;
T.Stats.UREGR = uregr;
T.Stats.EVEL  = evel;
T.Stats.EREGR = eregr;
T.Stats.LENS  = len;

% Return outputs
vru = {uregr , uvel};
vre = {eregr , evel};
vri = {iregr , ivel};
end

function T = excludeSeedlings(T, sidxs)
%% excludeSeedlings: remove seedlings from averaging
%
% Usage:
%   T = excludeSeedlings(T, sidxs)
%
% Input:
%   tinn: full input data
%   sidxs: indices of seedlings to exclude
%
% Output:
%   tout: dataset with excluded seedlings

[flds1 , flds2 , flds3] = extractFields(T);

go1 = cellfun(@(x) ~isempty(x), flds2);
for f1 = 1 : numel(flds1)
    if go1(f1)
        go2 = cellfun(@(x) ~isempty(x), flds3{f1});
        for f2 = 1 : numel(flds2{f1})
            if go2(f2)
                % Remove from 3rd-level field
                for f3 = 1 : numel(flds3{f1}{f2})
                    T.(flds1{f1}).(flds2{f1}{f2}).(flds3{f1}{f2}{f3})(sidxs) = ...
                        [];
                end
            else
                % Remove from 2nd-level field
                T.(flds1{f1}).(flds2{f1}{f2})(sidxs) = [];
            end
        end
    else
        % Remove from 1st-level field
        T.(flds1{f1})(sidxs) = [];
    end
end
end
