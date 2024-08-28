function [TRACK , CFLO] = trackingToCondor(GIMGS, GMIDS, ENMS, GNMS, GIDXS, SIDXS, npcts, varargin)
%% trackingToCondor: send tracking jobs to condor
%
%
% Usage:
%   [TRACK , CFLO] = trackingToCondor(GIMGS, GMIDS, ...
%       ENMS, GNMS, GIDXS, SIDXS, npcts, varargin)
%
% Input:
%   GIMGS: seedling images
%   GMIDS: seedling midlines remapped to full-resolution image
%   ENMS: cell array of experiment names
%   GNMS: cell array of genotype names
%   GIDXS: array of genotype indices
%   SIDXS: array of seedling indices
%   npcts: total points to track [default 61]
%   varargin: various options
%
% Output:
%   TRACK: filepaths to .mat condor results
%   CFLO: cFlow object used to submit condor jobs

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Create cFlow object
if dbug
    CFLO = 'dbug on';
else
    CFLO = cFlow('trackingFull');
    auth = readtext('/mnt/spaldingdata/nate/auth.iplant');
    auth = auth{1};

    % Make output directory
    CFLO.setMemory('18000');
    node_oPath  = 'output';
    home_oPath  = sprintf(['/mnt/tetra/JulianBustamante/' ...
        'Condor/tracking/%s'], kdate);
end

% ---------------------------------------------------------------------------- %
%% Single node runs tracking for all frames of a single seedling
tA = tic;
fprintf(['\n\n%s\n%s\n%s\n\t\t\t\t\t\tMIDLINE TRACKER 3.0\n' ...
    '%s\n%s\n%s\n\n\n\n'], sprA, sprB, sprA, sprA, sprB, sprA);

finit = ffrm;
nsdls = numel(GIMGS);
TRACK = cell(nsdls, 1);
for nidx = 1 : nsdls
    gimgs = GIMGS{nidx};
    gmids = GMIDS{nidx};
    enm   = ENMS{nidx};
    gnm   = GNMS{nidx};
    gidx  = GIDXS(nidx);
    sidx  = SIDXS(nidx);

    if isempty(finit); ffrm = size(gimgs,1) - 1; end
    nfrms = numel(ifrm : ffrm);

    % ------------------------------------------------------------------------ %
    % Iterate through all frames
    tS = tic;
    fprintf(['\n%s\nLoading cFlow object | %s | %03d of %03d | ' ...
        'Frames %03d to %03d [total %03d]\n%s\n'], ...
        sprA, gnm, nidx, nsdls, ifrm, ffrm, nfrms, sprB);

    % ------------------------------------------------------------------------ %
    tG = tic;
    fprintf('%s\n\tTracking %s [%02d frames]\n', sprA, gnm, nfrms);

    switch dbug
        case 0
            % Create output directory
            fprintf('\t\t\t\t\tPrepping Condor Object\n%s\n', sprB);
            gpath       = sprintf('%s/%s/', home_oPath, enm);
            map_command = sprintf('%s>%s', node_oPath, gpath);
            mmkdir(gpath);
            CFLO.addDirectoryMap(map_command);

            TRACK{nidx} = CFLO(gimgs, gmids, npcts, ...
                'ifrm', ifrm, 'ffrm', ffrm, 'skp', skp, 'dsk', dsk, ...
                'dres', dres, 'symin', symin, 'symax', symax, 'itrs', itrs, ...
                'tolf', tolf, 'tolx', tolx, 'dlt', dlt, 'eul', eul, 'nlc', nlc, ...
                'lb', lb, 'ub', ub, 'tol', tol, 'smth', smth, 'ltrp', ltrp, ...
                'othr', othr, 'vrng', vrng, 'fmax', fmax, 'ki', ki, 'ni', ni, ...
                'kdate', kdate, 'tdir', tdir, 'sav', sav, 'par', 0, ...
                'ExperimentName', enm, 'GenotypeName', gnm, ...
                'GenotypeIndex', gidx, 'SeedlingIndex', sidx, 'Frames', nfrms);

            ttm = 'hrs';
        case 1
            % Run locally
            TRACK{nidx} = trackingFull(gimgs, gmids, npcts, ...
                'ifrm', ifrm, 'ffrm', ffrm, 'skp', skp, 'dsk', dsk, ...
                'dres', dres, 'symin', symin, 'symax', symax, 'itrs', itrs, ...
                'tolf', tolf, 'tolx', tolx, 'dlt', dlt, 'eul', eul, 'nlc', nlc, ...
                'lb', lb, 'ub', ub, 'tol', tol, 'smth', smth, 'ltrp', ltrp, ...
                'othr', othr, 'vrng', vrng, 'fmax', fmax, 'ki', ki, 'ni', ni, ...
                'kdate', kdate, 'tdir', tdir, 'sav', sav, 'par', par, ...
                'ExperimentName', enm, 'GenotypeName', gnm, ...
                'GenotypeIndex', gidx, 'SeedlingIndex', sidx, 'Frames', nfrms);

            ttm = 'days';
        case 2
            % Show information and inputs
            info  = struct('ExperimentName', enm, 'GenotypeName', gnm, ...
                'GenotypeIndex', gidx, 'SeedlingIndex', sidx, 'Frames', nfrms);
            out   = struct('gimgs', gimgs, 'gmids', gmids);
            TRACK{nidx} = struct('info', info, 'out', out);
            fprintf(['GenotypeIndex: %02d\nSeedlingIndex: %02d\nFrame: ' ...
                '%02d to %02d [total %02d]\n'], gidx, sidx, ifrm, ffrm, nfrms);

            ttm = 'min';
        otherwise
            [TRACK{nidx} , CFLO] = deal([]);
            return;
    end

    fprintf('%s\nDONE! [%.02f min]\n%s\n', sprB, mytoc(tS, 'min'), sprA);

    if dbug == 2
        figclr(fidx);
        gttl = fixtitle(gnm);
        for frm = 1 : round(nfrms / 8) : nfrms
            myimagesc(gimgs{frm});
            hold on;
            plt(gmids{frm}, 'r-', 2);
            ttl = sprintf('G: %s | S: %02d | F: %02d of %02d', ...
                gttl, sidx, frm, nfrms);
            title(ttl, 'FontSize', 10);
            drawnow;
            hold off;
        end
    end

    fprintf('\t\tTracked %02d frames for %s [%.02f min]\n%s\n\n\n', ...
        nfrms, gnm, mytoc(tG, 'min'), sprA);
end

% Send to condor
if ~dbug; CFLO.submitDag(auth, 50, 50); end

fprintf(['\n\n%s\n%s\n%s\n\t\t\t\t\tFINISHED TRACKING! [%.02f min]\n%s\n%s' ...
    '\n%s\n\n\n\n'], sprA, sprB, sprA, mytoc(tA, ttm), sprA, sprB, sprA);
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
% Required
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
p.addOptional('lb',  [0     , 0    , -500  , 0]);
p.addOptional('ub',  [6     , 0.05 , 200    , 0.5]);
p.addOptional('tol', [1e-12 , 1e-12]);
p.addOptional('smth', 1);
p.addOptional('ltrp', 1000);
p.addOptional('othr', 2.5);
p.addOptional('vrng', 10);
p.addOptional('fmax', 20);
p.addOptional('ki', 0.02);
p.addOptional('ni', 0.3);

% Save and Visualization Options
p.addOptional('kdate', tdate);
p.addOptional('tdir', []);
p.addOptional('sav', 1);
p.addOptional('dbug', 0);
p.addOptional('fidx', 1);
p.addOptional('par', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end