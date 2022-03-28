function [HYPS , CDOR , resultsMap] = segmentationToCondor(gens, varargin)
%% segmentationToCondor: send entire Genotypes to Condor for segmentation
%
%
% Usage:
%   [HYPS , CDOR] = segmentationToCondor(gens, varargin)
%
% Input:
%   gens: array of Genotype objects
%   varargin: various options
%       Model Options
%           ncycs: 1
%           Nz: znnout
%           Nd: dnnout
%           Nb: bnnout
%           pz: pz
%           pm: pm
%           pdp: pdp
%           pdx: pdx
%           pdy: pdy
%           pdw: pdw
%
%       Optimization Options
%           ymin: 10
%           bwid: 0.5
%           toFix: 0
%           seg_lengths: [53 , 52 , 53 , 51]
%
%       Miscellaneous Options
%           nopts: 200
%           dbug: 0
%           par: 0
%           vis: 0
%           sav: 0
%
% Output:
%   HYPS: filepaths to .mat condor results
%   CDOR: cFlow object used to submit condor jobs
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Create cFlow object
if ~dbug
    CDOR = cFlow('segmentFullHypocotyl');
    auth = readtext('/mnt/spaldingdata/nate/auth.iplant');
    auth = auth{1};

    % Make output directory
    node_oPath  = 'output';
    home_oPath  = sprintf('/mnt/tetra/JulianBustamante/Condor/%s/', edate);
    stack_name  = gens.GenotypeName;
    resultsMap  = [home_oPath , stack_name , filesep];
    map_command = [node_oPath '>' resultsMap];
    mmkdir(resultsMap);
    CDOR.addDirectoryMap(map_command);

    % Set memory limit
    CDOR.setMemory('18000');

else
    CDOR = 'dbug on';
end

% ---------------------------------------------------------------------------- %
%% Iterate through all Genotypes, Seedlings, and frames
[~ , sprA , sprB] = jprintf(' ', 0, 0, 80);
fprintf('\n%s', sprA);

% For each genotype
ngens = numel(gens);
HYPS  = cell(ngens,1);
for gidx = 1 : ngens
    g     = gens(gidx);
    spre  = g.getSeedling;
    gnm   = g.GenotypeName;
    mhyps = max(arrayfun(@(x) x.Lifetime, spre));
    schk  = arrayfun(@(x) x.Lifetime == mhyps, spre);
    sidxs = find(schk);
    sgud  = spre(schk);
    nsdls = numel(sgud);

    % ------------------------------------------------------------------------ %
    % For each seedling
    HYPS{gidx} = cell(mhyps,nsdls);
    for ns = 1 : nsdls
        sidx  = sidxs(ns);
        s     = sgud(ns);
        h     = s.MyHypocotyl;
        nhyps = h.Lifetime;

        % -------------------------------------------------------------------- %
        % For each frame
        for hidx = 1 : nhyps
            t = tic;
            fprintf('\n%s\nLoading cFlow object | %s | Genotype %02d of %02d | Seedling %02d of %02d | Frame %03d of %03d\n%s\n', ...
                sprA, gnm, gidx, ngens, sidx, nsdls, hidx, nhyps, sprB);

            % Upper Region
            fprintf('Upper Hypocotyl | ');
            try
                uimg = h.getImage(hidx, 'gray', 'upper');
                fprintf('gidx %02d | sidx %02d | hidx %02d | [good] |\n', ...
                    gidx, sidx, hidx);
            catch
                fprintf(2, 'No upper image [%s | gidx %02d | sidx %02d | hidx %02d |\n', ...
                    gnm, gidx, sidx, hidx);
                uimg = [];
            end

            % Lower Region
            fprintf('Lower Hypocotyl | ');
            try
                lmsk = h.getImage(hidx, 'bw', 'lower');
                fprintf('gidx %02d | sidx %02d | hidx %02d | [good] |\n', ...
                    gidx, sidx, hidx);
            catch
                fprintf(2, 'No lower mask [%s | gidx %02d | sidx %02d | hidx %02d |\n', ...
                    gnm, gidx, sidx, hidx);
                lmsk = [];
            end

            % ---------------------------------------------------------------- %
            fprintf('%s\n\t\t\t\t\tPrepping Condor Object\n%s\n', sprB, sprB);
            switch dbug
                case 0
                    % Load Condor object
                    %                     CDOR(uimg, lmsk, ...
                    HYPS{gidx}{hidx,ns} = CDOR(uimg, lmsk, ...
                        'Nb', Nb, 'Nz', Nz, 'pz', pz, 'Nd', Nd, 'pdp', pdp, ...
                        'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'pm', pm, ...
                        'toFix', toFix, 'bwid', bwid, 'nopts', nopts, ...
                        'seg_lengths', seg_lengths, 'par', par, 'vis', vis, ...
                        'sav', sav, 'Frame', hidx, 'GenotypeName', gnm, ...
                        'GenotypeIndex', gidx, 'SeedlingIndex', sidx);
                case 1
                    % Show input images
                    HYPS{gidx}{hidx,ns} = struct('uimg', uimg, 'lmsk', lmsk);
                    subplot(121); myimagesc(uimg);
                    subplot(122); myimagesc(lmsk); drawnow;
                    fprintf('Genotype: %s\nGenotypeIndex: %02d\nSeedlingIndex: %02d\nFrame: %02d\n', ...
                        gnm, gidx, sidx, hidx);
                case 2
                    % Run locally without optimization
                    nopts = 0;
                    HYPS{gidx}{hidx,ns} = segmentFullHypocotyl(uimg, lmsk, ...
                        'Nb', Nb, 'Nz', Nz, 'pz', pz, 'Nd', Nd, 'pdp', pdp, ...
                        'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'pm', pm, ...
                        'toFix', toFix, 'bwid', bwid, 'nopts', nopts, ...
                        'seg_lengths', seg_lengths, 'par', par, 'vis', vis, ...
                        'sav', sav, 'Frame', hidx, 'GenotypeName', gnm, ...
                        'GenotypeIndex', gidx, 'SeedlingIndex', sidx);
            end

            fprintf('%s\nDONE! [%.03f sec]\n%s\n', sprB, toc(t), sprA);
        end
    end
end

fprintf('%s\n', sprA);

% Send to condor
if ~dbug; CDOR.submitDag(auth, 50, 50); end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
% Required
p = inputParser;
p.addOptional('ncycs', 1);

% Model Options
p.addOptional('Nz', 'znnout');
p.addOptional('Nd', 'dnnout');
p.addOptional('Nb', 'bnnout');
p.addOptional('pz', 'pz');
p.addOptional('pm', 'pm');
p.addOptional('pdp', 'pdp');
p.addOptional('pdx', 'pdx');
p.addOptional('pdy', 'pdy');
p.addOptional('pdw', 'pdw');

% Optimization Options
% p.addOptional('ymin', 10);
p.addOptional('bwid', 0.5);
p.addOptional('toFix', 0);
p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);

% Miscellaneous Options
p.addOptional('nopts', 200);
p.addOptional('dbug', 0);
p.addOptional('edate', tdate);
p.addOptional('par', 0);
p.addOptional('vis', 0);
p.addOptional('sav', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
