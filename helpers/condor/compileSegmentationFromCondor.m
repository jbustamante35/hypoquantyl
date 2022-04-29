function [GMIDS , GSRCS , HSRCS] = compileSegmentationFromCondor(HOUT, gens, varargin)
%% compileSegmentationFromCondor: remap predictions to full resolution images
%
%
% Usage:
%   [GMIDS , GSRCS , HSRCS] = compileSegmentationFromCondor( ...
%       HOUT, gens, varargin)
%
% Input:
%   HOUT: structur array of condor results
%   gens: Genotype objects predicted
%   varargin: various options
%
% Output:
%   GMIDS: midlines remapped from predictions
%   GSRCS: full data from remapped contours
%   HSRCS: data from predicted contours
%

%% Parse additional inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%%
[~ , sprA , sprB] = jprintf(' ', 0, 0, 80);

ngens = numel(gens);
[GMIDS , GSRCS , HSRCS] = deal(cell(size(HOUT)));
for gidx = 1 : ngens
    % Extract genotype data
    hout = HOUT{gidx};
    if iscell(hout); hout  = cell2mat(hout); end

    g    = gens(gidx);
    gnm  = g.GenotypeName;
    sgud = arrayfun(@(x) x.info.SeedlingIndex, hout(1,:));
    s    = g.getSeedling(sgud);
    h    = arrayfun(@(x) x.MyHypocotyl, s);

    [nhyps , nsdls]         = size(hout);
    [gmids , gsrcs , hsrcs] = deal(cell(nhyps,nsdls));

    % Perform remapping
    tR = tic;
    fprintf('\n%s\n\t\tRemapping %s [%02d of %02d | %d Seedlings | %d Frames]\n%s\n', ...
        sprA, gnm, gidx, ngens, nsdls, nhyps, sprB);
    for hidx = 1 : nhyps
        for sidx = 1 : nsdls
            t = tic;
            fprintf('| %s [%d of %d] | Seedling %02d of %02d | Frame %02d of %02d | ', ...
                gnm, gidx, ngens, sidx, nsdls, hidx, nhyps);

            % Extract condor results
            uout = hout(hidx,sidx).uhyp;
            lout = hout(hidx,sidx).lhyp;

            % Seedling propeties
            simg = s(sidx).getImage(hidx);
            sbox = s(sidx).getPData(hidx, 'BoundingBox');

            % Upper region
            uimg   = h(sidx).getImage(hidx, 'gray', 'upper');
            ubox   = h(sidx).getCropBox(hidx, 'upper');
            hcupp  = uout.opt.c;
            hmupp  = uout.opt.m;

            % Lower region
            try
                lmsk  = h(sidx).getImage(hidx, 'bw', 'lower');
                lbox  = h(sidx).getCropBox(hidx, 'lower');
                hclow = lout.c;
                hmlow = lout.m;
            catch
                [lmsk , lbox] = deal([]);
                hclow         = lout.c;
                hmlow         = lout.m;
            end

            % Check for errors
            isgood = hout(hidx,sidx).isgood;
            if sum(isgood) ~= 2
                fprintf(2, 'ERROR [%d %d] (attempting to fix) | ', isgood);
            end

            % Remap hypocotyl image to full-resolution image
            [gmids{hidx,sidx} , gsrcs{hidx,sidx} , hsrcs{hidx,sidx}] = ...
                getDomainInputs_remote(simg, uimg, lmsk, sbox, ubox, lbox, ...
                toFlip, 'bpredict', bpredict, 'zpredict', zpredict, ...
                'cpredict', cpredict, 'mline', mline, 'dsz', dsz, 'npts', npts, ...
                'init', init, 'creq', creq, 'mth', mth, 'slens', slens, ...
                'slen', slen, 'msz', msz, 'hcupp', hcupp, 'hmupp', hmupp, ...
                'hclow', hclow, 'hmlow', hmlow);

            fprintf('DONE! [%.03f sec]\n', toc(t));
        end
    end

    % Store results from genotype
    GMIDS{gidx} = gmids;
    GSRCS{gidx} = gsrcs;
    HSRCS{gidx} = hsrcs;

    fprintf('%s\n\t\t\t\t\tFINISHED [%.03f sec]\n%s\n', sprB, toc(tR), sprA);
end

%% Store final results into structure and Save
S = struct('GMIDS', GMIDS, 'GSRCS', GSRCS, 'HSRCS', HSRCS);
if sav
    t = tic;
    fprintf('%s\nSaving data for %d Genotypes [%s]...', ...
        sprB, ngens, gset);
    sdir = sprintf('compile_segmentation');
    if ~isfolder(sdir); mkdir(sdir); end
    snm  = sprintf('%s/%s_compile_segmentation_%02dgenotypes_%s', ...
        sdir, tdate, ngens, gset);
    save(snm, '-v7.3', 'S');
    fprintf('DONE! [%.03f sec]\n%s\n', toc(t), sprA);
end

if nargout == 1; GMIDS = S; end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;
p.addOptional('bpredict', []);
p.addOptional('zpredict', []);
p.addOptional('cpredict', []);
p.addOptional('mline', []);
p.addOptional('dsz', 3);
p.addOptional('npts', 210);
p.addOptional('init', 'alt');
p.addOptional('creq', 'Normalize');
p.addOptional('mth', 1);
p.addOptional('smth', 1);
p.addOptional('slens', [53 , 52 , 53 , 51]);
p.addOptional('slen', 51);
p.addOptional('msz', 50);
p.addOptional('toFlip', 0);
p.addOptional('hcupp', []);
p.addOptional('hmupp', []);
p.addOptional('hclow', []);
p.addOptional('hmlow', []);
p.addOptional('gset', 'gset');
p.addOptional('fidx', 0);
p.addOptional('sav', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
