function figs = plotCorrelationAll(X, Y, sv)
%% plotCorrelationAll: generates all correlation plots of PCA scores for x-/y-coordinates
% This function plots [n x m] plots of each PC of all Routes for x-/y-coordinate data against each
% other in M separate figure.
%
% Usage:
%   figs = plotCorrelationAll(X, Y, sv)
%
% Input:
%   X: pca data of x-coordinates using optimal number of PCs
%   Y: pca data of y-coordinates using optimal number of PCs
%   sv: boolean to save resulting array of figures 
%
% Output:
%   figs: resulting object array of figure handles for each plot generated
%

%% Set-up function handles and data structure
pcaX = arrayfun(@(x) x.customPCA, X, 'UniformOutput', 0);
pcaX = cat(1, pcaX{:});
pcaX = struct('Nm', 'X', 'Cm', pcaX);

pcaY = arrayfun(@(x) x.customPCA, Y, 'UniformOutput', 0);
pcaY = cat(1, pcaY{:});
pcaY = struct('Nm', 'Y', 'Cm', pcaY);
D    = [pcaX pcaY];

plt = @(a,b,c,d) plotCorrelationMulti(a,b,c,d,pcaX.Cm,pcaY.Cm,sv,1);
%% Iterate through all PCs of each Route for x-/y-coordinate PCA data
% iterate through all coordinate data
for i = 1 : size(D,2)
    d = D(i);
    % iterate through all Routes
    for j = 1 : numel(d.Cm)
        r = d.Cm(j);
        % iterate through each PC
        for k = 1 : size(r.PCAscores,2)
            plt(D(i).Nm, d.Cm, j, k);
            drawnow;
        end
    end
end

end