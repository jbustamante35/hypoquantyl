function [HDOR , HYPS , CFLO] = segmentationToCondor(geno, varargin)
%% segmentationToCondor: send entire Genotypes to Condor for segmentation
%
%
% Usage:
%   [HDOR , HYPS , CFLO] = segmentationToCondor(geno, varargin)
%
% Input:
%   geno: Genotype object
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
%   HDOR: filepaths to .mat condor results
%   HYPS: filepath to directoy of specifically-named condor results
%   CFLO: cFlow object used to submit condor jobs
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

% Check mode
if dbug
    % Debug mode
    CFLO = 'dbug on';
else
    % Create cFlow object
    CFLO = cFlow('segmentFullHypocotyl');
    auth = readtext('/mnt/spaldingdata/nate/auth.iplant');
    auth = auth{1};

    % Make output directory
    node_oPath  = 'output';
    home_oPath  = sprintf('/mnt/tetra/JulianBustamante/Condor/segmentation/%s/', ...
        edate);
    stack_name  = geno.GenotypeName;
    HYPS        = [home_oPath , stack_name , filesep];
    map_command = [node_oPath '>' HYPS];

    % Create output directory and set memory limit
    mmkdir(HYPS);
    CFLO.addDirectoryMap(map_command);
    CFLO.setMemory('18000');
end

% ---------------------------------------------------------------------------- %
%% Iterate through all Seedlings and frames
[~ , sprA , sprB] = jprintf(' ', 0, 0, 80);
fprintf('\n%s', sprA);

% For each genotype
spre  = geno.getSeedling;
gnm   = geno.GenotypeName;
mhyps = max(arrayfun(@(x) x.Lifetime, spre));
schk  = arrayfun(@(x) x.Lifetime == mhyps, spre);
sidxs = find(schk);
sgud  = spre(schk);
nsdls = numel(sgud);

% ---------------------------------------------------------------------------- %
% For each seedling
HDOR = cell(mhyps,nsdls);
for ns = 1 : nsdls
    sidx  = sidxs(ns);
    s     = sgud(ns);
    h     = s.MyHypocotyl;
    nhyps = h.Lifetime;

    % ------------------------------------------------------------------------ %
    % For each frame
    for hidx = 1 : nhyps
        t = tic;
        fprintf('\n%s\nLoading cFlow object | %s | Genotype %02d | Seedling %02d of %02d | Frame %03d of %03d\n%s\n', ...
            sprA, gnm, gidx, sidx, nsdls, hidx, nhyps, sprB);

        % Upper Region
        fprintf('Upper Hypocotyl | ');
        try
            uimg = h.getImage(hidx, 'gray', 'upper');
            fprintf('| %s | gidx %02d | sidx %02d | hidx %02d | [good] |\n', ...
                gnm, gidx, sidx, hidx);
        catch
            fprintf(2, 'No upper image [%s | gidx %02d | sidx %02d | hidx %02d |\n', ...
                gnm, gidx, sidx, hidx);
            uimg = [];
        end

        % Lower Region
        fprintf('Lower Hypocotyl | ');
        try
            lmsk = h.getImage(hidx, 'bw', 'lower');
            fprintf('| %s | gidx %02d | sidx %02d | hidx %02d | [good] |\n', ...
                gnm, gidx, sidx, hidx);
        catch
            fprintf(2, 'No lower mask [%s | gidx %02d | sidx %02d | hidx %02d |\n', ...
                gnm, gidx, sidx, hidx);
            lmsk = [];
        end

        % -------------------------------------------------------------------- %
        fprintf('%s\n\t\t\t\t\tPrepping Condor Object\n%s\n', sprB, sprB);
        switch dbug
            case 0
                % Load Condor object
                HDOR{hidx,ns} = CFLO(uimg, lmsk, ...
                    'Nb', Nb, 'Nz', Nz, 'pz', pz, 'Nd', Nd, 'pdp', pdp, ...
                    'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'pm', pm, ...
                    'toFix', toFix, 'bwid', bwid, 'nopts', nopts, ...
                    'seg_lengths', seg_lengths, 'par', par, 'vis', vis, ...
                    'sav', sav, 'Frame', hidx, 'GenotypeName', gnm, ...
                    'GenotypeIndex', gidx, 'SeedlingIndex', sidx);
            case 1
                % Show input images
                HDOR{hidx,ns} = struct('uimg', uimg, 'lmsk', lmsk);
                subplot(121); myimagesc(uimg);
                subplot(122); myimagesc(lmsk); drawnow;
                fprintf('Genotype: %s\nGenotypeIndex: %02d\nSeedlingIndex: %02d\nFrame: %02d\n', ...
                    gnm, gidx, sidx, hidx);
            case 2
                % Run locally without optimization
                nopts = 0;
                HDOR{hidx,ns} = segmentFullHypocotyl(uimg, lmsk, ...
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

fprintf('%s\n', sprA);

% Send to condor
if ~dbug; CFLO.submitDag(auth, 50, 50); end
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
p.addOptional('gidx', 0);
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
