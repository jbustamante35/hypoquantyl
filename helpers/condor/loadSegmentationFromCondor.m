function [HOUT , NHYP , HERR] = loadSegmentationFromCondor(HYPS, gidx)
%% loadSegmentationFromCondor: loads and organizes condor segmentation output
% 1) Extract all .mat files
% 2) Organze by Genotype --> Seedling --> Frame
%
% Usage:
%   [HOUT , NHYP , HERR] = loadSegmentationFromCondor(HYPS, gidx)
%
% Input:
%   HYPS: cell array of path names to genotype directory
%   gidx: indices for genotypes (optional) [default 1 : numel(HYPS)]
%
% Output:
%   HOUT: Loaded .mat files organized by genotype-seedling-frame
%   NHYP: total images loaded from each genotype
%   HERR: index and total errors from each genotype
%

%%
if nargin < 2; edate = tdate;          end
if nargin < 3; gidx = 1 : numel(HYPS); end

%% Extract .mat files from genotype's directory
[HHYP , NHYP , HERR] = cellfun(@(x) ...
    extractMats(x), HYPS(gidx), 'UniformOutput', 0);

%% Organize by Seedling
SIDXS = cellfun(@(y) arrayfun(@(x) x.info.SeedlingIndex, y), ...
    HHYP, 'UniformOutput', 0);
NSDLS = cellfun(@(x) unique(x), SIDXS, 'UniformOutput', 0);
SOUT = cellfun(@(h,s,n) arrayfun(@(nn) h(nn == s), n, 'UniformOutput', 0), ...
    HHYP, SIDXS, NSDLS, 'UniformOutput', 0);

%% Sort by Frames
HIDXS = cellfun(@(z) cellfun(@(y) arrayfun(@(x) x.info.Frame, y), ...
    z, 'UniformOutput', 0), SOUT, 'UniformOutput', 0);
[~ , HSORT] = cellfun(@(y) cellfun(@(x) sort(x), y, 'UniformOutput', 0), ...
    HIDXS, 'UniformOutput', 0);
HOUT = cellfun(@(a,b) cellfun(@(x,y) x(y), a, b, 'UniformOutput', 0), ...
    SOUT, HSORT, 'UniformOutput', 0);
end

function [hhyp , nhyp , herr] = extractMats(hyp)
%% extractMats
hmat = dir(hyp);
hmat = hmat(arrayfun(@(x) contains(x.name, 'segmentation.mat'), hmat));
hmat = arrayfun(@(x) [x.folder , filesep , x.name], hmat, 'UniformOutput', 0);
hhyp = cellfun(@(x) load(x), hmat);

%
hhyp = arrayfun(@(x) x.out, hhyp);
nhyp = numel(hhyp);
herr = nhyp - sum(~arrayfun(@isempty, hhyp));
end