function [figs, ttls] = showBuiltinPCA(pca_builtin, analysis_name, reshape_size)
%% showMyPCA: show output from myPCA data
% This function outputs 2 figures to visualize the output from myPCA function.
% Figure 1:
%   (a-f) Visualize analysis output
% Figure 2:
%   Principal Components
% Figure 3:
%   (a-n) Reshape all n Principal Components to match input data
%
% Usage:
%   [figs, ttls] = showBuiltinPCA(pca_builtin, analysis_name, reshape_size)
%
% Input:
%   pca_builtin: outputted structure from builtinPCA
%   analysis_name: name for the saved figure file
%
% Output:
%   figs: figure handles of figures
%   ttls: figure title names
%

%% Set up figures
figs    = 1:3;
figs(1) = figure;
figs(2) = figure;
figs(3) = figure;

ttls{1} = sprintf('%s_builtin_outputData', analysis_name);
ttls{2} = sprintf('%s_builtin_scores', analysis_name);
ttls{3} = sprintf('%s_builtin_reshapePCs', analysis_name);
set(figs, 'Color', 'w');

%% Visualize analysis output
set(0, 'CurrentFigure', figs(1));
colormap cool;

subplot(231);
imagesc(pca_builtin.COEFF);
title(sprintf('Coefficients \n Variables to each X'));

subplot(232);
imagesc(pca_builtin.EXPLAINED);
title(sprintf('Variance Explained \n %s variance by PC', '%'));

subplot(233);
imagesc(pca_builtin.LATENT);
title(sprintf('Latent \n PC variance)'));

subplot(234);
imagesc(pca_builtin.MU);
title(sprintf('Mu \n Mean of each x'));

subplot(235);
imagesc(pca_builtin.SCORE);
title(sprintf('Scores \n PC for each x'));

subplot(236);
imagesc(pca_builtin.TSQUARED);
title(sprintf('T^2 of each x'));

%% Principal Component Scores
set(0, 'CurrentFigure', figs(2));
imagesc(pca_builtin.SCORE);
pcs = size(pca_builtin.SCORE, 2);
title(sprintf('%d Principal Components\n%s', pcs, analysis_name));
colormap cool;

%% Reshape COEFF and plot individual PCs
set(0, 'CurrentFigure', figs(3));
colormap cool;

pca_builtin.resCOEFF = reshape(pca_builtin.COEFF, ...
    reshape_size(1), reshape_size(2), size(pca_builtin.COEFF, 2));

for i = 1 : size(pca_builtin.COEFF, 2)
    subplot(round(pcs/2), 2, i);
    imagesc(pca_builtin.resCOEFF(:,:,i));    
    axis tight;
    title(sprintf('PC %d', i));
end

end