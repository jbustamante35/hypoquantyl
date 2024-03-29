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
    [HYPS , CFLO] = deal('dbug on');
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
HDOR  = cell(mhyps,nsdls);
if isempty(fsdl); fsdl = nsdls; end
asdls = isdl : fsdl;

tg = tic;
fprintf('\n\n%s\n%s\n\n\n%s | %d Frames | %d Seedlings\n\n\n%s\n%s', ...
    sprB, sprB, gnm, geno.TotalImages, nsdls, sprB, sprB);
for ns = asdls
    sidx  = sidxs(ns);
    s     = sgud(ns);
    h     = s.MyHypocotyl;
    nhyps = h.Lifetime;

    % ------------------------------------------------------------------------ %
    % For each frame
    if isempty(fhyp); fhyp = nhyps; end
    ahyps = ihyp : fhyp;

    if par
        % ------------------------------------------------------------------------ %
        %% Run with parallel
        ts = tic;
        fprintf('\n\n%s | Seedling %d of %d | %d Frames\n', ...
            gnm, sidx, nsdls, fhyp);
        
        % Collect all upper images and lower masks first
        [uimgs , lmsks] = deal(cell(numel(ahyps),1));
        for hidx = ahyps
            % Upper Region
            fprintf('\nUpper Hypocotyl ');
            try
                uimgs{hidx} = h.getImage( ...
                    hidx, 'gray', 'upper', [], mbuf, abuf, scl);
                if ~isempty(hhist)
                    href  = hhist.Data;
                    hmth  = hhist.Tag;
                    nbins = hhist.NumBins;
                    uimgs{hidx}  = normalizeImageWithHistogram( ...
                        uimgs{hidx}, href, hmth, nbins);
                end

                fprintf('| %s | gidx %02d | sidx %02d | hidx %02d | [good] |\n', ...
                    gnm, gidx, sidx, hidx);
            catch
                fprintf(2, '| %s | gidx %02d | sidx %02d | hidx %02d | [No upper image] |\n', ...
                    gnm, gidx, sidx, hidx);
                uimgs{hidx} = [];
            end

            % Lower Region
            fprintf('Lower Hypocotyl ');
            try
                lmsks{hidx} = h.getImage( ...
                    hidx, 'bw', 'lower', [], mbuf, abuf, scl);
                fprintf('| %s | gidx %02d | sidx %02d | hidx %02d | [good] |\n', ...
                    gnm, gidx, sidx, hidx);
            catch
                fprintf(2, '| %s | gidx %02d | sidx %02d | hidx %02d | [No lower mask] |\n', ...
                    gnm, gidx, sidx, hidx);
                lmsks{hidx} = [];
            end
        end

        % -------------------------------------------------------------------- %
        %% This doesn't work yet 
        % Can't use in-script locally-generated variables in parfor loops
%         nopts = 0;
%         parfor hidx = ahyps
%             th = tic;
%             fprintf('%s\n\t\t\t\t\tPrepping Condor Object\n%s\n', sprB, sprB);
% 
%             uimg = uimgs{hidx};
%             lmsk = lmsks{hidx};
%             switch dbug
%                 case 0
%                     % Load Condor object
%                     %                     HDOR{hidx,ns} = CFLO(uimg, lmsk, 'edate', edate, ...
%                     %                         'Nb', Nb, 'Nz', Nz, 'pz', pz, 'Nd', Nd, 'pdp', pdp, ...
%                     %                         'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'pm', pm, ...
%                     %                         'toFix', toFix, 'bwid', bwid, 'nopts', nopts, ...
%                     %                         'seg_lengths', seg_lengths, 'par', 0, 'vis', vis, ...
%                     %                         'sav', sav, 'Frame', hidx, 'GenotypeName', gnm, ...
%                     %                         'GenotypeIndex', gidx, 'SeedlingIndex', sidx);
%                 case 1
%                     % Show input images
%                     HDOR{hidx,ns} = struct('uimg', uimg, 'lmsk', lmsk);
%                     fprintf('Genotype: %s\nGenotypeIndex: %02d\nSeedlingIndex: %02d\nFrame: %02d\n', ...
%                         gnm, gidx, sidx, hidx);
%                 case 2
%                     % Run locally without optimization
%                     HDOR{hidx,ns} = segmentFullHypocotyl(uimg, lmsk, 'edate', edate, ...
%                         'Nb', Nb, 'Nz', Nz, 'pz', pz, 'Nd', Nd, 'pdp', pdp, ...
%                         'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'pm', pm, ...
%                         'toFix', toFix, 'bwid', bwid, 'nopts', nopts, ...
%                         'seg_lengths', seg_lengths, 'par', 0, 'vis', vis, ...
%                         'fidx', fidx, 'sav', sav, 'Frame', hidx, ...
%                         'GenotypeName', gnm, 'GenotypeIndex', gidx, ...
%                         'SeedlingIndex', sidx, 'toFlip', toFlip, ...
%                         'keepBoth', keepBoth, 'path2subs', path2subs);
%             end
% 
%             fprintf('%s\nFINISHED FRAME %d of %d [Seedling %d of %d] (%s) [%.03f sec]\n%s\n', ...
%                 sprB, hidx, fhyp, sidx, nsdls, gnm, toc(th), sprA);
%         end
        fprintf('\n\nFINISHED SEEDLING %d of %d (%s) | %d Frames [%.03f sec]\n\n%s', ...
        sidx, nsdls, gnm, fhyp, toc(ts), sprB);
    else
        % ------------------------------------------------------------------------ %
        %% Run on single thread
        ts = tic;
        fprintf('\n\n%s | Seedling %d of %d | %d Frames\n', ...
            gnm, sidx, nsdls, fhyp);
        for hidx = ahyps
            th = tic;
            fprintf('\n%s\nLoading cFlow object | %s | Genotype %02d | Seedling %02d of %02d | Frame %03d of %03d\n%s\n', ...
                sprA, gnm, gidx, sidx, nsdls, hidx, fhyp, sprB);

            % Upper Region
            fprintf('Upper Hypocotyl ');
            try
                uimg = h.getImage(hidx, 'gray', 'upper', [], mbuf, abuf, scl);
                if ~isempty(hhist)
                    href  = hhist.Data;
                    hmth  = hhist.Tag;
                    nbins = hhist.NumBins;
                    uimg  = normalizeImageWithHistogram(uimg, href, hmth, nbins);
                end

                fprintf('| %s | gidx %02d | sidx %02d | hidx %02d | [good] |\n', ...
                    gnm, gidx, sidx, hidx);
            catch
                fprintf(2, '| %s | gidx %02d | sidx %02d | hidx %02d | [No upper image] |\n', ...
                    gnm, gidx, sidx, hidx);
                uimg = [];
            end

            % Lower Region
            fprintf('Lower Hypocotyl ');
            try
                lmsk = h.getImage(hidx, 'bw', 'lower', [], mbuf, abuf, scl);
                fprintf('| %s | gidx %02d | sidx %02d | hidx %02d | [good] |\n', ...
                    gnm, gidx, sidx, hidx);
            catch
                fprintf(2, '| %s | gidx %02d | sidx %02d | hidx %02d | [No lower mask] |\n', ...
                    gnm, gidx, sidx, hidx);
                lmsk = [];
            end

            % -------------------------------------------------------------------- %
            fprintf('%s\n\t\t\t\t\tPrepping Condor Object\n%s\n', sprB, sprB);
            switch dbug
                case 0
                    % Load Condor object
                    HDOR{hidx,ns} = CFLO(uimg, lmsk, 'edate', edate, ...
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

                    % Segmentation
                    HDOR{hidx,ns} = segmentFullHypocotyl(uimg, lmsk, 'edate', edate, ...
                        'Nb', Nb, 'Nz', Nz, 'pz', pz, 'Nd', Nd, 'pdp', pdp, ...
                        'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'pm', pm, ...
                        'toFix', toFix, 'bwid', bwid, 'nopts', nopts, ...
                        'seg_lengths', seg_lengths, 'par', par, 'vis', vis, ...
                        'fidx', fidx, 'sav', sav, 'Frame', hidx, ...
                        'GenotypeName', gnm, 'GenotypeIndex', gidx, ...
                        'SeedlingIndex', sidx, 'toFlip', toFlip, ...
                        'keepBoth', keepBoth, 'path2subs', path2subs);
            end

            fprintf('%s\nFINISHED FRAME %d of %d [Seedling %d of %d] (%s) [%.03f sec]\n%s\n', ...
                sprB, hidx, fhyp, sidx, nsdls, gnm, toc(th), sprA);
        end
    end
    fprintf('\n\nFINISHED SEEDLING %d of %d (%s) | %d Frames [%.03f sec]\n\n%s', ...
        sidx, nsdls, gnm, fhyp, toc(ts), sprB);
end
fprintf('\n\nFINISHED GENOTYPE %s | %d Frames | %d Seedlings |  [%.03f sec]\n\n\n%s\n%s\n%s\n', ...
    gnm, size(HDOR), toc(tg), sprA, sprA, sprA);

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
p.addOptional('path2subs', 0);

% Optimization Options
% p.addOptional('ymin', 10);
p.addOptional('bwid', 0.5);
p.addOptional('toFix', 0);
p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);
p.addOptional('hhist', []);
p.addOptional('mbuf', 0);
p.addOptional('abuf', 0);
p.addOptional('scl', 1);

% Miscellaneous Options
p.addOptional('gidx', 0);
p.addOptional('nopts', 200);
p.addOptional('dbug', 0);
p.addOptional('edate', tdate);
p.addOptional('par', 0);
p.addOptional('sav', 0);
p.addOptional('vis', 0);
p.addOptional('fidx', 0);
p.addOptional('toFlip', []);
p.addOptional('keepBoth', 0);
p.addOptional('isdl', 1);
p.addOptional('ihyp', 1);
p.addOptional('fsdl', []);
p.addOptional('fhyp', []);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
