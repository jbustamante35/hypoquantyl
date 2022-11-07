function out = segmentFullHypocotyl(uimg, lmsk, varargin)
%% segmentFullHypocotyl: condor remote segmentation of upper and lower hypocotyl
%
% Usage:
%   out = segmentFullHypocotyl(uimg, lmsk, varargin)
%
% Input:
%   uimg: upper hypocotyl image
%   lmsk: lower hypocotyl mask
%   varargin: various options
%         Model Options
%         p.addOptional('Nb', 'bnnout');
%         p.addOptional('Nz', 'znnout');
%         p.addOptional('Nd', 'dnnout');
%         p.addOptional('pz', 'pz');
%         p.addOptional('pdp', 'pdp');
%         p.addOptional('pdw', 'pdw');
%         p.addOptional('pdx', 'pdx');
%         p.addOptional('pdy', 'pdy');
%         p.addOptional('pm', 'pm');
%
%         Optimization Options
%         p.addOptional('ncycs', 1);
%         p.addOptional('nopts', 100);
%         p.addOptional('toFix', 0);
%         p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);
%
%         Miscellaneous Options
%         p.addOptional('sav', 0);
%
%         Information Options
%         p.addOptional('GenotypeName', 'genotype');
%         p.addOptional('GenotypeIndex', 0);
%         p.addOptional('SeedlingIndex', 0);
%         p.addOptional('Frame', 0);
%
% Output:
%   out: output structure
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Segment upper and lower hypocotyl individually
uhyp = segmentUpperHypocotyl(uimg, 'Nb', Nb, 'Nz', Nz, 'Nd', Nd, 'pz', pz, ...
    'pdp', pdp, 'pdw', pdw, 'pdx', pdx, 'pdy', pdy, 'pm', pm, 'toFix', toFix, ...
    'bwid', bwid, 'seg_lengths', seg_lengths, 'nopts', nopts, 'sav', 0, ...
    'par', par, 'vis', vis, 'fidx', fidx, 'GenotypeName', GenotypeName, ...
    'GenotypeIndex', GenotypeIndex, 'SeedlingIndex', SeedlingIndex, ...
    'Frame', Frame, 'toFlip', toFlip, 'keepBoth', keepBoth, 'path2subs', path2subs);

if isempty(lmsk); fprintf('\n\nLower mask empty\n\n'); end
lhyp = segmentLowerHypocotyl(lmsk, 'seg_lengths', seg_lengths, 'sav', 0, ...
    'GenotypeName', GenotypeName, 'GenotypeIndex', GenotypeIndex, ...
    'SeedlingIndex', SeedlingIndex, 'Frame', Frame);

%% Output
out = struct('info', uhyp.info, 'uhyp', uhyp, 'lhyp', lhyp, ...
    'err', [uhyp.err , lhyp.err], 'isgood', [uhyp.isgood , lhyp.isgood]);

if sav
    if ~isfolder('output'); mkdir('output'); end
    outnm = sprintf('output/%s_results_%s_genotype%02d_seedling%d_frame%02d_segmentation', ...
        edate, GenotypeName, GenotypeIndex, SeedlingIndex, Frame);
    save(outnm, '-v7.3', 'out');
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Model Options
p.addOptional('Nb', 'bnnout');
p.addOptional('Nz', 'znnout');
p.addOptional('Nd', 'dnnout');
p.addOptional('pz', 'pz');
p.addOptional('pdp', 'pdp');
p.addOptional('pdw', 'pdw');
p.addOptional('pdx', 'pdx');
p.addOptional('pdy', 'pdy');
p.addOptional('pm', 'pm');
p.addOptional('path2subs', 0);

% Optimization Options
p.addOptional('ncycs', 1);
p.addOptional('nopts', 100);
p.addOptional('bwid', 0.5);
p.addOptional('toFix', 0);
p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);

% Miscellaneous Options
p.addOptional('sav', 0);
p.addOptional('par', 0);
p.addOptional('vis', 0);
p.addOptional('fidx', 0);
p.addOptional('edate', tdate);
p.addOptional('toFlip', []);
p.addOptional('keepBoth', 0);

% Information Options
p.addOptional('GenotypeName', 'genotype');
p.addOptional('GenotypeIndex', 0);
p.addOptional('SeedlingIndex', 0);
p.addOptional('Frame', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end