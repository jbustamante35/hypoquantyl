function mypca = pcaAnalysis(rawD, numC, sv, dName, vis, mth)
%% pcaAnalysis: custom pca analysis
% This function takes in rasterized data set of size [N x d] and returns a
% structure containing all data extracted after pca analysis. User defines
% number of components to reduce to.
%
% Note [10.23.2019]
% I removed the built-in PCA results because I'm so much better than them
%
% Usage:
%   mypca = pcaAnalysis(rawD, numC, sv, dName, vis, mth)
%
% Input:
%   rawD: rasterized data set to conduct analysis
%   numC: number of PCA components to reduce
%   sv: boolean to save analysis in .mat file
%   dName: name for data being analyzed (for figure names)
%   vis: boolean to visualize various output from analysis
%   mth: method 1 uses a class object, method 2 stores into structure
%
% Output:
%   mypca: structure containing data using my custom pca function
%

%% PCA using my custom pca function and MATLAB's built-in pca function
% Default to Method 1
switch nargin 
    case 4
        vis = 0;
        mth = 1;
    case 5
        mth = 1;
    case 6
    otherwise
        fprintf(2, 'Error with inputs [%d]\n', nargin);
        mypca = [];
        return;
end

switch mth
    case 1
        % Update that uses a custom class [10.23.2019]
        mypca = PcaJB(rawD, numC, 'DataName', dName);
        fname = mypca.DataName;
        
    case 2
        % Traditional method that uses stores data into built-in structure
        mypca = myPCA(rawD, numC, 'old');
        fname = sprintf('%s_pcaResults_%s_%dPCs', tdate, dName, numC);
        
    otherwise
        fprintf(2, 'Error with Method %d\n', mth);
        mypca = [];
        return;
end

%% Save results from custom and built-in analysis
if sv
    save(fname, '-v7.3', 'mypca');
end

%% Show output from custom and builtin PCA analysis
if vis
    analysis_name = dName; % Just in case I want to change the title formatting
    [figC, ttlC]  = showMyPCA(mypca, analysis_name);
    
    %% Save figures as .fig and .tiff
    if sv
        savename = sprintf('%s_PCA', datestr(now, 'yymmdd'));
        fignm    = sprintf('%s_%s', savename, ttlC);
        savefig(figC, fignm);
        saveas(figC, fignm, 'tiffn');
    end
    
end

end


