function [ptx, pty, pz, pp, Nz, Nt] = loadZVecNetworks(ROOTDIR, PCADIR, SIMDIR, TRNDIR)
%% loadZVecNetworks: load PCA datasets and neural net models for Z-Vectors
% Input:
%   DATADIR: root directory of datasets
%   MFILES: directory with .mat files
%   PCADIR: directory with PCA datasets
%   SIMDIR: directory with neural net data
%   TRNDIR: directory with training data
%
% Output:
%   pz:
%   Nz:
%

%% Defaults
if nargin == 0
    DATADIR = '/home/jbustamante/Dropbox/EdgarSpalding/labdata';
    MFILES  = 'development/HypoQuantyl/datasets/matfiles';
    ROOTDIR = sprintf('%s/%s', DATADIR, MFILES);
    PCADIR  = 'pca';
    SIMDIR  = 'simulations';
    TRNDIR  = 'training';
end

%%
t    = tic;
sprt = repmat('-', 1, 80);

fprintf('\n\n%s\nLoading datasets and neural networks from %s:\n', ...
    sprt, ROOTDIR);

%% PCA data for Z-Vectors
PCA  = 'PCA_custom';
pcaz = '190726_pcaResults_z210Hypocotyls_Reduced_10PCs.mat';
pz   = loadFnc(ROOTDIR, PCADIR, pcaz, PCA);
pz   = pz.PCA_custom;

%% Neural Net model for predicting Z-Vectors
DOUT   = 'OUT';
cnnout = 'zvectors/190727_ZScoreCNN_210Contours_z10PCs_x3PCs_y3PCs.mat';
co     = loadFnc(ROOTDIR, SIMDIR, cnnout, DOUT);
ZNN    = co.OUT.DataOut;

% Extract the networks
Nz = arrayfun(@(x) x.NET, ZNN, 'UniformOutput', 0);
s  = arrayfun(@(x) sprintf('N%d', x), 1:numel(Nz), 'UniformOutput', 0);
Nz = cell2struct(Nz, s, 2);

%% Neural Net model for predicting displacement vectors
TOUT   = 'TN';
trnnet = '191017_HQTrainedData_20Iterations_300Curves.mat';
TN     = loadFnc(ROOTDIR, TRNDIR, trnnet, TOUT);

% Extract the networks
Nt  = arrayfun(@(x) x.Net, TN.TN, 'UniformOutput', 0);
s   = arrayfun(@(x) sprintf('N%d', x), 1:numel(Nt), 'UniformOutput', 0);
Nt = cell2struct(Nt, s, 2);

%% Eigenvectors and Means for image patches
pp.EigVectors = arrayfun(@(x) x.EigVectors, TN.TN, 'UniformOutput', 0);
pp.MeanVals   = arrayfun(@(x) x.Means, TN.TN, 'UniformOutput', 0);

%% PCA data for folding predictions
pcatx = '191017_pcaResults_FoldPredictionsX_10PCs';
pcaty = '191017_pcaResults_FoldPredictionsY_10PCs';
ptx   = loadFnc(ROOTDIR, PCADIR, pcatx, PCA);
pty   = loadFnc(ROOTDIR, PCADIR, pcaty, PCA);
ptx   = ptx.PCA_custom;
pty   = pty.PCA_custom;

fprintf('DONE! [%.02f sec]\n', toc(t));

%% Load 'em up!
    function y = loadFnc(rootdir, datadir, fin, vin)
        %% loadFunction: load dataset and variables with output message
        str = sprintf('%s/%s/%s', rootdir, datadir, fin);
        y   = load(str, vin);
        fprintf('Loaded %s from %s\n', vin, fin);
    end

end