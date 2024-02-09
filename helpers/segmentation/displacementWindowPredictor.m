function [cpre , zpre , citrs , fnms] = displacementWindowPredictor(img, varargin)
%% displacementWindowPredictor:
%
%
% Usage:
%   [cpre , zpre , citrs , fnms] = displacementWindowPredictor(img, ncycs, ...
%       model_options, misc_options, vis_options)
%
% Input:
%   img:
%   ncycs: number of cycles to put through neural nets (default 1)
%
%   model_options:
%       Nz:
%       pz:
%       Nd:
%       pdp:
%       pdx:
%       pdy:
%       pdw:
%       fmth:
%       z:
%       model_manifest:
%
%   misc_options: parameters for parallelization, saving, and visualization
%       par:
%       sav:
%       vis:
%
%   vis_options: visualization parameters if [vis = 1]
%       fidx:
%       cidx:
%       ncrvs:
%       splts:
%       ctru:
%       ztru:
%       ptru:
%       zoomLvl:
%       toRemove:
%
% Output:
%   cpre:
%   zpre:
%   citrs: contours from each recursive iteration [after smoothing]
%   fnms:
%

%% Parse inputs, Load models, Separate sets
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

% Load any non-inputted models
args = loadModels(args, model_manifest);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

if ~isempty(splts)
    trnIdx  = splts.trnIdx;
    valIdx  = splts.valIdx;
    tstIidx = splts.tstIdx;
    tset    = determineSet(cidx, trnIdx, valIdx, tstIidx);
else
    tset = [];
end

% Misc
[scls , doms , dszs] = setupParams('myShps', myShps, 'zoomLvl', zoomLvl);
nitrs                = numel(fieldnames(Nd));
nsplt                = round(size(pdw.InputData,2) / 2);
nsegs                = size(pdx.InputData,2);
citrs                = cell(nitrs,1);

[~ , sprA , sprB] = jprintf('', 0, 0);
tAll              = tic;
if vis > 1
    fprintf('%s\nDisplacement Window Predictor | %d Iterations | %d Patches | %dx%dx%d Domains\n%s\n', ...
        sprA, nitrs, nsegs, numel(scls), numel(doms), numel(dszs), sprB);
end

% ---------------------------------------------------------------------------- %
%% Get Z-Vector from image
if vis > 1; t = tic; end

% zseed = false;
if isempty(z)
    if vis > 1; n = fprintf('Predicting Z-Vector from image'); end
    %% TODO: Displace by B-Vector
    [zpre.initial , zpre.score_initial] = predictZvectorFromImage(img, Nz, pz);
    ptru = sampleCorePatches(img, zpre.initial, scls, doms, dszs, par);
else
    if vis > 1; n = fprintf('Sampling given Z-Vector'); end
    zpre.initial       = z;
    zpre.score_initial = ...
        zVectorProjection(z, nsegs, pz.EigVecs, pz.MeanVals, 3);

    % Sample if no ptru
    if ~sum(ptru)
        ptru = sampleCorePatches(img, zpre.initial, scls, doms, dszs, par);
    end
end

switch vis
    case 2
        nn   = deblank(repmat('%.03f ', 1, pz.NumberOfPCs));
        n(2) = fprintf(['[' , nn , ']'], zpre.score_initial);
        jprintf('', toc(t), 1, 80 - sum(n));
    case 3
        jprintf('', toc(t), 1, 80 - n);
        fprintf('%s\n', sprB);
end

% ---------------------------------------------------------------------------- %
%% Predict contour from each iteration
switch vis
    case 2
        % Compact
        titrs = tic;
        fprintf('Predicting through %d iterations |', nitrs);
    case 3
        % Verbose
end

for itr = 1 : nitrs
    % ----------------------- Sample Patches --------------------------------- %
    %% Sample Patches
    if vis == 3
        fprintf('Iteration %d of %d\n', itr, nitrs);
        titr = tic;
        t    = tic;
        n    = fprintf('Sampling patches from Z-Vector');
    end

    if itr == 1
        % Use initial Z-Vector and patches or use seeded Z-Vector again
        z    = zpre.initial;
        ptch = ptru;
    else
        % Create frame bundle and patches from prediction
        cpre = prepareTargets(cpre, nsplt);
        z    = curve2framebundle(cpre(:,1:2));
        ptch = sampleCorePatches(img, z, scls, doms, dszs, par);
    end

    % Project patches into PCA space
    pprj = pcaProject(ptch, pdp.EigVecs{itr}, pdp.MeanVals{itr}, 'sim2scr');

    if vis == 3; jprintf('', toc(t), 1, 80 - n); end

    % ------------------------- Predict D-Vectors -------------------------------- %
    %% Predict D-Vectors and back-project into image space
    if vis == 3
        t = tic;
        n = fprintf('Predicting D-Vector and Back-Projecting');
    end

    nstr = sprintf('N%d', itr);
    dtmp = Nd.(nstr)(pprj')';

    if size(dtmp,2) == 2
        dpre = [dtmp , ones(size(dtmp,1) , 1)];
    else
        dpre = dtmp;
    end

    %     cpre = computeTargets(dpre, z, 0, par);
    cpre = computeTargets(dpre, z, toShape, par);

    if vis == 3; jprintf('', toc(t), 1, 80 - n); end

    % -------------------------- Smooth Contour ------------------------------ %
    %% PCA smooth predictions
    if vis == 3
        t = tic;
        n = fprintf('Smoothing contour');
    end

    switch fmth
        case 'whole'
            cpre = wholeSmoothing(cpre, [pdx , pdy], npxy);
        case 'local'
            cpre = wholeSmoothing(cpre, [pdx , pdy], npxy);
            cpre = localSmoothing(cpre, nsplt, pdw, npw);
        otherwise
    end

    %% Straighten top and bottom sections [not great yet]
    if toFix
        % Straighten top and bottom segments
        tmp        = straightenSegment(cpre(:,1:2), seg_lengths, 1);
        tmp(:,3,:) = 1;
        cpre       = tmp;
    end

    % Store each iteration of contours
    citrs{itr} = cpre;

    if vis == 3; jprintf('', toc(t), 1, 80 - n); end

    % --------------------------- Display Predictions ------------------------ %
    %% Show and Save iterative predictions
    if vis == 3
        t = tic;
        n = fprintf('Save Image [%d] | Save Data [%d]', vis, sav);
    end

    if vis == 1
        figclr(fidx);
        myimagesc(img);
        hold on;
        plt(ctru, 'g-', 2);
        plt(cpre(:,1:2), 'y--', 2);
        ttl = sprintf('Curve %d of %d [%s set]\nIteration %d of %d', ...
            cidx, ncrvs, tset, itr, nitrs);
        title(ttl, 'FontSize', 10);
        drawnow;

        % Save each iteration
        if sav == 2
            sdir = sprintf(['displacementvector_%smethod_predictions/%s/' ...
                'curve%03dof%03d'], fmth, tset, cidx, ncrvs);
            fnms = sprintf('%s_iteration%02dof%02d', tdate, itr, nitrs);
            saveFiguresJB(fidx, {fnms}, sdir);
        end
    end

    switch vis
        case 2
            m = 5;
            if mod(itr,m); fprintf('.'); else; fprintf('%d|', itr); end
        case 3
            jprintf('', toc(t), 1, 80 - n);

            % End of Iteration
            nitr = fprintf('Finished Iteration %d of %d', itr, nitrs);
            jprintf('', toc(titr), 1, 80 - nitr);
            fprintf('%s\n\n', sprA);
    end
end

%% End of iterations
if vis == 2
    fprintf('\n');
    n = fprintf('Finished %d Iterations', nitrs);
    jprintf('', toc(titrs), 1, 80 - n);
end

% ------------------------------ Final Outputs ------------------------------- %
%% Return final output
if vis > 1
    t = tic;
    n = fprintf('Storing final outputs [alt_return = %s]', alt_return);
end

cpre = cpre(:,1:2);

% Close contour if open
if ~all(cpre(1,:) == cpre(end,:)); cpre = [cpre ; cpre(1,:)]; end

% Make Z-Vector and Z-Vector PC score from final contour
zpre.final       = contour2corestructure(cpre, nsplt);
zpre.score_final = pcaProject(zVectorConversion( ...
    zpre.final(:,1:4), nsegs, 1, 'prep'), pz.EigVecs, pz.MeanVals, 'sim2scr');
zpre.vector      = z;

% Return requested variable [either contour or z-vector]
if nargout == 1; cpre = eval(alt_return);        end
if vis > 1     ; jprintf('', toc(t), 1, 80 - n); end

% ------------------------- Display Final Iterations ------------------------- %
%% Show final iteration
if vis >= 1
    t = tic;
    n = fprintf('Final Save Image [%d] | Final Save Data [%d]', vis, sav);
end

if vis == 1
    figclr(fidx);
    myimagesc(img);
    hold on;
    plt(ctru, 'g-', 2);
    plt(cpre, 'y--', 2);
    ttl = sprintf('Curve %d of %d [%s set]', cidx, ncrvs, tset);
    title(ttl, 'FontSize', 10);

    drawnow;

    fnms = sprintf('%s_curve%03dof%03d_finalprediction', ...
        tdate, cidx, ncrvs);

    if sav
        sdir = sprintf('displacementvector_%smethod_predictions/%s/', ...
            fmth, tset);
        saveFiguresJB(fidx, {fnms}, sdir);
    end
end

if vis >= 1
    jprintf('', toc(t), 1, 80 - n);
    fprintf('%s\nFinished! [%.02f sec]\n%s\n', sprB, toc(tAll), sprA);
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
% Required: ncycs
% Model: Nz, pz, Nd, pdp, pdx, pdy, pdw, fmth, z, model_manifest
% Misc: par, sav, vis
% Vis: fidx, cidx, ncrvs, splts, ctru, ztru, ptru, zoomLvl, toRemove

% Required
p = inputParser;
p.addOptional('ncycs', 1);

% Model Options
p.addOptional('Nz', 'znnout');
p.addOptional('pz', 'pz');
p.addOptional('Nd', 'dnnout');
p.addOptional('pdp', 'pcadp');
p.addOptional('pdx', 'pcadx');
p.addOptional('pdy', 'pcady');
p.addOptional('pdw', 'pcadw');
p.addOptional('fmth', 'local');
p.addOptional('z', []);
p.addOptional('model_manifest', {'dnnout' , 'pcadp' , ...
    'pcadx' , 'pcady' , 'pcadw' , 'znnout' , 'pz'});

% Miscellaneous Options
p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);
p.addOptional('toFix', 0);
p.addOptional('toShape', 0);
p.addOptional('npxy', []);
p.addOptional('npw', []);
p.addOptional('par', 0);
p.addOptional('sav', 0);
p.addOptional('vis', 0);
p.addOptional('vrb', 0);
p.addOptional('alt_return', 'cpre');

% Visualization Options
p.addParameter('fidx', 1);
p.addParameter('cidx', 1);
p.addParameter('ncrvs', 1);
p.addParameter('splts', []);
p.addParameter('ctru', [0 , 0]);
p.addParameter('ztru', [0 , 0]);
p.addParameter('ptru', [0 , 0]);
p.addParameter('zoomLvl', [0.5 , 1.5]);
p.addParameter('myShps', [2 , 3 , 4]);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

function args = loadModels(args, model_manifest)
%% loadModels:
% if nargin < 2
%     model_manifest = {'dnnout' , 'pcadp' , 'pcadx' , 'pcady' , 'pcadw' , 'znnout' , 'pz'};
% end

%%
mdir = '/home/jbustamante/Dropbox/EdgarSpalding/labdata/development/HypoQuantyl/datasets/matfiles';
end
