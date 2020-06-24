function fnms = compareSkeletonPatches(btru, bpre, idxs, setnm, nfigs)
%% compareSkeletonPatches: assess network model for skeleton patches
% Description
%
% Usage:
%    fnms = compareSkeletonPatches(btru, bpre, idxs, setnm, nfigs)
%
% Input:
%   btru: cell array of ground truth skeleton patches
%   bpre: cell array of predicted skeleton patches
%   idxs: index for training and validation sets
%   setnm: name for index you are querying from
%   nfigs: figures to show output
%
% Output:
%    fnms: figure names
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%%
if nargin < 5
    nfigs = 1 : 4;
end

%% Compare predicted patches with original
numfigs = numel(nfigs);
setidx  = pullRandom(idxs, numfigs);
setimg  = [btru(setidx) ; bpre(setidx)]';
rows    = 1;
cols    = 2;

fnms = cell(numfigs, 1);
for f = 1 : numfigs
    figclr(nfigs(f));
    subplot(rows, cols, 1);
    imagesc(setimg{f,1});
    ttl = sprintf('Ground Truth %d\n%s Set', setidx(f), setnm);
    title(ttl, 'FontSize', 10);
    
    subplot(rows, cols, 2);
    imagesc(setimg{f,2});
    ttl = sprintf('Predicted %d\n%s Set', setidx(f), setnm);
    title(ttl, 'FontSize', 10);
    
    fnms{nfigs(f)} = sprintf('%s_SegmentPatches_TruthVsPrediction_%sSet_Segment%04d', ...
        tdate, setnm, setidx(f));
    colormap gray;
end

end