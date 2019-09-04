function PLSR = plsrAnalysis(X, Y, numR, sv, dName, vis)
%% plsrAnalysis: custom pca analysis
% This function takes in rasterized data set of size [N x d] and returns a
% structure containing all data extracted after pca analysis. User defines
% number of components to reduce to.
%
% Usage:
%   PLSR = plsrAnalysis(X, Y, numR, sv, dName, vis)
%
% Input:
%   X: [N x P] predictor variables of N observations and P variables
%   Y: [N x M] response variables of M loading from the N observations
%   numR: number of components to reduce the dataset down to
%   sv: boolean to save analysis in .mat file
%   dName: name for data being analyzed (for figure names)
%   vis: boolean to visualize various output from analysis
%
% Output:
%   PLSR: structure containing data using my wrapper for pls regression
%

%% PCA using my custom pca function and MATLAB's built-in pca function
PLSR = myPLSR(X, Y, numR);

%% Save results from custom and built-in analysis
if sv
    fname = sprintf('%s_plsrResults_%s_%dPCs', ...
        datestr(now, 'yymmdd'), dName, numR);
    save(fname, '-v7.3', 'PLSR');
end

%% Show output from custom and builtin PCA analysis [TODO]
if vis
    analysis_name = dName; % Just in case I want to change the title formatting
    [figC, ttlC]  = showMyPLSR(PLSR, analysis_name);

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
else
    fprintf('Parameter ''vis'' does nothing yet!\n');
end

end





