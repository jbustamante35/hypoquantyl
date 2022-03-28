function out = segmentLowerHypocotyl(msk, varargin)
%% segmentLowerHypocotyl: process and segment lower regions of hypocotyl
% For use with CONDOR
%
% Usage:
%   out = segmentLowerHypocotyl(msk, varargin)
%
% Input:
%   msk: binary mask of lower hypocotyl
%   varargin: various options
%       dsz: disz size for binary mask smoothing [default 3]
%       npts: number of coordinates to set contour
%       mth: processing method to find corners of contour [default 1]
%       smth: smoothing parameter after segmentation [default 1]
%       slens: length of segments for all 4 regions [left|top|right|bottom]
%       fidx: figure handle index to display result [default 0]
%
% Output:
%   out: results
%       info: metadata about input mask
%       cntr: re-formatted contour of lower mask
%       mline: midline generated from contour
%

%%
try
    %% Parse inputs
    args = parseInputs(varargin);
    for fn = fieldnames(args)'
        feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
    end

    % Segment, smooth, process to regions, extract midline
    [cntr , mline] = mask2clipped(msk, dsz, npts, init, creq, ...
        mth, smth, seg_lengths, fidx);

    %% If good
    isgood = true;
    err    = [];
catch err
    %% If error
    [cntr , mline] = deal([]);
    isgood         = false;
    fprintf(2, '\n%s\n\n', err.getReport);
end

%% Output
info = struct('GenotypeName', GenotypeName, 'GenotypeIndex', GenotypeIndex, ...
    'SeedlingIndex', SeedlingIndex, 'Frame', Frame);
out  = struct('info', info, 'c', cntr, 'm', mline, ...
    'err', err, 'isgood', isgood);

if sav
    mkdir('output');
    outnm = sprintf('output/%s_results_lower', tdate);
    save(outnm, '-v7.3', 'out');
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Misc Options
p.addOptional('dsz', 3);
p.addOptional('npts', 210);
p.addOptional('init', 'alt');
p.addOptional('creq', 'Normalize');
p.addOptional('mth', 1);
p.addOptional('smth', 1);
p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);

% Information Options
p.addOptional('GenotypeName', 'genotype');
p.addOptional('GenotypeIndex', 0);
p.addOptional('SeedlingIndex', 0);
p.addOptional('Frame', 0);

% Visualization Options
p.addOptional('sav', 0);
p.addOptional('fidx', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
