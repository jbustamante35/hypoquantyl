function HQ = HypoQuantyl
%%
% Read through and load parameters script
ti = tic;
fprintf('\n%s\nReading through hypoquantyl_script...\n%s\n', sprA, sprB);
run('hypoquantyl_script.m');

% Finish path to images
cinn = dir2(pprintf(sprintf('%s%s%s', path_to_data, filesep, tset)));
cset = cinn.name;
ginn = dir2(pprintf(sprintf('%s%s%s', cinn.folder, filesep, cset)));
gset = ginn.name;

fprintf('Date of Analysis: %s\n', edate);
fprintf('Input Path: %s\n', path_to_data);
fprintf('Output Path: %s\n', odir);
fprintf('Selection: type (%s) | condition (%s) | genotype (%s)\n', ...
    tset, cset, gset);
fprintf(['Misc: verbosity (%d) | save (%d) | ' ...
    'parallel (%d) [%02d cores]\n'], vrb, sav, par, ncores);
fprintf('%s\nDONE! Loaded %d parameters [%.03f sec]\n%s\n', ...
    sprB, numel(who), mytoc(ti), sprA);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Prepare Models %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load learning models
hqinn = pprintf(sprintf('%s%s%s', path_to_data, filesep, hqnm));
hqmod = load(hqinn);
hqmod = hqmod.HQ;

% -------------------------- Load into environment --------------------------- %
for fld = fieldnames(hqmod)'
    for fn = fieldnames(hqmod.(cell2mat(fld)))'
        feval(@() assignin('caller', cell2mat(fn), ...
            hqmod.(cell2mat(fld)).(cell2mat(fn))));
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% Image Pre-Processing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Detect seedlings and prepare hypocotyl images
path_to_conditions = cinn.folder;
path_to_genotypes  = ginn.folder;

opts = {'HYPOCOTYLLENGTH' , hlng};
ex   = imagePreprocessor(path_to_genotypes, gset, mth, 0, toExclude, ...
    vrb, fidxs, vmth, opts, 0);

gens  = ex.combineGenotypes;
ngens = numel(gens);
enm   = ex.ExperimentName;

% ------------------------ Save Pre-Processing ------------------------------- %
if sav
    xdir = pprintf(sprintf('%s/output/%s/preprocessing', odir, edate));
    if ~isfolder(xdir); mkdir(xdir); end
    ex.SaveExperiment(xdir);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Segmentation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Segmentation on upper and lower hypocotyl regions
GSEGS = hypocotylSegmenter(gens, edate, vrb, path2subs, keepBoth, ...
    Nb, Nz, pz, Nd, pdp, pdx, pdy, pdw, pm, ...
    bpredict, zpredict, cpredict, sopt, mline, mscore, msample, ...
    myShps, zoomLvl, mpts, mmth, mparams, stolf, stolx, toFix, bwid, ...
    nopts, dsz, smth, npts, slens, mbuf, abuf, scl, href, par, flp, isdl, ihyp);

% --------------------- Segmentation Post-Processing ------------------------- %
% Fix flipping
FLPS  = cellfun(@(y) arrayfun(@(x) x.info.toFlip, y), GSEGS, 'UniformOutput', 0);
FTOT  = cellfun(@(x) sum(x), FLPS, 'UniformOutput', 0);
TTOT  = cellfun(@(x) size(x,1), FLPS, 'UniformOutput', 0);
TOFLP = cellfun(@(f,t) (f / t) > 0.5, FTOT, TTOT, 'UniformOutput', 0);
FBAD  = cellfun(@(f,t) f ~= t, FLPS, TOFLP, 'UniformOutput', 0);
BTOT  = cellfun(@(x) sum(x), FBAD, 'UniformOutput', 0);
BSEG  = cellfun(@(s,f) s(f), GSEGS, FBAD, 'UniformOutput', 0);
BSUM  = cellfun(@sum, BTOT);

% Helpful function handles
getImg  = @(g,s,f,v) gens(g).getSeedling(s).MyHypocotyl.getImage( ...
    f, 'gray', v, [], mbuf, abuf, scl);
getInfo = @(s) [s.info.GenotypeIndex , s.info.SeedlingIndex , ...
    s.info.Frame , s.info.toFlip];

% Fix Flipping
ta = tic;
fprintf('\n\n%s\n', sprA);
for gidx = 1 : numel(BSEG)
    tg = tic;
    fprintf('Genotype %02d of %02d\n%s\n', gidx, ngens, sprB);
    bsegs = BSEG{gidx};
    nbad  = BSUM(gidx);

    for bi = 1 : nbad
        tb = tic;
        fprintf('| g%02d of %02d | b%02d of %02d | ', gidx, ngens, bi, nbad);
        bseg  = bsegs(bi);
        binfo = getInfo(bseg);
        bimg  = getImg(binfo(1), binfo(2), binfo(3), 'upper');
        isz   = size(bimg,1);

        oimg = normalizeImageWithHistogram(bimg, href);
        fseg = flipSegmentation(bseg, slens, isz(1), oimg, escore, 'flp');

        % Switch init and flp
        fseg.info.toFlip      = ~fseg.info.toFlip;
        fseg.uhyp.info.toFlip = ~fseg.uhyp.info.toFlip;
        fseg.uhyp.tmp         = fseg.uhyp.init;
        fseg.uhyp.init        = fseg.uhyp.flp;
        fseg.uhyp.flp         = fseg.uhyp.tmp;
        fseg.uhyp             = rmfield(fseg.uhyp, 'tmp');

        BSEG{gidx}(bi) = fseg;

        fprintf('[%.02f sec] |\n', toc(tb));
    end

    fprintf('%s\nGenotype %02d of %02d [%.02f sec]\n%s\n', ...
        sprB, gidx, ngens, toc(tg), sprB);
end

fprintf('DONE! [%.02f min]\n%s\n\n', mytoc(ta, 'min'), sprA);

% Replace init with flipped of flp
for gidx = 1 : numel(BSEG); GSEGS{gidx}(FBAD{gidx}) = BSEG{gidx}; end

% -------------------------- Save Segmentation ------------------------------- %
if sav
    sdir = pprintf(sprintf('%s/output/%s/segmentation', odir, edate));
    if ~isfolder(sdir); mkdir(sdir); end
    snm  = pprintf(sprintf('%s/%s_segmentation_%s_%dgenotypes', ...
        sdir, edate, enm, ngens));
    save(snm, '-v7.3', 'GSEGS');
end

% ---------------------------------------------------------------------------- %
%% Combine upper and lower regions, rescale coordinates
[gmids , gcntr] = deal(cell(ngens, 1));
nstc = 'init';
for gi = 1 : numel(GSEGS)
    gen  = gens(gi);
    gttl = gen.GenotypeName;
    hseg = GSEGS{gi};

    [frms , nsdls] = size(hseg);
    for si = 1 : nsdls
        s = gen.getSeedling(si);
        h = s.MyHypocotyl;
        for frm = 1 : frms
            th = tic;
            fprintf(['| %s | Frame %02d of %02d | ' ...
                'Seedling %d of %d | Genotype %02d of %02d | '], ...
                gttl, frm, frms, si, nsdls, gi, ngens);

            uhyp = hseg(frm,si).uhyp.(nstc);
            lhyp = hseg(frm,si).lhyp;
            uc   = uhyp.c;
            um   = uhyp.m;
            lc   = lhyp.c;
            lm   = lhyp.m;
            gbox = s.getCropBox(frm, mbuf);
            ubox = h.getCropBox(frm, 'upper', mbuf, abuf, scl);
            lbox = h.getCropBox(frm, 'lower', mbuf, abuf, scl);
            simg = s.getImage(frm, 'gray', mbuf);
            uimg = h.getImage(frm, 'gray', 'upper', [], mbuf, abuf, scl);
            limg = h.getImage(frm, 'gray', 'lower', [], mbuf, abuf, scl);

            [gmids{gi}{frm,si} , gcntr{gi}{frm,si}] = ...
                getDomainInputs_remote(simg, uimg, limg, gbox, ubox, lbox, ...
                0, 'hcupp', uc, 'hmupp', um, 'hclow', lc, 'hmlow', lm, ...
                'slens', slens, 'npts', npts);

            fprintf('[%.03f sec]\n', toc(th));
        end
    end
end

% ---------------------------------------------------------------------------- %
% Store Re-Mapping
GMAPS = cell(size(GSEGS));
for gi = 1 : numel(GSEGS)
    hseg = GSEGS{gi};

    [frms , nsdls] = size(hseg);
    gmap           = cell(frms,nsdls);
    for si = 1 : nsdls
        for frm = 1 : frms
            gmap{frm,si}.info = hseg(frm,si).info;
            gmap{frm,si}.c    = gcntr{gi}{frm,si};
            gmap{frm,si}.m    = gmids{gi}{frm,si};
            gmap{frm,si}.g    = hseg(frm,si).uhyp.init.g;
        end
    end
    GMAPS{gi} = cell2mat(gmap);
end

% ---------------------------- Save Remapping -------------------------------- %
if sav
    rdir = pprintf(sprintf('%s/output/%s/remapping', odir, edate));
    if ~isfolder(rdir); mkdir(rdir); end
    rnm  = pprintf(sprintf('%s/%s_remapping_%s_%dgenotypes', ...
        rdir, edate, enm, ngens));
    save(rnm, '-v7.3', 'GMAPS');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Tracking %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Prep images and midlines
gidxs = arrayfun(@(x) x.info.GenotypeIndex, GMAPS{1}(1,:));
sidxs = arrayfun(@(x) x.info.SeedlingIndex, GMAPS{1}(1,:));
enms  = arrayfun(@(x) ex.ExperimentName, sidxs, 'UniformOutput', 0);
gnms  = arrayfun(@(x) x.info.GenotypeName, GMAPS{1}(1,:), 'UniformOutput', 0);

% Extract File Paths, Images, and Midlines
GFINS = arrayfun(@(x) x.getProperty('ImageStore').Files, ...
    gens, 'UniformOutput', 0);
GIMGS = cellfun(@(y) cellfun(@(x) double(imread(x)), y, 'UniformOutput', 0), ...
    GFINS, 'UniformOutput', 0);
GMIDS = cellfun(@(y) arrayfun(@(x) x.m, ...
    y, 'UniformOutput', 0), GMAPS, 'UniformOutput', 0);

GIMGS = repmat(GIMGS, 1, nsdls);
GMIDS = arrayfun(@(x) GMIDS{1}(:,x), 1 : nsdls, 'UniformOutput', 0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Eulerian Tracking Locally
T = trackingToCondor(GIMGS, GMIDS, enms, gnms, gidxs, sidxs, ...
    npcts, 'dbug', dbug, 'fidx', fidx, 'ifrm', ifrm, 'ffrm', ffrm, ...
    'skp', skp, 'dsk', dsk, 'dres', dres, 'symin', symin, 'symax', symax, ...
    'itrs', itrs, 'tolf', ttolf, 'tolx', ttolx, 'dlt', dlt, 'eul', eul, ...
    'nlc', nlc, 'lb', lb, 'ub', ub, 'tol', tol, 'smth', tsmth, 'ltrp', ltrp, ...
    'othr', othr, 'vrng', vrng, 'fmax', fmax, 'ki', ki, 'ni', ni, ...
    'kdate', edate, 'tdir', [], 'sav', 0, 'par', par);

% Extract Tracking Results
Tb = cellfun(@(x) x.T, T, 'UniformOutput', 0);

% ------------------------ Tracking Post-Processing -------------------------- %
% Concatenate and average tracking results
ty   = combineTracking(cat(1,Tb{:}), iex);
lthr = min(cellfun(@(x) min(x(end,:)), ty.Output.Arclength.src));

[ty , tu , terr , ti] = averageTracking(ty, [], [], ltrp, lthr, tsmth);

TY  = arrayfun(@(x) x, ty, 'UniformOutput', 0);
TRU = tu(1);
TVU = tu(2);
TRE = terr(1);
TVE = terr(2);
TRI = ti(1);
TVI = ti(2);

% Convert to proper units
fns = getConversionFunctions(TY, ...
    'pix_per_mm', pix_per_mm, 'frm_per_hr', frm_per_hr, 'fblu', fblu);

frm2hr = fns.frm2hr;
hr2frm = fns.hr2frm;
rf2h   = fns.rf2h;
vf2h   = fns.vf2h;

% Convert REGR and Velocities from pix-frm to mm-hr
VVU = cellfun(@(x) vf2h(x), TVU, 'UniformOutput', 0);
VRU = cellfun(@(x) rf2h(x), TRU, 'UniformOutput', 0);
VVE = cellfun(@(x) vf2h(x), TVE, 'UniformOutput', 0);
VRE = cellfun(@(x) rf2h(x), TRE, 'UniformOutput', 0);

VVI = cellfun(@(y) cellfun(@(x) vf2h(x), ...
    y, 'UniformOutput', 0), TVI, 'UniformOutput', 0);
VRI = cellfun(@(y) cellfun(@(x) rf2h(x), ...
    y, 'UniformOutput', 0), TRI, 'UniformOutput', 0);

% ---------------------------- Save Tracking --------------------------------- %
if sav
    TRACK.raw = TY;
    TRACK.converted = struct('UVEL', VVU, 'UREGR', VRU, ...
        'EVEL', VVE, 'EREGR', VRE, 'VI', VVI, 'RI', VRI);
    vdir = pprintf(sprintf('%s/output/%s/tracking', odir, edate));
    if ~isfolder(vdir); mkdir(vdir); end
    vnm  = pprintf(sprintf('%s/%s_tracking_%s_%dgenotypes', ...
        vdir, edate, enm, ngens));
    save(vnm, '-v7.3', 'TRACK');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Analysis %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Store results into .csv files


% ---------------------------- Save Analysis --------------------------------- %
% if sav
%     adir = pprintf(sprintf('%s/output/%s/analysis', odir, edate));
%     if ~isfolder(adir); mkdir(adir); end
%     saveFiguresJB(figs, fnms);
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Outputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Store results into output
hqinn = load(pprintf(sprintf('%s/hqinputs', odir)));
HQ    = struct('inputs', hqinn, 'models', hqmod, ...
    'preprocessing', ex, 'segmentation', GSEGS, 'remapping', GMAPS, ...
    'tracking', TRACK);

end
