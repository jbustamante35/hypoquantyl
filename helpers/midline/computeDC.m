function scrs = computeDC(trgParamPath, scrs, evecs, mns, vis)
%% computeDC
% Description
%
% Usage:
%    scrs = computeDC(trgParamPath, scrs, evecs, mns, vis)
%
% Input:
%   trgParamPath: parameter path to target scores
%   scrs: PC scores of single inputted complex of contour-midlines
%   evecs: eigenvectors of contour-midlines
%   mns: mean values of contour-midlines
%   vis: figure handle index to show output
%
% Output:
%    scrs: input PC scores with iterative scores to target
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%%
if nargin < 5
    vis = 0;
end

options = optimset('Display','final', 'MaxFunEvals', 500);

for e = 1 : size(trgParamPath,1)
    %% Minimization function to find scores to
    scrs(e+1,:) = fminsearch(@(x) ...
        hypoDistance(x, trgParamPath(e,:), evecs, mns), scrs(e,:), options);
    
    fprintf('Current Loop %d\n', e);
    
    %% Show midline and contour form current score
    if vis
        figclr(vis);
        showOutput(scrs(e+1,:), evecs, mns);
        ttl = sprintf('Iteration %d', e);
        title(ttl, 'FontSize', 10);
        drawnow;
    end
end

end

function showOutput(scr, evecs, mns)
%% showOutput
tsz = 210;
msz = 50;

% Convert PC score to contour and midline
% v     = pcaProject(scr, evecs, mns, 'scr2sim');
% r     = reshape(v, [tsz + msz , 2]);
% cntr  = r(1 : tsz, :);
% mline = r(tsz + 1 : end, :);
[cntr , mline] = cmscr2cmvec(scr, evecs, mns, tsz, msz);

% Plot contour and midline
plt(cntr, 'g-', 2);
axis image;
axis ij;
hold on;
plt(mline, 'r-', 2);

end
