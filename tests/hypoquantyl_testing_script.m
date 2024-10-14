%% HypoQuantyl Testing Script
% Open hypoquantyl_script to adjust input parameters
% The variables set here are saved into the hqinputs.mat file where you set the
% output directory (parameter name is 'odir')
edit hypoquantyl_script.m

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
switch HQ.inputs.tset
    case 'single'
        hq = single_dark_cry1;
    case 'multiple'
        hq = multiple_blue_col0;
end

ex    = hq.preprocessing;
g     = ex.combineGenotypes;
s     = ex.combineSeedlings;
h     = ex.combineHypocotyls;
enm   = ex.ExperimentName;
nsdls = g.NumberOfSeedlings;

fns    = getConversionFunctions(hq.tracking.raw);
frm2hr = fns.frm2hr;
hr2frm = fns.hr2frm;

VVU = hq.tracking.converted.UVEL;
VRU = hq.tracking.converted.UREGR;
VVI = hq.tracking.converted.VI;
VRI = hq.tracking.converted.RI;

% Visualize results
[figs , fnms] = makeBlankFigures(2, 1);

fidx = 1;
ttl  = fixtitle(sprintf('%s (%d seedlings)', enm, nsdls));
rows = [1 , 2 , 1];
vrng = [0 , 0.3 , 4]; % [min , max , values_to_show]
rrng = [0 , 8 , 5];   % [min , max , values_to_show]
fsz  = [5 , 8 , 8];
fcnv = {2 , frm2hr , hr2frm};
fblu = 0;

% Mean Velocity and REGR
showTrackingProcessing(VVU,VRU, ttl, fidx, ...
    rows, fblu, vrng, rrng, fsz, fcnv);

% Individual Velocities and REGRs
MRI = cellfun(@(x) interpolateGrid(x, 'xtrp', 500, 'ytrp', 500, 'fsmth', 3), ...
    VRI, 'UniformOutput', 0);

figclr(2);
montage(MRI, 'Size', [1 , numel(MRI)], 'DisplayRange', []);
colormap jet; colorbar; clim([0 , 10]);

% Additional options to store into tabulated csv format [to-do]