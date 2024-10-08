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
% Model Options
%       p.addOptional('pz', 'pz');
%       p.addOptional('pdp', 'pdp');
%       p.addOptional('pdx', 'pdx');
%       p.addOptional('pdy', 'pdy');
%       p.addOptional('pdw', 'pdw');
%       p.addOptional('pm', 'pm');
%       p.addOptional('Nz', 'znnout');
%       p.addOptional('Nb', 'bnnout');
%       p.addOptional('Nd', 'dnnout');
%       p.addOptional('path2subs', 0);
%
%       % Segmentation Function Handles
%       p.addOptional('bpredict', []);
%       p.addOptional('zpredict', []);
%       p.addOptional('cpredict', []);
%       p.addOptional('mline', []);
%       p.addOptional('mscore', []);
%       p.addOptional('sopt', []);
%       p.addOptional('msample', []);
%
%       % Optimization Options
%       p.addOptional('ncycs', 1);
%       p.addOptional('nopts', 100);
%       p.addOptional('mbuf', 0);
%       p.addOptional('scl', 1);
%
%       % Mask Smoothing Options
%       p.addOptional('dsz', 5);
%       p.addOptional('smth', 5);
%       p.addOptional('npts', 210);
%       p.addOptional('href', []);
%
%       % Segmentation Function Options
%       p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);
%       p.addOptional('ymin', 10);
%       p.addOptional('bwid', [0.1 , 0.1 , 0.1]);
%       p.addOptional('psz', 20);
%       p.addOptional('toFix', 0);
%       p.addOptional('tolfun', 1e-4);
%       p.addOptional('tolx', 1e-4);
%       p.addOptional('myShps', [2 , 3 , 4]);
%       p.addOptional('zoomLvl', [0.5 , 1.5]);
%       p.addOptional('mpts', 50);
%       p.addOptional('mmth', 'nate');
%       p.addOptional('mparams', [5 , 3 , 0.1]);
%
%       % Miscellaneous Options
%       p.addOptional('sav', 0);
%       p.addOptional('par', 0);
%       p.addOptional('vis', 0);
%       p.addOptional('fidx', 0);
%       p.addOptional('edate', tdate);
%       p.addOptional('toFlip', []);
%       p.addOptional('keepBoth', 0);
%       p.addOptional('ddir', 'output');
%
%       % Information Options
%       p.addOptional('GenotypeName', 'genotype');
%       p.addOptional('GenotypeIndex', 0);
%       p.addOptional('SeedlingIndex', 0);
%       p.addOptional('Frame', 0);
%
% Output:
%   out: output structure

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Segment upper and lower hypocotyl individually
uhyp = segmentUpperHypocotyl(uimg, 'Nb', Nb, 'Nz', Nz, 'Nd', Nd, 'pz', pz, ...
    'pdp', pdp, 'pdw', pdw, 'pdx', pdx, 'pdy', pdy, 'pm', pm, ...
    'bpredict', bpredict, 'zpredict', zpredict, 'cpredict', cpredict, ...
    'sopt', sopt, 'mline', mline, 'mscore', mscore, 'msample', msample, ...
    'toFix', toFix, 'bwid', bwid, 'seg_lengths', seg_lengths, ...
    'mbuf', mbuf, 'scl', scl, 'href', href, 'nopts', nopts, 'sav', 0, ...
    'par', par, 'vis', vis, 'myShps', myShps, 'zoomLvl', zoomLvl, ...
    'mpts', mpts, 'mmth', mmth, 'mparams', mparams, 'tolfun', tolfun, ...
    'tolx', tolx, 'fidx', fidx, 'toFlip', toFlip, 'keepBoth', keepBoth, ...
    'path2subs', path2subs, 'GenotypeName', GenotypeName, ...
    'GenotypeIndex', GenotypeIndex, 'SeedlingIndex', SeedlingIndex, ...
    'Frame', Frame);

if isempty(lmsk); fprintf('\n\nLower mask empty\n\n'); end
lhyp = segmentLowerHypocotyl(lmsk, 'dsz', dsz, 'smth', smth, 'npts', npts, ...
    'seg_lengths', seg_lengths, 'mline', mline, 'sav', 0, ...
    'GenotypeName', GenotypeName, 'GenotypeIndex', GenotypeIndex, ...
    'SeedlingIndex', SeedlingIndex, 'Frame', Frame);

%% Output
out = struct('info', uhyp.info, 'uhyp', uhyp, 'lhyp', lhyp, ...
    'err', [uhyp.err , lhyp.err], 'isgood', [uhyp.isgood , lhyp.isgood]);

if sav
    if ~isfolder(ddir); mkdir(ddir); end
    outnm = sprintf('%s/%s_results_%s_genotype%02d_seedling%d_frame%02d_segmentation', ...
        ddir, edate, GenotypeName, GenotypeIndex, SeedlingIndex, Frame);
    save(outnm, '-v7.3', 'out');
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Model Options
p.addOptional('pz', 'pz');
p.addOptional('pdp', 'pdp');
p.addOptional('pdx', 'pdx');
p.addOptional('pdy', 'pdy');
p.addOptional('pdw', 'pdw');
p.addOptional('pm', 'pm');
p.addOptional('Nz', 'znnout');
p.addOptional('Nb', 'bnnout');
p.addOptional('Nd', 'dnnout');
p.addOptional('path2subs', 0);

% Segmentation Function Handles
p.addOptional('bpredict', []);
p.addOptional('zpredict', []);
p.addOptional('cpredict', []);
p.addOptional('mline', []);
p.addOptional('mscore', []);
p.addOptional('sopt', []);
p.addOptional('msample', []);

% Optimization Options
p.addOptional('ncycs', 1);
p.addOptional('nopts', 100);
p.addOptional('mbuf', 0);
p.addOptional('scl', 1);

% Mask Smoothing Options
p.addOptional('dsz', 5);
p.addOptional('smth', 5);
p.addOptional('npts', 210);
p.addOptional('href', []);

% Segmentation Function Options
p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);
p.addOptional('ymin', 10);
p.addOptional('bwid', [0.1 , 0.1 , 0.1]);
p.addOptional('psz', 20);
p.addOptional('toFix', 0);
p.addOptional('tolfun', 1e-4);
p.addOptional('tolx', 1e-4);
p.addOptional('myShps', [2 , 3 , 4]);
p.addOptional('zoomLvl', [0.5 , 1.5]);
p.addOptional('mpts', 50);
p.addOptional('mmth', 'nate');
p.addOptional('mparams', [5 , 3 , 0.1]);

% Miscellaneous Options
p.addOptional('sav', 0);
p.addOptional('par', 0);
p.addOptional('vis', 0);
p.addOptional('fidx', 0);
p.addOptional('edate', tdate);
p.addOptional('toFlip', []);
p.addOptional('keepBoth', 0);
p.addOptional('ddir', 'output');

% Information Options
p.addOptional('GenotypeName', 'genotype');
p.addOptional('GenotypeIndex', 0);
p.addOptional('SeedlingIndex', 0);
p.addOptional('Frame', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
