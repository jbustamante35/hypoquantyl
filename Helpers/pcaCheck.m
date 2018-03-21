function pcaChk = pcaCheck(ct, dX, dY, n, p, v1, v2)
%% pcaCheck: run and view various data from principal components analysis
%
%
% Usage:
%   pcaChk = pcaCheck(ct, dX, dY, n, p, v1, v2)
%
% Input:
%   ct: contours containing set of images to analyze
%   dX: rasterized x-coordinate data
%   dY: rasterized y-coordinate data
%   n: number of PCs to reduce to
%   p: pause time for viewing figures
%   v1: visualize results from pca analysis
%   v2: visualize results from this function
%
% Output:
%   pcaX: pca results for x-coordinates
%   pcaY: pca results for y-coordinates
%
%

%% Run PCA with n principal components
[pX, ~] = pcaAnalysis(dX, n, [1 size(dX,2)], 0, 'xCoords', v1);
[pY, ~] = pcaAnalysis(dY, n, [1 size(dY,2)], 0, 'yCoords', v1);

%% Check accuracy of analysis
rawX = pX.InputData;
simX = pX.SimData;
rawY = pY.InputData;
simY = pY.SimData;

% Mean and StDev
avgX = mean([rawX ; simX]);
avgY = mean([rawY ; simY]);
stdX = std([rawX ; simX]);
stdY = std([rawY ; simY]);

% Mean Square Errors
MSE = @(exp,obs) mean((exp - obs) .^ 2);
mseX = MSE(rawX, simX);
mseY = MSE(rawY, simY);

pcaChk = struct('PCA',  [pX pY], ...
    'MEAN', [avgX ; avgY], ...
    'STD',  [stdX ; stdY], ...
    'MSE',  [mseX ; mseY]);


%% Compare input vs simulated contour
if v2
    
    %% Plot mean, std, and mse
    figure;
    t = ['x' ; 'y'];
    for m = 1 : 2
        subplot(2, 2, m);
        plot(pcaChk.MEAN(m,:), 'k');
        title(sprintf('Mean and StDev: \n %s-coordinates (%d PCs)', t(m), n));
        hold on;
        stdevUp = pcaChk.MEAN(m,:) + pcaChk.STD(m,:);
        stdevDn = pcaChk.MEAN(m,:) - pcaChk.STD(m,:);
        plot(stdevUp, 'c-');
        plot(stdevDn, 'c-');
    end
    
    yl = [0 30];
    subplot(2, 2, 3);
    plot(mseX, 'k');
    title(sprintf('MSE: \n x-coordinates (%d PCs)', n));
    ylim(yl);
    
    subplot(2, 2, 4);
    plot(mseY, 'k');
    title(sprintf('MSE: \n y-coordinates (%d PCs)', n));
    ylim(yl);
    
    
    %% Iterate through random set of input vs simulated data
    % Random set is configured to last 30 sec, depending on time p
    frms = 30 / p;
    rIdx = randperm(numel(ct), frms);
    
    figure;
    for i = rIdx
        % View raw coordinates and simulated coordinates
        subplot(311);
        title('x coordinate');
        plotPoints(pX.InputData(i,:), pX.SimData(i,:));
        hold off;
        
        subplot(312);
        title('y coordinate');
        plotPoints(pY.InputData(i,:), pY.SimData(i,:));
        hold off;
        
        % View input and simulated contours overlaid on image
        subplot(313);
        title('Contour overlay');
        viewOverlay(ct(i).getGrayImageAtFrame(1), ...
            pX.InputData(i,:), ...
            pY.InputData(i, :), ...
            pX.SimData(i,:), ...
            pY.SimData(i,:));
        hold off;
        
        pause(p);
    end
end

end

function plotPoints(rawD, simD)
plot(rawD, 'k', 'LineWidth', 3);
hold on;
plot(simD, 'm', 'LineWidth', 3);
end

function viewOverlay(im, rawX, rawY, simX, simY)
imagesc(im), colormap gray;
hold on;
plot(rawX, rawY, 'k');
plot(simX, simY, 'm');
end