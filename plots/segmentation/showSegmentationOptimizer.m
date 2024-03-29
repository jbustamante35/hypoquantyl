function out = showSegmentationOptimizer(img, ctru, cinit, zpre, cpredict, aa, bb)
%% showSegmentationOptimizer:
%
% Usage:
%   out = showSegmentationOptimizer(img, ctru, cinit, zpre, cpredict, aa, bb)
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

% Quck or Full version
switch class(cpredict)
    case 'function_handle'
        % Full visualization
        cpre = cpredict(img, zpre);
    case 'double'
        if cpredict
            % Minimal visualization
            cpre = zpre(:,1:2);
        else
            % Skip Visualization
            out = false;
            return;
        end
end

%
myimagesc(img);
set(gcf, 'Color', 'w');
axis image;
axis ij;
hold on;

% Show Contours
plt(ctru, 'b-', 2);
plt(cinit, 'r-', 2);
plt(cpre, 'g-', 2);

ttl = sprintf('Fmin Search Optimization');
lgn = {'Ground Truth' , 'Initial Guess' , 'Optimized Prediction'};
title(ttl, 'FontSize', 8);
legend(lgn, 'Location', 'southwest', 'FontSize', 8);

hold off;
out = false;
end
