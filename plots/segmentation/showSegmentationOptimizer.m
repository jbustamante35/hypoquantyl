function out = showSegmentationOptimizer(img, ctru, cinit, zpre, cpredict, aa, bb)
%% showSegmentationOptimizer:
%
%
% Usage:
%   out = showSegmentationOptimizer(img, ctru, cinit, cpre, aa, bb)
%
% Input:
%   img:
%   ctru:
%   cinit:
%   cpre:
%   aa:
%   bb:
%
% Output:
%   out:
%

%%
% cpre  = cpredict(img, zpre);
ztru  = contour2corestructure(ctru);
zinit = contour2corestructure(cinit);
% zpre  = contour2corestructure(cpre);

%%
set(gcf, 'Color', 'w');
myimagesc(img);
axis ij;
hold on;

% Show Z-Vectors
plt(ztru(:,1:2), 'b.', 2);
plt(zinit(:,1:2), 'r.', 2);
plt(zpre(:,1:2), 'g.', 2);

ttl = sprintf('Fmin Search Optimization');
lgn = {'Ground Truth' , 'Initial Guess' , 'Optimized Prediction'};
title(ttl, 'FontSize', 10);
legend(lgn, 'Location', 'southeast', 'FontSize', 10);

% plt(ctru, 'b-', 2);
% plt(cinit, 'r-', 2);
% plt(cpre, 'g-', 2);

hold off;
out = false;

end
