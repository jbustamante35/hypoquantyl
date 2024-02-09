function mcc = computeMatthewsCorellation(ctru, cpre, isz, lbl, fidxs)
%% computeMatthewsCorellation: compute Matthew's Corellation Coefficient
% Computes the phi coefficient between two contours to estimate the closeness 
% of the curves. The first step converts each curve into binary masks the size
% of the 'isz' parameter. 
%
% % -------------------------------------------------------------------------- %
%
% Example of a confusion matrix for a 2-group system
%             | -------------- | -------------- |
%             |    Positive    |    Negative    |
%  | -------- | -------------  | -------------- |
%  |     True | True Positive  | True Negative  |
%  | -------- | -------------  | -------------- |
%  |    False | False Positive | False Negative |
%  | ------------------------------------------ |
%
% % -------------------------------------------------------------------------- %
%
% Equation for Matthew's Corellation Coefficient
%                 (TP x TN) - (FP x FN)
% MCC =  ---------------------------------------------
%        sqrt((TP + FP) (TP + FN) (TN + FP) (TN + FN))
%
% % -------------------------------------------------------------------------- %
%
% Usage:
%   mcc = computeMatthewsCorellation(ctru, cpre, isz, lbl, fidxs)
%
% Input:
%   ctru: ground truth contour
%   cpre: predicted contour
%   idx: size of image to create masks
%   lbl: class labels (optional, 2 expected)
%   fidxs: figure handle indices for visualizing (optional, 2 expected)
%
% Output:
%   mcc: Matthew's Corellation Coefficient value
%

if nargin < 4; lbl = [];    end
if nargin < 5; fidxs = [];  end

%% Convert to binary mask
mtru = double(poly2mask(ctru(:,1), ctru(:,2), isz(1), isz(2)));
mpre = double(poly2mask(cpre(:,1), cpre(:,2), isz(1), isz(2)));

% Convert to confusion matrix
gtru = mtru(:)';
gpre = mpre(:)';
G    = confusionmat(gtru, gpre, 'Order', [0 , 1]);

% Compute MCC
MCC = @(tp,tn,fp,fn) ((tp * tn) - (fp * fn)) / ...
    (sqrt((tp + fp) * (tp + fn) * (tn + fp) * (tn + fn)));

tp = G(1,1);
tn = G(2,2);
fp = G(2,1);
fn = G(1,2);

mcc = MCC(tp, tn, fp, fn);

%% Visualize results
if ~isempty(fidxs)
    % Show contours on masks
    rows = 1;
    cols = 2;

    figclr(fidxs(1));
    subplot(rows, cols, 1);
    myimagesc(mtru);
    hold on;
    plt(ctru, 'g--', 2);
    plt(cpre, 'y-', 2);
    ttl = sprintf('Expected');
    title(ttl, 'FontSize', 10);

    subplot(rows, cols, 2);
    myimagesc(mpre);
    hold on;
    plt(ctru, 'g--', 2);
    plt(cpre, 'y-', 2);
    ttl = sprintf('Predicted');
    title(ttl, 'FontSize', 10);

    % Show confusion matrix
    set(0, 'CurrentFigure', fidxs(2)); clf;
    confusionchart(G, lbl);
end

end