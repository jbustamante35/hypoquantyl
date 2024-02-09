function [escr , out] = computeError(img, evec, emid, estd, efunc)
%% computeSegmentationError
% 1) Sample image from midline
% 2) Project into midline patch PC space
% 3) Re-project PC scores back to midline patch space
% 4) Compute error from re-projection
% 5) Compute distance to dataset median
% 6) Compute PC score probability
%
% Usage:
%   [scr , out] = computeError(img, evec, emid, estd, efunc)
%
% Input:
%   img: image
%   evec: vector to evaluate
%   emid: median of re-projection error from dataset
%   estd: standard deviation of re-projection error from dataset
%   efunc: structure containing function handles
%       esample: sample vector onto image
%       ecnv: project vectorized image patch to/from pc space
%       escore: score probabiity of pc scores against distribution
%
% Output:
%   scr: computed score
%   out: miscellaneous data
%       smp: vector sampled on image
%       prj: vector re-projected from pc space
%       pcs: sampled vector in pc space
%       err: norm of the difference from re-projected to sampled
%       dst: distance to median of error distribution
%       std: standard deviations from the median
%       prb: probability score from PC score distribution
%       scr: computed score (std * prb)

% Extract function handles
esample = efunc.esample;
ecnv    = efunc.ecnv;
escore  = efunc.escore;

% Sample and Project
smp = esample(img, evec);
pcs = ecnv(smp);
dim = size(smp);
enp = numel(pcs);
prj = reshape(ecnv(pcs(1 : enp)), dim);

% Compute error, probability, and standard deviations from median
eerr = norm(prj(:) - smp(:));
edst = pdist([eerr ; emid]);
edev = nstds(edst, emid, estd);
eprb = escore(img, evec);
escr = edev * eprb;

% Return extra data
out.smp = smp;
out.prj = prj;
out.pcs = pcs;
out.err = eerr;
out.dst = edst;
out.std = edev;
out.prb = eprb;
out.scr = escr;
end