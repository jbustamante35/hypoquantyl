function fnm = plotGroundTruthAndPrediction(img, cpre, zpre, ctru, ztru, mth, idx, trnIdx, fidx, allVectors)
%% plotGroundTruthAndPrediction: overlay ground truth contour on predicted
%
%
% Usage:
%   fnm = plotGroundTruthAndPrediction( ...
%           img, cpre, zpre, ctru, ztru, mth, idx, trnIdx, fidx)
%
% Input:
%   img: image corresponding to prediction
%   cpre: predicted contour
%   zpre: predicted Z-Vector
%   ctru: ground truth contour
%   ztru: ground truth Z-Vector
%   mth: method used for prediction [svec|dvec]
%   idx: index in dataset
%   trnIdx: index of training set
%   fidx: index of figure handle
%   allVectors: show variety of Z-Vector points [none|mids|all]
%
% Output:
%   fnm: name of figure generated
%

if nargin < 10
    allVectors = 'mids'; % Default to showing just midpoints
end

%% Show Z-Vector and Contour
figclr(fidx);
myimagesc(img);
hold on;

% Ground Truth and Predicted Contours
plt(ctru, 'g--', 2);
plt(cpre, 'y-', 2);

%% Show Tangent and Normal vectors
switch allVectors
    case 'none'
        lgn = {'Expected Contour' , 'Predicted Contour'};
        legend(lgn, 'Location', 'northeastoutside');
    case 'mids'
        plt(ztru(:,1:2), 'g.', 3);
        plt(zpre(:,1:2), 'y.', 3);
        lgn = {'Expected Contour' , 'Predicted Contour' , ...
            'Expected Z-Vector', 'Predicted Z-Vector'};
        legend(lgn, 'Location', 'northeastoutside');
    case 'all'
        % Prepare Z-Vectors
        scl           = 1;
        [ttru, ntru]  = prepZVector(ztru, mth, scl);
        [tpre , npre] = prepZVector(zpre, mth, scl);
        
        % Show first coordinates and vectors
        plt(ctru(1,:), 'b.', 10);
        plt(cpre(1,:), 'r.', 10);
        cellfun(@(x) plt(x, 'r-', 1), ttru, 'UniformOutput', 0);
        cellfun(@(x) plt(x, 'b-', 1), ntru, 'UniformOutput', 0);
        cellfun(@(x) plt(x, 'm-', 1), tpre, 'UniformOutput', 0);
        cellfun(@(x) plt(x, 'c-', 1), npre, 'UniformOutput', 0);
    otherwise
        fprintf(2, 'Showing vectors should be [none|mids|all]\n');
end

%% Saving figure
% Check if in training or validation set
if ismember(idx, trnIdx)
    cSet = 'training';
else
    cSet = 'validation';
end

% Title and figure name
fnm = sprintf('%s_GroundTruthVsPredicted_%sMethod_Hypocotyl%03d_%s', ...
    tdate, mth, idx, cSet);
ttl = sprintf('Neural Net Prediction [%s Method]\nHypocotyl %d [%s set]', ...
    mth, idx, cSet);
title(ttl);

end

function [ttng , tnrm] = prepZVector(znrm, mth, SCL)
%% Scale tangent and normal vectors
if nargin < 3
    SCL  = 3;
end

smth = 'svec';
dmth = 'dvec';
mid  = znrm(:,1:2);
tng  = znrm(:,3:4);
nrm  = znrm(:,5:6);

switch mth
    case smth
        tng  = (SCL * (tng - mid)) + mid;
        nrm  = (SCL * (nrm - mid)) + mid;
    case dmth
        tng  = (SCL * (tng)) + mid;
        nrm  = (SCL * (nrm)) + mid;
    otherwise
        fprintf(2, 'Method %s must be [%s|%s]\n', mth, smth, dmth);
        return;
end

ttng = arrayfun(@(x) [mid(x,:) ; tng(x,:)], 1:length(mid), 'UniformOutput', 0);
tnrm = arrayfun(@(x) [mid(x,:) ; nrm(x,:)], 1:length(mid), 'UniformOutput', 0);

end
