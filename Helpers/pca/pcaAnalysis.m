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

%% PCA using my custom pca function and MATLAB's built-in pca function
PCA_custom  = myPCA(rawD, numC);
PCA_builtin = builtinPCA(rawD, numC);

%% Save results from custom and built-in analysis
if sv
    fname = sprintf('%s_pcaResults_%s_%dPCs', datestr(now, 'yymmdd'), dName, numC);
    save(fname, '-v7.3', 'PCA_custom', 'PCA_builtin');
end

%% Show output from custom and builtin PCA analysis
if vis
    [figC, ttlC] = showMyPCA(PCA_custom, analysis_name);
    [figB, ttlB] = showBuiltinPCA(PCA_builtin, analysis_name, sz);
    
    %% Save figures as .fig and .tiff
    figA = [figC figB];
    ttlA = [ttlC ttlB];
    if sv
        savename = sprintf('%s_PCA', datestr(now, 'yymmdd'));
        for i = 1 : length(figA)
            fignm = sprintf('%s_%s', savename, ttlA{i});
            curr = figA(i);
            savefig(curr, fignm);
            saveas(curr, fignm, 'tiffn');
        end
    end
    
end

end





