function mypca = pcaAnalysis(vec, npc, sav, pnm, varargin)
%% pcaAnalysis: custom pca analysis
% This function takes in rasterized data set of size [N x d] and returns a
% structure containing all data extracted after pca analysis. User defines
% number of components to reduce to.
%
% Note [10.23.2019]
% I removed the built-in PCA results because I'm so much better than them
%
% Usage:
%   mypca = pcaAnalysis(rawD, numC, sav, dName, varargin)
%
% Input:
%   rawD: rasterized data set to conduct analysis
%   numC: number of PCA components to reduce
%   sv: boolean to save analysis in .mat file
%   dName: name for data being analyzed (for figure names)
%   varargin: additional parameters (example: {'ZScoreNormalize', 1})
%   vis: boolean to visualize various output from analysis [removed 3.31.2021]
%   mth: use custom class (1) or store into structure (2) [removed 04.05.2021]
%
% Output:
%   mypca: structure containing data using my custom pca function
%

%% PCA using my custom pca function and MATLAB's built-in pca function
% Default to Method 1 and no visualization
if nargin < 2; npc   = 3;            end
if nargin < 3; sav   = 0;            end
if nargin < 4; pnm = sprintf('pca'); end

if nargin < 2
    fprintf(2, 'Not enough input arguments [%d]\n', nargin);
    mypca = [];
    return;
end

%%
mypca = PcaJB(vec, npc, 'DataName', pnm, varargin{:});
fname = mypca.DataName;

% ---------------------------------------------------------------------------- %
%% Save results from custom and built-in analysis
if sav; save(fname, '-v7.3', 'mypca'); end
end
