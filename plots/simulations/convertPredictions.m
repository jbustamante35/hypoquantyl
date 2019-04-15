function [segInp_truth, segSim_pred, figs] = convertPredictions(idx, D, predZ, predMethod, px, py, pz, sav)
%% convertPredictions:
% This
%
% Usage:
%
%
% Input:
%
%
% Output:
%
%

%% Set figure indices [recommended to have 3 figures already opened!]
figs(1) = figure(1);
figs(2) = figure(2);
figs(3) = figure(3);

%% Extract some technical data
pcx = length(px.EigValues);
pcy = length(py.EigValues);
pcz = length(pz.EigValues);
%     pcr = size(predZ); % For PLSR output

%%
switch predMethod
    case 'plsr'
        % TODO convert PLSR output to original Z-Vector
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

end