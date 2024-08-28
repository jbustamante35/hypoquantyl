function out = trackingFull(gimgs, gmids, npcts, varargin)
%% trackingFull: tracking and processing of midlines
% For use with HTCondor
%
% Usage:
%   out = trackingFull(gimgs, gmids, npcts, varargin)
%
% Input:
%   gimgs: images to track on
%   gmids: midlines of a single seedling to track
%   npcts: total points to track [default 61]
%   varargin: various options [see below]
%
% Output:
%   out: results
%       info: metadata about inputs
%       F: output containing [tracked_percent , tracked_stretch]
%       M: tracked coordinates
%       T: processed tracking

%%
try
    %% Parse inputs
    args = parseInputs(varargin);
    for fn = fieldnames(args)'
        feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Run Tracking
    F = trackingWholeCurve(gimgs, gmids, npcts, 'ifrm', ifrm, ...
        'ffrm', ffrm, 'skp', skp, 'dsk', dsk, 'dres', dres, 'symin', symin, ...
        'symax', symax, 'itrs', itrs, 'tolf', tolf, 'tolx', tolx, ...
        'dlt', dlt, 'eul', eul, 'par', par);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Process Tracking
    W = cellfun(@(x) fiberBundle1d(x), gmids(ifrm:ffrm+1), 'UniformOutput', 0);
    W = cat(1, W{:});
    T = trackingProcessor(F, W, npcts, 'ki', ki, 'ni', ni, 'fmax', fmax, ...
        'vrng', vrng, 'smth', smth, 'ltrp', ltrp, 'othr', othr, 'nlc', nlc, ...
        'ExperimentName', ExperimentName, 'GenotypeName', GenotypeName, ...
        'GenotypeIndex', GenotypeIndex, 'SeedlingIndex', SeedlingIndex);

    %% If good
    isgood = true;
    err    = [];
catch err
    %% If error
    T      = [];
    isgood = false;
    err.getReport;
end

%% Output
info = struct('ExperimentName', ExperimentName, 'GenotypeName', GenotypeName, ...
    'GenotypeIndex', GenotypeIndex, 'SeedlingIndex', SeedlingIndex, ...
    'Frames', Frames, 'NPercents', npcts);
out  = struct('info', info, 'T' , T, 'err', err, 'isgood', isgood);

if sav
    if isempty(tdir)
        tdir = sprintf('output/tracking/%s/%s/%s', ...
            kdate, ExperimentName, GenotypeName);
    end

    if ~isfolder(tdir); mkdir(tdir); end
    outnm = sprintf(['%s/%s_results_' ...
        '%s_genotype%02d_seedling%d_%02dframes_%02dpoints_tracking'], ...
        tdir, kdate, GenotypeName, GenotypeIndex, SeedlingIndex, Frames, npcts);
    save(outnm, '-v7.3', 'out');
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Tracking Parameters
p.addOptional('ifrm', 1);
p.addOptional('ffrm', []);
p.addOptional('skp', 1);
p.addOptional('dsk', 12);    % Size of disk domain
p.addOptional('dres', 130);  % Resolution for disk domain
p.addOptional('symin', 1.0); % Min stretch value
p.addOptional('symax', 1.3); % Max stretch value
p.addOptional('itrs', 500);  % Maximum iterations
p.addOptional('tolf', 1e-8); % Termination tolerance for function value
p.addOptional('tolx', 1e-8); % Termination tolerance for x-value
p.addOptional('dlt', 20);    % Default distance to set lower bound above point
p.addOptional('eul', 1);     % Eulerian (1) or Lagrangian (0)

% Processing Options
p.addOptional('nlc', 1);
p.addOptional('lb', [0 , 0    , -500  , 0]);
p.addOptional('ub', [6 , 0.05 , 200    , 0.5]);
p.addOptional('tol', [1e-12 , 1e-12]);
p.addOptional('smth', 1);
p.addOptional('ltrp', 1000);
p.addOptional('othr', 2.5);
p.addOptional('vrng', 10);
p.addOptional('fmax', 20);
p.addOptional('ki', 0.02);
p.addOptional('ni', 0.3);

% Dataset Options
p.addOptional('ExperimentName', 'experiment');
p.addOptional('GenotypeName', 'genotype');
p.addOptional('GenotypeIndex', 0);
p.addOptional('SeedlingIndex', 0);
p.addOptional('Frames', 0);

% Save and Visualization Options
p.addOptional('kdate', tdate);
p.addOptional('tdir', []);
p.addOptional('sav', 1);
p.addOptional('par', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
