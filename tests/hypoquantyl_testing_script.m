%% HypoQuantyl Testing Script
% Open hypoquantyl_parameters_script to adjust input parameters
% The variables set here are saved into the hqinputs.mat file where you set the
% output directory (parameter name is 'odir')
edit hypoquantyl_parameters_script.m

%% Run the pipeline!
% This will read the parameters set from the script and output everything into
% the 'HQ' output variable.
th = tic;
try
    HQ = HypoQuantyl;
    eval(sprintf('%s_%s = HQ', ...
        HQ.inputs.tset, HQ.preprocessing.ExperimentName));
catch err
    fprintf('\n%s\nError in %s\n%s\n%s\n', ...
        sprA, err.getReport, mfilename, sprA);
    HQ = [];
end
fprintf('\n%s\nFinished in %.02f hours\n%s\n', sprB, mytoc(th, 'hrs'), sprA);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Analysis %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Basic analysis of results
% Figure 1 (left): Average Velocity
% Figure 1 (right): Average REGR
% Figure 2: Movie overlaying REGR on seedling(s)

switch HQ.inputs.tset
    case 'single'
        hq = single_dark_cry1;
    case 'multiple'
        hq = multiple_blue_col0;
end

odir = hq.inputs.odir;
edate = hq.inputs.edate;
rdir = pprintf(sprintf('%s/outputs/%s/analysis', odir, edate));

% Function Handles
fns     = getConversionFunctions(hq.tracking.raw);
frm2hr  = fns.frm2hr;
hr2frm  = fns.hr2frm;
msample = hq.models.functions.msample;

% Preprocessing
ex    = hq.preprocessing;
g     = ex.combineGenotypes;
s     = ex.combineSeedlings;
h     = ex.combineHypocotyls;
enm   = ex.ExperimentName;
nsdls = g.NumberOfSeedlings;

% Segmentation
segs  = hq.segmentation;
remap = hq.remapping;

% Tracking
track = hq.tracking.converted{1};
VVU   = track.Stats.UVEL;
VRU   = track.Stats.UREGR;

% Prep for Analysis
[figs , fnms] = makeBlankFigures(2, 1);

fidx = 1;
ttl  = fixtitle(sprintf('%s (%d seedlings)', enm, nsdls));
rows = [1 , 2 , 1];
vrng = [0 , 0.3 , 4]; % [min , max , values_to_show]
rrng = [0 , 8 , 5];   % [min , max , values_to_show]
fsz  = [5 , 8 , 8];
fcnv = {2 , frm2hr , hr2frm};
fblu = 0;

[utbl , uimgs , umaps , uenms , usnms] = prep_overlay_movie(track, remap, g);

%% Overlay REGR on seedling images
sav  = 1;

% Mean Velocity and REGR
fnms{1} = showTrackingProcessing(VVU, VRU, ttl, 1, ...
    rows, fblu, vrng, rrng, fsz, fcnv);
saveFiguresJB(1, fnms(1), rdir);

% Overlay REGR on seedlings
regr_overlay_movies({track}, utbl, uimgs, umaps, uenms, usnms, msample, ...
    'rdate', edate, 'fidx', 2, 'sav', sav, 'rdir', rdir);

%% Additional options to store into tabulated csv format [to-do]



