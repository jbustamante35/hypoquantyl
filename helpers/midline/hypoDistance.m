function d = hypoDistance(scr, trgParams, evecs, mns)
%% hypoDistance: evaluate difference between parameters of scores and target
% Description
%
% Usage:
%   d = hypoDistance(scr, trgParams, evecs, mns)
%
% Input:
%   scr: input PC scores to evaluate
%   trgParams: parameters of target score
%   evecs: eigenvectors of contour-midlines
%   mns: mean values of contour-midlines
%
% Output:
%   d: normalized distance of parameters from score to target parameters
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%%
p = measureAtC(scr, evecs, mns);
d = norm(trgParams - p);

end

