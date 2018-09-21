function [figs, ttls] = showMyPCA(pca_custom, analysis_name)
%% showMyPCA: show output from myPCA data
% This function outputs 2 figures to visualize the output from myPCA function.
% Figure 1:
%   (a) full rasterized data
%   (b) mean-centered square matrix
% Figure 2:
%   (a) diagonalized and sorted eigenvalues
%   (b) sorted eigenvectors
%
% Usage:
%   [figs, ttls] = showMyPCA(pca_custom, analysis_name)
%
% Input:
%   pca_custom: outputted structure from myPCA
%   analysis_name: name for the saved figure file
%
% Output:
%   figs: figure handles of figures
%   ttls: figure title names
%

%% Set up figures
figs    = 1:2;
figs(1) = figure;
figs(2) = figure;
ttls{1} = sprintf('%s_custom_inputData', analysis_name);
ttls{2} = sprintf('%s_custom_outputData', analysis_name);
set(figs, 'Color', 'w');

%% Raw input data
% Raw rasterized data
set(0, 'CurrentFigure', figs(1));
subplot(221);
imagesc(pca_custom.InputData);
title(sprintf('Raw Rasterized Data\n%s', analysis_name));
xlabel('Dimension');
ylabel('Index');
colormap cool;

% Mean-centered data
subplot(222);
imagesc(pca_custom.MeanCentered);
title(sprintf('Mean Centered Data\n%s', analysis_name));
xlabel('Dimension');
ylabel('Index');
colormap cool;

% Variance-covariance matrix
subplot(212);
imagesc(pca_custom.VarCovar);
title(sprintf('Variance-Covariance Matrix | %s', analysis_name));

%% Output data [eigenvalues, eigenvectors]
% Eigenvalues
set(0, 'CurrentFigure', figs(2));
subplot(211);
imagesc(pca_custom.EigValues);
colormap cool;
title(sprintf('Eigenvalues in descending order | %s', analysis_name));

% Eigenvectors
subplot(212);
imagesc(pca_custom.EigVectors);
colormap cool;
title(sprintf('Eigenvectors | %s', analysis_name));

end