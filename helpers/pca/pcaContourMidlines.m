function [pr , evecs , mns] = pcaContourMidlines(c, npr, sav)
%% pcaContourMidlines: PCA on contour-midline complex
% Description
%
% Usage:
%   [pr , evecs , mns] = pcaContourMidlines(c, npr)
%
% Input:
%   c: array of Curves where midlines have been traced
%   npr: number of principal components to reduce to (default 15)
%   sav: save results in .mat file (default false)
%
% Output:
%   pr: object after PCA
%   evecs: eigenvectors from dataset
%   mns: column means from covariance matrix
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%% Default number of PCs
if nargin < 2
    npr = 15;
    sav = 0;
end

% Get info about dataset
nmids = numel(c);
csize = c(1).TraceSize;
msize = c(1).MidlineSize;
cmsize = csize + msize;

% Concatenate and rasterize contour-midline complexes
m  = arrayfun(@(idx) [c(idx).getTrace('norm') ; c(idx).getMidline('norm')], ...
    1 : numel(c), 'UniformOutput', 0);
M  = cat(3, m{:});
R  = reshape(M, [cmsize * 2 , nmids])';

% Run PCA and get outputs
pr    = pcaAnalysis(R, npr, sav, 'contourmidline', 0);
evecs = pr.EigVecs;
mns   = pr.MeanVals;

end

