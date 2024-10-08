function GSEGS = hypocotylSegmenter(gens, edate, vrb, path2subs, keepBoth, Nb, Nz, pz, Nd, pdp, pdx, pdy, pdw, pm, bpredict, zpredict, cpredict, sopt, mline, mscore, msample, myShps, zoomLvl, mpts, mmth, mparams, stolf, stolx, toFix, bwid, nopts, dsz, smth, npts, slens, mbuf, abuf, scl, href, par, flp, isdl, ihyp)
%% hypocotylSegmenter: segmentation pipeline on a full dataset
% This is a wrapper script for the full segmentation pipeline
%
% Usage:
%   GSEGS = hypocotylSegmenter(gens, edate, vrb, path2subs, keepBoth, ...
%     Nb, Nz, pz, Nd, pdp, pdx, pdy, pdw, pm, ...
%     bpredict, zpredict, cpredict, sopt, mline, mscore, msample, myShps, ...
%     zoomLvl, mpts, mmth, mparams, stolf, stolx, toFix, bwid, nopts, ...
%     dsz, smth, npts, slens, mbuf, abuf, scl, href, par, flp, isdl, ihyp);
%
% Input:
%
%
% Output:
%
%

%% 
ngens = numel(gens);
GSEGS = cell(ngens, 1);
te = tic;
fprintf(['\n\n\n%s\n%s\n%s\n\n\nSEGMENTING %02d GENOTYPES' ...
    '\n\n\n%s\n%s\n%s\n\n\n'], sprA, sprA, sprA, ngens, sprA, sprA, sprA);
for gi = 1 : ngens
    % For each genotype
    gidx  = gi;
    gen   = gens(gidx);
    sdls  = gen.getSeedling;
    gttl  = gen.GenotypeName;
    mhyps = max(arrayfun(@(x) x.Lifetime, sdls));
    sidxs = arrayfun(@(x) x.getSeedlingIndex, sdls);
    nsdls = numel(sdls);

    tg = tic;
    fprintf('\n%s\nSEGMENTING GENOTYPE %02d of %02d [%s]\n%s\n', ...
        sprA, gi, ngens, gttl, sprA);

    % ------------------------------------------------------------------------ %
    % For each seedling
    fsdl  = nsdls;
    HSEG  = cell(mhyps,nsdls);
    asdls = isdl : fsdl;

    fprintf('\n\n%s\n%s\n\n\n%s | %d Frames | %d Seedlings\n\n\n%s\n%s', ...
        sprB, sprB, gttl, gen.TotalImages, fsdl, sprB, sprB);
    for ns = asdls
        sidx  = sidxs(ns);
        s     = sdls(ns);
        h     = s.MyHypocotyl;
        nhyps = h.Lifetime;

        % -------------------------------------------------------------------- %
        % For each frame
        fhyp  = nhyps;
        ahyps = ihyp : fhyp;

        ts = tic;
        fprintf('\n\n%s | Seedling %d of %d | %d Frames\n', ...
            gttl, sidx, fsdl, fhyp);

        % Collect all upper images and lower masks first
        [uimgs , lmsks] = deal(cell(numel(ahyps),1));
        for hidx = ahyps
            % ---------------------- Upper Region ---------------------------- %
            if vrb; fprintf('\nUpper Hypocotyl '); end
            try
                uimgs{hidx} = h.getImage( ...
                    hidx, 'gray', 'upper', [], mbuf, abuf, scl);

                if vrb
                    fprintf(['| %s | gidx %02d | sidx %02d | hidx %02d | ' ...
                        '[good] |\n'], gttl, gidx, sidx, hidx);
                end
            catch
                fprintf(2, ['| %s | gidx %02d | sidx %02d | hidx %02d | ' ...
                    '[No upper image] |\n'], gttl, gidx, sidx, hidx);
                uimgs{hidx} = [];
            end

            % ---------------------- Upper Region ---------------------------- %
            if vrb; fprintf('Lower Hypocotyl '); end
            try
                lmsks{hidx} = h.getImage( ...
                    hidx, 'bw', 'lower', [], mbuf, abuf, scl);

                if vrb
                    fprintf(['| %s | gidx %02d | sidx %02d | hidx %02d | ' ...
                        '[good] |\n'], gttl, gidx, sidx, hidx);
                end
            catch
                fprintf(2, ['| %s | gidx %02d | sidx %02d | hidx %02d | ' ...
                    '[No lower mask] |\n'], gttl, gidx, sidx, hidx);
                lmsks{hidx} = [];
            end
        end

        % ---------------------- Parallel Segmentation ----------------------- %
        if par
            ncores = feature('numcores');
            pcores = ncores * 0.75; % Use 3/4 cores available
            setupParpool(pcores, 1);
            parfor hidx = ahyps
                th = tic;
                fprintf(['%s\n\t\t\t\t\tSegmenting on ' ...
                    'parallel threads\n%s\n'], sprB, sprB);
                uimg = uimgs{hidx};
                lmsk = lmsks{hidx};

                % Make input parameters visable in each thread [weird hack]
                HSEG{hidx,ns} = segmentFullHypocotyl(uimg, lmsk, 'edate', edate, ...
                    'Nb', Nb, 'Nz', Nz, 'pz', pz, 'Nd', Nd, 'pdp', pdp, ...
                    'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'pm', pm, ...
                    'bpredict', bpredict, 'zpredict', zpredict, ...
                    'cpredict', cpredict, 'sopt', sopt, 'mline', mline, ...
                    'mscore', mscore, 'msample', msample, 'myShps', myShps, ...
                    'zoomLvl', zoomLvl, 'mpts', mpts, 'mmth', mmth, ...
                    'mparams', mparams, 'tolfun', stolf, 'tolx', stolx, ...
                    'toFix', toFix, 'bwid', bwid, 'nopts', nopts, 'dsz', dsz, ...
                    'smth', smth, 'npts', npts, 'seg_lengths', slens, ...
                    'mbuf', mbuf, 'scl', scl, 'href', href, 'par', 0, ...
                    'vis', 0, 'fidx', 0, 'sav', 0, 'Frame', hidx, ...
                    'GenotypeName', gttl, 'GenotypeIndex', gidx, ...
                    'SeedlingIndex', sidx, 'toFlip', flp, 'keepBoth', keepBoth, ...
                    'path2subs', path2subs);

                fprintf(['%s\nFINISHED FRAME %d of %d ' ...
                    '[Seedling %d of %d] (%s) [%.03f sec]\n%s\n'], ...
                    sprB, hidx, fhyp, sidx, nsdls, gttl, mytoc(th, 'sec'), sprA);
            end
        else
            % ------------------ Single-Thread Segmentation ------------------ %
            for hidx = ahyps
                th = tic;
                fprintf(['%s\n\t\t\t\t\tSegmenting on ' ...
                    'single-thread\n%s\n'], sprB, sprB);
                uimg = uimgs{hidx};
                lmsk = lmsks{hidx};
                HSEG{hidx,ns} = segmentFullHypocotyl(uimg, lmsk, 'edate', edate, ...
                    'Nb', Nb, 'Nz', Nz, 'pz', pz, 'Nd', Nd, 'pdp', pdp, ...
                    'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'pm', pm, ...
                    'bpredict', bpredict, 'zpredict', zpredict, ...
                    'cpredict', cpredict, 'sopt', sopt, 'mline', mline, ...
                    'mscore', mscore, 'msample', msample, 'myShps', myShps, ...
                    'zoomLvl', zoomLvl, 'mpts', mpts, 'mmth', mmth, ...
                    'mparams', mparams, 'tolfun', stolf, 'tolx', stolx, ...
                    'toFix', toFix, 'bwid', bwid, 'nopts', nopts, 'dsz', dsz, ...
                    'smth', smth, 'npts', npts, 'seg_lengths', slens, ...
                    'mbuf', mbuf, 'scl', scl, 'href', href, 'par', 0, ...
                    'vis', 0, 'fidx', 0, 'sav', 0, 'Frame', hidx, ...
                    'GenotypeName', gttl, 'GenotypeIndex', gidx, ...
                    'SeedlingIndex', sidx, 'toFlip', flp, 'keepBoth', keepBoth, ...
                    'path2subs', path2subs);

                fprintf(['%s\nFINISHED FRAME %d of %d ' ...
                    '[Seedling %d of %d] (%s) [%.03f sec]\n%s\n'], ...
                    sprB, hidx, fhyp, sidx, nsdls, gttl, mytoc(th, 'sec'), sprA);
            end
        end

        fprintf(['\n\nFINISHED SEEDLING %d of %d (%s) | ' ...
            '%d Frames [%.03f sec]\n\n%s'], ...
            sidx, fsdl, gttl, fhyp, mytoc(ts, 'min'), sprB);
    end

    GSEGS{gidx} = HSEG;
    fprintf('\n%s\nFINSIHED %s GENOTYPE %02d of %02d [%.03f sec]\n%s\n', ...
        sprA, gttl, gidx, ngens, mytoc(tg, 'hrs'), sprA);
end

GSEGS = cellfun(@(x) cell2mat(x), GSEGS, 'UniformOutput', 0);

fprintf(['\n\n\n%s\n%s\n%s\n\n\nFINISHED ALL %02d GENOTYPES [%.02f hrs]' ...
    '\n\n\n%s\n%s\n%s\n\n\n'], ...
    sprA, sprA, sprA, ngens, mytoc(te, 'hrs'), sprA, sprA, sprA);

end
