function [TRACK , CFLO] = trackingToCondor(gimgs, gmids, varargin)
%% trackingToCondor: send tracking jobs to condor
%
%
% Usage:
%   [TRACK , CFLO] = trackingToCondor(gimgs, gmids, varargin)
%
% Input:
%   gimgs: full-resolution images of seedlings
%   gmids: seedling midlines remapped to full-resolution image
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
    CFLO = cFlow('trackingMidlineWhole_remote');
    auth = readtext('/mnt/spaldingdata/nate/auth.iplant');
    auth = auth{1};

    % Make output directory
    node_oPath  = 'output';
    home_oPath  = sprintf('/mnt/tetra/JulianBustamante/Condor/tracking/%s/', ...
        edate);
    gpath       = [home_oPath , gnm , filesep];
    map_command = [node_oPath '>' gpath];

    % Create output directory and set memory limit
    mmkdir(gpath);
    CFLO.addDirectoryMap(map_command);
    CFLO.setMemory('18000');
end

% ---------------------------------------------------------------------------- %
%% Iterate through all Genotypes, Seedlings, and frames
[~ , sprA , sprB] = jprintf(' ', 0, 0, 80);

tA = tic;
fprintf('\n\n%s\n%s\n%s\n\t\t\t\t\t\tMIDLINE TRACKER 2.0\n%s\n%s\n%s\n\n\n\n', ...
    sprA, sprB, sprA, sprA, sprB, sprA);

if isempty(ffrm); ffrm = size(gimgs,1) - 1; end
ipcts           = 0 : 1 / npcts : 1;
[nhyps , nsdls] = size(gmids);

%
tG = tic;
fprintf('%s\n\tTracking %s [%02d Seedlings] from frame %02d to %02d [%02d total]', ...
    sprA, gnm, nsdls, ifrm, ffrm, nhyps);

% ---------------------------------------------------------------------------- %
% For each seedling
TRACK = cell(1,nsdls);
gimgs = gimgs(ifrm : nhyps);
for sidx = 1 : nsdls
    tS = tic;
    fprintf('\n%s\nLoading cFlow object | %s | Seedling %02d of %02d | Frames %03d to %03d [total %03d]\n%s\n', ...
        sprA, gnm, sidx, nsdls, ifrm, ffrm, nhyps, sprB);

    % ------------------------------------------------------------------------ %
    fprintf('\t\t\t\t\tPrepping Condor Object\n%s\n', sprB);
    smids = gmids(:,sidx);
    switch dbug
        case 0
            % Load Condor object
            TRACK{sidx} = CFLO(gimgs, smids, ...
                'ipcts', ipcts, 'ifrm', ifrm, 'ffrm', ffrm, 'skp', skp, ...
                'sav', sav, 'ExperimentName', enm, 'GenotypeName', gnm, ...
                'GenotypeIndex', gidx, 'SeedlingIndex', sidx, 'Frames', nhyps);
        case 1
            % Run locally
            TRACK{sidx} = trackingMidlineWhole_remote(gimgs, smids, ...
                'ipcts', ipcts, 'ifrm', ifrm, 'ffrm', ffrm, 'skp', skp, ...
                'sav', sav, 'ExperimentName', enm, 'GenotypeName', gnm, ...
                'GenotypeIndex', gidx, 'SeedlingIndex', sidx, ...
                'Frames', nhyps, 'dbug', dbug);
        case 2
            % Show input images
            TRACK{sidx} = struct('gimgs', gimgs, 'smids', smids);
            fprintf('GenotypeIndex: %02d\nSeedlingIndex: %02d\nFrame: %02d to %02d [total %02d]\n', ...
                gidx, sidx, ifrm, ffrm, nhyps);
    end

    fprintf('%s\nDONE! [%.03f sec]\n%s\n', sprB, toc(tS), sprA);
end

if dbug == 2
    gttl = fixtitle(gnm);
    for hidx = 1 : nhyps
        myimagesc(gimgs{hidx});
        hold on;
        cellfun(@(x) plt(x, '-', 2), gmids(hidx,:));
        ttl = sprintf('G: %s | S: %02d | F: %02d of %02d', ...
            gttl, sidx, hidx, nhyps);
        title(ttl, 'FontSize', 10);
        drawnow;
        hold off;
    end
end

fprintf('\t\tTracked %0d seedlings for %s! [%.03f sec]\n%s\n\n\n', ...
    nsdls, gnm, toc(tG), sprA);

% Send to condor
if ~dbug; CFLO.submitDag(auth, 50, 50); end

fprintf('\n\n%s\n%s\n%s\n\t\t\t\t\t\tFINISHED TRACKING! [%.03f sec]\n%s\n%s\n%s\n\n\n\n', ...
    sprA, sprB, sprA, toc(tA), sprA, sprB, sprA);
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
% Required
p = inputParser;

%
p.addOptional('skp', 1);
p.addOptional('npcts', 20);
p.addOptional('ifrm', 1);
p.addOptional('ffrm', []);

% Miscellaneous Options
p.addOptional('dbug', 0);
p.addOptional('sav', 0);

% Information Options
p.addOptional('enm', 'experiment');
p.addOptional('gnm', 'genotype');
p.addOptional('gidx', 0);
p.addOptional('edate', tdate);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end