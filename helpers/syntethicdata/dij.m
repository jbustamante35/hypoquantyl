function scrsOut = dij(cntr, scrsIn, eVec, eVals, mns, frm, sz, df, vis)
%% dij: 
%
%
% Usage:
%   scrsOut = dij(cntr, scrsIn, eVec, eVals, mns, frm, sz, df, vis)
%
% Input:
%   cntr: x-/y-coordinates of a contour
%   scrsIn: pca scores to change
%   eVec: eigenvectors
%   eVals: egenvalues
%   mns: pca means
%   frm: frame to shift into
%   sz: size to reshape back-projection
%   df: initial parameters
%   vis: boolean to visualize change in shape after changing scores
%
% Output:
%   scrsOut: new scores after changing parameters
%


% Back-Project
tmpcrv = (scrsIn * eVec') + mns;
crv    = reshape(tmpcrv, sz);
trc    = (frm * crv')';
met0   = featureMetric(trc, frm);

%
nm    = size(met0,1);
nscrs = size(scrsIn,2);
delta = 0.1;

if vis
    plt(cntr, 'g--', 1);
    axis ij;
    axis image;
    hold on;
end

%%
for sIdx = 1 : nscrs
    % Scale delta to eigenvalues
    dlt = delta * eVals(sIdx,sIdx);
    
    % Get measurements and trace from changing PC scores
    [met1, trc1] = getMetrics(scrsIn, sIdx, eVec, mns, sz, dlt, frm, @plus);
    [met2, trc2] = getMetrics(scrsIn, sIdx, eVec, mns, sz, dlt, frm, @minus);
    
    if vis
        plt(trc1, 'r-', 2);
        plt(mean(trc1(:,1:2)), 'r*', 10);
        plt(trc2, 'g-', 2);
        plt(mean(trc2(:,1:2)), 'g*', 10);
    end
    
    % Store in measurement matrix for each changing score
    M(:,sIdx) = mean([delta^-1 * (met1 - met0) , -delta^-1 * (met2 - met0)], 2);
    
end

%
dc      = (M \ df') .* diag(eVals);
scrsOut = scrsIn + dc';

end

function [met , trc] = getMetrics(scrs, scrIdx, ev, mns, sz, delta, frm, fn)
%% getMetrics:
scrs(scrIdx) = fn(scrs(scrIdx), delta);
nc           = (scrs * ev') + mns;
crv          = reshape(nc, sz);
trc          = (frm * crv')';
met          = featureMetric(trc, frm);

end


