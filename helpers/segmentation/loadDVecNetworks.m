function [pdx, pdy, pz, pdp, Nz, Nd] = loadDVecNetworks(ROOTDIR, PCADIR, NETOUT)
%% loadDVecNetworks: load PCA datasets and neural net models for Z-Vectors
%
% Usage:
%   [pdx, pdy, pz, pdp, Nz, Nd] = loadDVecNetworks(ROOTDIR, PCADIR, NETOUT)
%
% Input:
%   ROOTDIR: root directory of datasets and mat-files
%   PCADIR: directory with PCA datasets
%   SIMDIR: directory with neural net data
%
% Output:
%   ptx:
%   pty:
%   pz:
%   Nz:
%   Nt:
%

%% Default locations
if nargin == 0
    DATADIR = '/home/jbustamante/Dropbox/EdgarSpalding/labdata';
    MFILES  = 'development/HypoQuantyl/datasets/matfiles';
    ROOTDIR = sprintf('%s/%s', DATADIR, MFILES);
    PCADIR  = 'pca';
    NETOUT  = 'netoutputs';
end

t    = tic;
sprt = repmat('-', 1, 80);

fprintf('\n\n%s\nLoading datasets and neural networks from %s:\n', ...
    sprt, ROOTDIR);

%% PCA data for Z-Vectors
PCA  = 'mypca';
pcaz = 'pcaz.mat';
pz   = loadFnc(ROOTDIR, PCADIR, pcaz, PCA);
pz   = pz.(PCA);

%% Neural Net model for predicting Z-Vectors
ZOUT   = 'OUT';
znnout = 'znn/znnout.mat';
co     = loadFnc(ROOTDIR, NETOUT, znnout, ZOUT);
ZNN    = co.OUT;

% Extract the networks
if isstruct(ZNN.Net)
    Nz = ZNN.Net;
else
    Nz = arrayfun(@(x) x.Net, ZNN, 'UniformOutput', 0);
    s  = arrayfun(@(x) sprintf('N%d', x), 1:numel(Nz), 'UniformOutput', 0);
    Nz = cell2struct(Nz, s, 2);
end

%% Neural Net model for predicting displacement vectors
DOUT   = 'TN';
dnnout = 'dnn/dnnout.mat';
TN     = loadFnc(ROOTDIR, NETOUT, dnnout, DOUT);

% Extract the networks
Nd  = arrayfun(@(x) x.Net, TN.TN, 'UniformOutput', 0);
s   = arrayfun(@(x) sprintf('N%d', x), 1:numel(Nd), 'UniformOutput', 0);
Nd = cell2struct(Nd, s, 2);

%% Eigenvectors and Means for image patches
pdp.EigVecs  = arrayfun(@(x) x.EigVecs, TN.TN, 'UniformOutput', 0);
pdp.MeanVals = arrayfun(@(x) x.MeanVals, TN.TN, 'UniformOutput', 0);

%% PCA data for folding D-Vector predictions
pcadx = 'pcadx.mat';
pcady = 'pcady.mat';
pdx   = loadFnc(ROOTDIR, PCADIR, pcadx, PCA);
pdy   = loadFnc(ROOTDIR, PCADIR, pcady, PCA);
pdx   = pdx.(PCA);
pdy   = pdy.(PCA);

fprintf('DONE! [%.02f sec]\n', toc(t));

%% Load 'em up!
    function y = loadFnc(rootdir, datadir, fin, vin)
        %% loadFunction: load dataset and variables with output message
        str = sprintf('%s/%s/%s', rootdir, datadir, fin);
        y   = load(str, vin);
        fprintf('Loaded %s from %s\n', vin, fin);
    end

end

