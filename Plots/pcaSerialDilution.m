function pcaSerialDilution(pcaX, pcaY, din, dim)
%% pcaSerialDilution: 
% This function only works for my contour coordinates PCA for now 
%
% Usage:
% 
% 
% Input:
%   pcaData: structure containing output from my custom pcaAnalysis
% 
% Output:
%   n/a:
% 
% 

% 
rawD = {pcaX.InputData;  pcaY.InputData};
mnsD = {pcaX.MeanVals;   pcaY.MeanVals};
eigV = {pcaX.EigVectors; pcaY.EigVectors};
scrD = {pcaX.PCAscores;  pcaY.PCAscores};
orgD = {pcaX.SimData;    pcaY.SimData};

% Serial Dilution by 2 StDevs of each score vector



for i = 1 : size(scrD{dim}, 2)
    newD      = scrD{dim};
    itr       = (2* std(scrD{dim}(:,i)));
    ds        = scrD{dim}(:,i) + itr;
    newD(:,i) = ds;    
    simD      = ((newD * eigV{dim}') + mnsD{dim});
    for ii = 1 : size(scrD{dim}, 1)    
        rX = rawD{1}(ii,:);
        rY = rawD{2}(ii,:);
        sX = orgD{1}(ii,:);
        sY = orgD{2}(ii,:);

        subplot(211);
        hold on;
        showContours(din{ii}, rX, rY, sX, sY, simD(ii,:));
        hold off;

        subplot(212);
        hold on;
        showPredictions(rX, sX, simD(ii,:));
        hold off;

        pause(0.3);
    end
end


end 

function showContours(d, rX, rY, sX, sY, dil)
%% showContours: show raw, originial, and diluted contour 
% 
% 

imagesc(d), colormap gray;
hold on;
plot(rX,  rY, 'k', 'LineWidth', 3);
plot(sX,  sY, 'm', 'LineWidth', 3);
plot(dil, sY, 'b', 'LineWidth', 3);
hold off;
end

function showPredictions(r, s, dil)
%% showPredictions: plot original and diluted prediction
hold on;
plot(r, 'k');
plot(s, 'm');
plot(dil, 'b');
hold off;
end


