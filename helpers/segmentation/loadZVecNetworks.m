function [ptx, pty, pz, ptp, Nz, Nt] = loadZVecNetworks(ROOTDIR, PCADIR, SIMDIR, TRNDIR)
%% loadZVecNetworks: load PCA datasets and neural net models for Z-Vectors
%
% Usage:
%   [ptx, pty, pz, pp, Nz, Nt] = ...
%           loadZVecNetworks(ROOTDIR, PCADIR, SIMDIR, TRNDIR)
%
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
PCA  = 'mypca';
pcaz = 'pcaz.mat';
pz   = loadFnc(ROOTDIR, PCADIR, pcaz, PCA);
pz   = pz.(PCA);

%% Neural Net model for predicting Z-Vectors
DOUT   = 'OUT';
znnout = 'zvectors/znnout.mat';
co     = loadFnc(ROOTDIR, SIMDIR, znnout, DOUT);
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
TOUT   = 'TN';
trnnet = 'trnnet.mat';
TN     = loadFnc(ROOTDIR, TRNDIR, trnnet, TOUT);

% Extract the networks
Nt  = arrayfun(@(x) x.Net, TN.TN, 'UniformOutput', 0);
s   = arrayfun(@(x) sprintf('N%d', x), 1:numel(Nt), 'UniformOutput', 0);
Nt = cell2struct(Nt, s, 2);

%% Eigenvectors and Means for image patches
try
    ptp.EigVecs  = arrayfun(@(x) x.EigVecs, TN.TN, 'UniformOutput', 0);
    ptp.MeanVals = arrayfun(@(x) x.Means, TN.TN, 'UniformOutput', 0);
catch
    ptp.EigVecs  = arrayfun(@(x) x.EigVectors, TN.TN, 'UniformOutput', 0);
    ptp.MeanVals = arrayfun(@(x) x.Means, TN.TN, 'UniformOutput', 0);
end
    
%% PCA data for folding predictions
pcatx = 'pcatx.mat';
pcaty = 'pcaty.mat';
ptx   = loadFnc(ROOTDIR, PCADIR, pcatx, PCA);
pty   = loadFnc(ROOTDIR, PCADIR, pcaty, PCA);
ptx   = ptx.(PCA);
pty   = pty.(PCA);

fprintf('DONE! [%.02f sec]\n', toc(t));

%% Load 'em up!
    function y = loadFnc(rootdir, datadir, fin, vin)
        %% loadFunction: load dataset and variables with output message
        str = sprintf('%s/%s/%s', rootdir, datadir, fin);
        y   = load(str, vin);
        fprintf('Loaded %s from %s\n', vin, fin);
    end

end

