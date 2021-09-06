function [pz , pdp , pdx , pdy , pdw , Nz , Nd , trnIdx , valIdx , tstIdx] = loadHTNetworks(HT)
%% loadHTNetworks: Load models and PCA from HypocotylTrainer object
% Description
%
% Usage:
%   [pz , pdp , pdx , pdy , Nz , Nd , trnIdx , valIdx , tstIdx] = ...
%        loadHTNetworks(HT)
%
% Input:
%   HT: HypocotylTrainer object
%
% Output:
%   pz:
%   pdp:
%   pdx:
%   pdy:
%   Nz:
%   Nd:
%   trnIdx:
%   valIdx
%

%% Get training and validation indices
splts  = HT.getSplits;
trnIdx = splts.trnIdx;
valIdx = splts.valIdx;
tstIdx = splts.tstIdx;

% ---------------------------------------------------------------------------- %
% Load Z-Vector models
zout = HT.getZVector('ZOUT');
pz   = HT.getPCA('pz');
Nz   = arrayfun(@(x) x.Net, zout, 'UniformOutput', 0);
nstr = arrayfun(@(x) sprintf('N%d', x), 1 : numel(Nz), 'UniformOutput', 0);
Nz   = cell2struct(Nz, nstr);

% ---------------------------------------------------------------------------- %
% Load D-Vector models
dout = HT.getDVector('DOUT');
Nd   = dout.Net;
nstr = arrayfun(@(x) sprintf('N%d', x), 1 : numel(Nd), 'UniformOutput', 0);
Nd   = cell2struct(Nd, nstr, 2);

pdp.EigVecs  = dout.EigVecs;
pdp.MeanVals = dout.MeanVals;

pdx = dout.pdf.pdx;
pdy = dout.pdf.pdy;
pdw = dout.pdf.pdw;

if nargout == 1
    splts = struct('trnIdx', trnIdx , 'valIdx', valIdx , 'tstIdx', tstIdx);
    hout  = {pz   , pdp   , pdx   , pdy   , pdw   , Nz   , Nd   , splts}';
    flds  = {'pz' , 'pdp' , 'pdx' , 'pdy' , 'pdw' , 'Nz' , 'Nd' , 'splts'}';
    pz    = cell2struct(hout, flds);
end
end

