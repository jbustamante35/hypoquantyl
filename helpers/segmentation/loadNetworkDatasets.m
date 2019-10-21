function [px, py, pz, pp, Nz, Ns] = loadNetworkDatasets(ROOTDIR, PCADIR, SIMDIR)
%% loadNetworkDatasets: load given PCA datasets and neural net models
% Input:
%   DATADIR: root directory of datasets
%   MFILES: directory with .mat files
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
    SIMDIR  = 'simulations';
end

%%
t    = tic;
sprt = repmat('-', 1, 80);

fprintf('\n\n%s\nLoading datasets and neural networks from %s:\n', ...
    sprt, ROOTDIR);

% Load PCA data [trim down and move into repository]
PCA  = 'PCA_custom';
pcax = '190709_pcaResults_x210Hypocotyls_3PCs.mat';
pcay = '190709_pcaResults_y210Hypocotyls_3PCs.mat';
pcaz = '190726_pcaResults_z210Hypocotyls_Reduced_10PCs.mat';
pcap = '190913_pcaResults_zp43890ZPatches_5PCs.mat';

px = loadFnc(ROOTDIR, PCADIR, pcax, PCA);
py = loadFnc(ROOTDIR, PCADIR, pcay, PCA);
pz = loadFnc(ROOTDIR, PCADIR, pcaz, PCA);
pp = loadFnc(ROOTDIR, PCADIR, pcap, PCA);

px = px.PCA_custom;
py = py.PCA_custom;
pz = pz.PCA_custom;
pp = pp.PCA_custom;

% Load latest network models [trim down and move into repository]
DOUT   = 'OUT';
cnnout = 'zvectors/190727_ZScoreCNN_210Contours_z10PCs_x3PCs_y3PCs.mat';
snnout = 'svectors/190916_SScoreNN_43890Segment_s6PCs.mat';

co = loadFnc(ROOTDIR, SIMDIR, cnnout, DOUT);
so = loadFnc(ROOTDIR, SIMDIR, snnout, DOUT);

ZNN = co.OUT.DataOut;
SNN = so.OUT.DataOut;

% Extract the networks
Nz = arrayfun(@(x) x.NET, ZNN, 'UniformOutput', 0);
s  = arrayfun(@(x) sprintf('N%d', x), 1:numel(Nz), 'UniformOutput', 0);
Nz = cell2struct(Nz, s, 2);

Ns = arrayfun(@(x) x.Net, SNN, 'UniformOutput', 0);
s  = arrayfun(@(x) sprintf('N%d', x), 1:numel(Ns), 'UniformOutput', 0);
Ns = cell2struct(Ns, s, 2);

fprintf('DONE! [%.02f sec]\n', toc(t));

% Load 'em up!
    function y = loadFnc(rootdir, datadir, fin, vin)
        %% loadFunction: load dataset and variables with output message
        str = sprintf('%s/%s/%s', rootdir, datadir, fin);
        y   = load(str, vin);
        fprintf('Loaded %s\n', fin);
    end

end