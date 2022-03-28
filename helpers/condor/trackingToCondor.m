function [TRACK , CDOR] = trackingToCondor(GIMGS, GMIDS, varargin)
%% trackingToCondor: send tracking jobs to condor
%
%
% Usage:
%   [TRACK , CDOR] = trackingToCondor(GIMGS, GMIDS, varargin)
%
% Input:
%   GMIGS: full-resolution images of seedlings
%   GMIDS: seedling midlines remapped to full-resolution image
%   varargin: various options
%
% Output:
%   TRACK: filepaths to .mat condor results
%   CDOR: cFlow object used to submit condor jobs

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Create cFlow object
if ~dbug
    CDOR = cFlow('trackingMidlineWhole_remote');
    auth = readtext('/mnt/spaldingdata/nate/auth.iplant');
    auth = auth{1};
else
    CDOR = 'dbug on';
end

% ---------------------------------------------------------------------------- %
%% Iterate through all Genotypes, Seedlings, and frames
[~ , sprA , sprB] = jprintf(' ', 0, 0, 80);

tA = tic;
fprintf('\n\n%s\n%s\n%s\n\t\t\t\t\t\tMIDLINE TRACKER 1.5\n%s\n%s\n%s\n\n\n\n', ...
    sprA, sprB, sprA, sprA, sprB, sprA);

% For each genotype
ngens = numel(GIMGS);
TRACK = cell(ngens,1);

if isempty(gnms)
    gnms = arrayfun(@(x) 'genotype', (1 : ngens)', 'UniformOutput', 0);
end

if isempty(ffrm)
    FFRMS = cellfun(@(x) size(x,1) - 1, GIMGS);
else
    FFRMS = repmat(ffrm, ngens, 1);
end

ipcts = 0 : 1 / npcts : 1;
for gidx = 1 : ngens
    gnm   = gnms{gidx};
    gimgs = GIMGS{gidx};
    gmids = GMIDS{gidx};
    ffrm  = FFRMS(gidx);
    [nhyps , nsdls] = size(gmids);

    %
    tG = tic;
    fprintf('%s\n\tTracking Genotype %02d of %02d [%02d Seedlings] from frame %02d to %02d [%02d total]', ...
        sprA, gidx, ngens, nsdls, ifrm, ffrm, nhyps);

    % ------------------------------------------------------------------------ %
    % For each seedling
    TRACK{gidx} = cell(1,nsdls);
    gimgs       = gimgs(ifrm : nhyps);
    for sidx = 1 : nsdls
        tS = tic;
        fprintf('\n%s\nLoading cFlow object | Genotype %02d of %02d | Seedling %02d of %02d | Frames %03d to %03d [total %03d]\n%s\n', ...
            sprA, gidx, ngens, sidx, nsdls, ifrm, ffrm, nhyps, sprB);

        % -------------------------------------------------------------------- %
        fprintf('\t\t\t\t\tPrepping Condor Object\n%s\n', sprB);
        smids = gmids(:,sidx);
        switch dbug
            case 0
                % Load Condor object
                TRACK{gidx}{sidx} = CDOR(gimgs, smids, ...
                    'ipcts', ipcts, 'ifrm', ifrm, 'ffrm', ffrm, 'skp', skp, ...
                    'GenotypeName', gnm, 'GenotypeIndex', gidx, ...
                    'SeedlingIndex', sidx, 'Frames', nhyps);
            case 1
                % Run locally
                TRACK{gidx}{sidx} = trackingMidlineWhole_remote(gimgs, smids, ...
                    'ipcts', ipcts, 'ifrm', ifrm, 'ffrm', ffrm, 'skp', skp, ...
                    'GenotypeName', gnm, 'GenotypeIndex', gidx, ...
                    'SeedlingIndex', sidx, 'Frames', nhyps, 'dbug', dbug);
            case 2
                % Show input images
                TRACK{gidx}{sidx} = struct('gimgs', gimgs, 'smids', smids);
                fprintf('GenotypeIndex: %02d\nSeedlingIndex: %02d\nFrame: %02d to %02d [total %02d]\n', ...
                    gidx, sidx, ifrm, ffrm, nhyps);
        end

        fprintf('%s\nDONE! [%.03f sec]\n%s\n', sprB, toc(tS), sprA);
    end

    if dbug == 1
        for hidx = 1 : numel(gimgs)
            myimagesc(gimgs{hidx});
            hold on;
            cellfun(@(x) plt(x, '-', 2), gmids(hidx,:));
            ttl = sprintf('G: %02d | S: %02d | F: %02d of %02d', ...
                gidx, sidx, hidx, nhyps);
            title(ttl, 'FontSize', 10);
            drawnow;
            hold off;
        end
    end

    fprintf('\t\tTracked %0d seedlings for genotype %02d of %02d! [%.03f sec]\n%s\n\n\n', ...
        nsdls, gidx, ngens, toc(tG), sprA);
end

% Send to condor
if ~dbug; CDOR.submitDag(auth, 50, 50); end

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
p.addOptional('gnms', []);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end