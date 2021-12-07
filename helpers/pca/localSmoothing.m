function [trgs , pdw] = localSmoothing(trgs, nsplt, PF)
%% localSmoothing: local PCA smoothing of segments
%
%
% Usage:
%   [trgs , pdw] = localSmoothing(trgs, nsplt, PF)
%
% Input:
%   trgs:
%   nsplt:
%   PF:
%
% Output:
%   trgs:
%   pdw:
%

%% Split and concatenate contours into segments
SEGS  = arrayfun(@(x) split2Segments(trgs(:,1:2,x), nsplt), ...
    1 : size(trgs,3), 'UniformOutput', 0)';
WX    = cellfun(@(x) squeeze(x(:,1,:))', SEGS, 'UniformOutput', 0);
WY    = cellfun(@(x) squeeze(x(:,2,:))', SEGS, 'UniformOutput', 0);
wvecs = [cat(1, WX{:}) , cat(1, WY{:})];

if isnumeric(PF)
    %% Build PC space with ground truth data
    npf = PF;
    pdw = myPCA(wvecs, npf);
    
else
    %% Project and Back-Project into PC space
    pdw   = PF;
    midx  = round(nsplt / 2);
    
    % Project --> Back-Project --> Reshape
    win  = pcaProject(wvecs, pdw.EigVecs, pdw.MeanVals, 'sim2scr');
    wout = pcaProject(win, pdw.EigVecs, pdw.MeanVals, 'scr2sim');        
    ws   = reshape(wout, [size(trgs,1) , size(trgs,3) , nsplt , 2]);
    ws   = permute(ws, [3 , 4 , 1 , 2]);
                
    % Re-shift indices to correct spot (middle index matches input index)
    trgs        = permute(squeeze(ws(midx,:,:,:)), [2 , 1 , 3]);
    trgs(:,3,:) = 1;
    trgs        = circshift(trgs, midx-1);
    
end
end
