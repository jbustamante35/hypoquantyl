function [PCA_custom, PCA_builtin] = pcaAnalysis(rawD, numC, sz, sv, dName, vis)
%% pcaAnalysis: custom pca analysis
% This function takes in rasterized data set of size [N x d] and returns a structure containing all
% data extracted after pca analysis. User defines number of components to reduce to.
%
% Usage:
%   [PCA_custom, PCA_builtin] = pcaAnalysis(rawD, numC, sz, sv, dName, vis)
%
% Input:
%   rawD: rasterized data set to conduct analysis
%   numC: number of PCA components to reduce
%   sz: [2 x 1] array to resize linearized data into original shape
%   sv: boolean to save analysis in .mat file
%   dName: name for data being analyzed (for figure names)
%   vis: boolean to visualize various output from analysis
%
% Output:
%   PCA_custom: structure containing data using my custom pca function
%   PCA_builtin: structure containing data using MATLAB's built-int pca function
%

%% PCA using my custom pca function
% Find and subtract off means
avgD  = mean(rawD, 1);
subD  = bsxfun(@minus, rawD, avgD);

% Get Variance-Covariance Matrix
covD = (subD' * subD) / size(subD,1);

% Get Eigenvector and Eigenvalues
[eigV, eigX] = eigs(covD, numC);

% Simulate data points by projecting eigenvectors onto original data
pcaS = subD * eigV;
simD = ((pcaS * eigV') + avgD);

%% Setup output structure
PCA_custom = struct('InputData',    rawD, ...
    'MeanVals',     avgD, ...
    'MeanCentered', subD, ...
    'VarCovar',     covD, ...
    'EigVectors',   eigV, ...
    'EigValues',    eigX, ...
    'PCAscores',    pcaS, ...
    'SimData',      simD);

%% ---------------------------------------------------------------------------------------------- %%
%% PCA using MATLAB's built-in pca function
warning('off','stats:pca:ColRankDefX'); % Turn off T-squared warning message for using > 3 PCs
[C, S, L, T, E, M] = pca(rawD, 'NumComponents', numC, 'Algorithm', 'svd');
PCA_builtin        = struct('COEFF',     C, ...
    'SCORE',     S, ...
    'LATENT',    L, ...
    'TSQUARED',  T, ...
    'EXPLAINED', E, ...
    'MU',        M);

%% Save results from custom and built-in analysis
if sv
    fname = sprintf('%s_pcaResults_%s_%dPCs', datestr(now, 'yymmdd'), dName, numC);
    save(fname, '-v7.3', 'PCA_custom', 'PCA_builtin');
end

%% ---------------------------------------------------------------------------------------------- %%
%% Show output from custom PCA analysis
if vis
    fig(1) = figure;
    ttl{1} = sprintf('%s_pcaCustom1', dName);
    colormap cool;
    
    subplot(311);
    imagesc(rawD);
    title(sprintf('Raw Rasterized Data: %s', dName));
    xlabel('Dimension');
    ylabel('Index');
    
    subplot(312);
    imagesc(subD);
    title(sprintf('Mean Centered Data: %s', dName));
    xlabel('Dimension');
    ylabel('Index');
    
    subplot(313);
    imagesc(covD);
    title(sprintf('Variance-Covariance Matrix: %s', dName));
    
    fig(2) = figure;
    ttl{2} = sprintf('%s_pcaCustom2', dName);
    colormap cool;
    
    subplot(211);
    imagesc(eigX);
    title(sprintf('Eigenvalues in descending order: %s', dName));   
    
    subplot(212);
    imagesc(eigV);
    title(sprintf('Eigenvectors: %s', dName));
    
    
    
    %% Show output from built-in pca analysis
    fig(3) = figure;
    ttl{3} = sprintf('%s_pcaBuiltin1', dName);
    subplot(231); imagesc(PCA_builtin.COEFF);     title('Coefficients (Variables to each X)');
    subplot(232); imagesc(PCA_builtin.EXPLAINED); title('Explained (% variance by each PC and Mu');
    subplot(233); imagesc(PCA_builtin.LATENT);    title('Latent (PC variances)');
    subplot(234); imagesc(PCA_builtin.MU);        title('Mu (Mean of each X)');
    subplot(235); imagesc(PCA_builtin.SCORE);     title('Scores (PC for each X)');
    subplot(236); imagesc(PCA_builtin.TSQUARED);  title('T-Squared of each X');        
    
    fig(4) = figure;
    ttl{4} = sprintf('%s_pcaBuiltin2', dName);
    imagesc(PCA_builtin.SCORE);
    title(sprintf('%d Principal Components: %s', numC, dName)), colormap cool;
    
    % Reshape COEFF and plot individual PCs
    PCA_builtin.resCOEFF = reshape(PCA_builtin.COEFF, sz(1), sz(2), size(PCA_builtin.COEFF,2));
    fig(5) = figure;
    ttl{5} = sprintf('%s_pcaBuiltin3', dName);
    for i = 1 : size(PCA_builtin.COEFF,2)
        subplot(round(numC/2), 2, i);
        imagesc(PCA_builtin.resCOEFF(:,:,i));
        colormap gray, axis image;
        title(sprintf('PC %d', i));
    end
    
    %% Save figures as .fig and .tiff
    if sv
        savename = sprintf('%s_PCA', datestr(now, 'yymmdd'));
        for i = 1 : length(fig)
            fignm = sprintf('%s_%s', savename, cell2mat(ttl(i)));
            curr = fig(i);
            savefig(curr, fignm);
            saveas(curr, fignm, 'tiffn');
        end
    end
    
end

end





