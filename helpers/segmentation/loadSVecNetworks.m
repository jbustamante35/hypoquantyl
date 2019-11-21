function [px, py, pz, pzp, psx, psy, Nz, Ns] = loadSVecNetworks(ROOTDIR, PCADIR, SIMDIR)
%% loadSVecNetworks: load datasets models for S-Vector predictions
%
% Usage:
%   [px, py, pz, pzp, psx, psy, Nz, Ns] = ...
%       loadSVecNetworks(ROOTDIR, PCADIR, SIMDIR)
%
% Input:
%   ROOTDIR: root directory of datasets and .mat files
%   PCADIR: directory with PCA datasets
%   SIMDIR: directory with neural net data
%
% Output:
%
%

%% Load defaults
if nargin == 0
    DATADIR = '/home/jbustamante/Dropbox/EdgarSpalding/labdata';
    MFILES  = 'development/HypoQuantyl/datasets/matfiles';
    ROOTDIR = sprintf('%s/%s', DATADIR, MFILES);
    PCADIR  = 'pca';
    SIMDIR  = 'netoutputs';
end

%%
t    = tic;
sprt = repmat('-', 1, 80);

fprintf('\n\n%s\nLoading datasets and neural networks from %s:\n', ...
    sprt, ROOTDIR);

% Load latest PCA data [trim down and move into repository]
PCA   = 'mypca';
pcax  = 'pcax.mat';
pcay  = 'pcay.mat';
pcaz  = 'pcaz.mat';
pcazp = 'pcazp.mat';
pcasx = 'pcasx.mat';
pcasy = 'pcasy.mat';

px  = loadFnc(ROOTDIR, PCADIR, pcax,  PCA);
py  = loadFnc(ROOTDIR, PCADIR, pcay,  PCA);
pz  = loadFnc(ROOTDIR, PCADIR, pcaz,  PCA);
pzp = loadFnc(ROOTDIR, PCADIR, pcazp, PCA);
psx = loadFnc(ROOTDIR, PCADIR, pcasx, PCA);
psy = loadFnc(ROOTDIR, PCADIR, pcasy, PCA);

px  = px.(PCA);
py  = py.(PCA);
pz  = pz.(PCA);
pzp = pzp.(PCA);
psx = psx.(PCA);
psy = psy.(PCA);

% Load latest network models [trim down and move into repository]
DOUT   = 'OUT';
znnout = 'znn/znnout.mat';
snnout = 'snn/snnout.mat';

co = loadFnc(ROOTDIR, SIMDIR, znnout, DOUT);
so = loadFnc(ROOTDIR, SIMDIR, snnout, DOUT);

ZNN = co.OUT;
SNN = so.OUT;

% Extract the networks
if isstruct(ZNN.Net)
    Nz = ZNN.Net;
else
    Nz = arrayfun(@(x) x.Net, ZNN, 'UniformOutput', 0);
    s  = arrayfun(@(x) sprintf('N%d', x), 1:numel(Nz), 'UniformOutput', 0);
    Nz = cell2struct(Nz, s, 2);
end

if isstruct(SNN.Net)
    Ns = SNN.Net;
else
    Ns = arrayfun(@(x) x.Net, SNN, 'UniformOutput', 0);
    s  = arrayfun(@(x) sprintf('N%d', x), 1:numel(Ns), 'UniformOutput', 0);
    Ns = cell2struct(Ns, s, 2);
end

fprintf('DONE! [%.02f sec]\n', toc(t));

%% Load 'em up!
    function y = loadFnc(rootdir, datadir, fin, vin)
        %% loadFunction: load dataset and variables with output message
        str = sprintf('%s/%s/%s', rootdir, datadir, fin);
        y   = load(str, vin);
        fprintf('Loaded %s\n', fin);
    end

end