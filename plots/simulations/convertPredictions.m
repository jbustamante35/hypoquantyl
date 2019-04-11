function [segInp_truth, segSim_pred, figs] = convertPredictions(idx, D, predZ, predMethod, px, py, pz, sav)
figs(1) = figure(1);
figs(2) = figure(2);
figs(3) = figure(3);

%% Extract some technical data
% ttlSegs = D(idx).NumberOfSegments;
pcx = length(px.EigValues);
pcy = length(py.EigValues);
pcz = length(pz.EigValues);
%     pcr = size(predZ);

%%
switch predMethod
    case 'plsr'
        cnvMethod = @(x) x;
        
    case 'cnn'
        % Use function to revert CNN output to original Z-Vector
        numCrvs   = size(predZ, 1);
        ttlSegs   = size(predZ, 2) / 6;
        cnvMethod = @(x) zVectorConversion(x, ttlSegs, numCrvs, 'rev');
end

%% Plot Frankencotyls to show backbone predictions [single]
tmpZ = cnvMethod(predZ);

% Show Ground Truth
[segInp_truth, ~] = ...
    plotPredictions(idx, px, py, pz, tmpZ, D, 'truth', sav, 1);

% Show Predicted
[~, segSim_pred] = ...
    plotPredictions(idx, px, py, pz, tmpZ, D, 'predicted', sav, 2);

%% Plot predictions and truths
chkX = segInp_truth;
chkY = segSim_pred;
I    = D(idx).Parent.getImage('gray');
P    = [pcx, pcy, pcz];
plotGroundTruthAndPrediction(chkX, chkY, I, idx, P, sav, 3);

%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %% Show n Frankencotyls to show backbone predictions [looping, training]
%     currDir = pwd;
%     if sav
%         trnDir = sprintf('%s', [pwd '/' 'trained_examples']);
%         eval(sprintf('mkdir %s', trnDir));
%         eval(sprintf('cd %s', trnDir));
%     end
%
%     for n = trnIdx
%
%         tmpX    = predZ(:, 1:(end/2))';
%         tmpY    = predZ(:, (end/2 + 1) : end)';
%         tmpZ = [tmpX(:) , tmpY(:)];
%
%         [segInp_truth, ~] = ...
%             plotFrankencotyls(n, n, px, py, pz, tmpZ, D, ...
%             'truth',     flp, sav, 1);
%
%         [~, segSim_pred] = ...
%             plotFrankencotyls(n, n, px, py, pz, tmpZ, D, ...
%             'predicted', flp, sav, 2);
%
%         % Plot predictions and truths
%         chkX = segInp_truth{1};
%         chkY = segSim_pred{1};
%         I    = C(n).getImage('gray');
%         P    = [pcr, pcz, pcx, pcy];
%         plotGroundTruthAndPrediction(chkX, chkY, I, n, P, sav, 3);
%
%         pause(1);
%     end
%
%     eval(sprintf('cd %s', currDir));
%
%     %% Show n Frankencotyls to show backbone predictions [looping, validation]
%     if sav
%         valDir = sprintf('%s', [pwd '/' 'validation_examples']);
%         eval(sprintf('mkdir %s', valDir));
%         eval(sprintf('cd %s', valDir));
%     end
%
%     for n = valIdx
%
%         tmpX    = predZ(:, 1:(end/2))';
%         tmpY    = predZ(:, (end/2 + 1) : end)';
%         tmpZ = [tmpX(:) , tmpY(:)];
%
%         [segInp_truth, ~] = ...
%             plotFrankencotyls(n, n, px, py, pz, tmpZ, D, ...
%             'truth',     flp, sav, 1);
%
%         [~, segSim_pred] = ...
%             plotFrankencotyls(n, n, px, py, pz, tmpZ, D, ...
%             'predicted', flp, sav, 2);
%
%         % Plot predictions and truths
%         chkX = segInp_truth{1};
%         chkY = segSim_pred{1};
%         I    = C(n).getImage('gray');
%         P    = [pcr, pcz, pcx, pcy];
%         plotGroundTruthAndPrediction(chkX, chkY, I, n, P, sav, 3);
%
%         pause(1);
%     end
%
%     eval(sprintf('cd %s', currDir));

end