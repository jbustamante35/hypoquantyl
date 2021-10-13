function [fnm , mcc , p] = showHypocotylPrediction(img, cpre, ctru, fidx, cidx, nflts, tset, zpre, zgrade, zcnv)
%% showHypocotylPredictions: visualization to show 2-step neural net result
%
%
% Usage:
%   [fnm , mcc , p] = showHypocotylPrediction( ...
%       img, cpre, ctru, fidx, cidx, nflts, tset, zpre, zgrade, zcnv)
%
% Input:
%   img: image used for predictor
%   cntr: contour predicted from image
%
% Output:
%   fnm: Figure name for saving later
%   mcc: Matthew's Corellation Coefficient of contour
%   p: Probability of Z-Vector PC scores
%

%%
% [mtru , mpre , mcc , p] = deal([]);
% if ~isempty(ztru); mtru = ztru(:,1:2); end
% if ~isempty(zpre); mpre = zpre(:,1:2); end

[fnm , mcc , p] = deal([]);
% Matthew's Corellation Coefficient of contour
if ~isempty(ctru)
    isz = size(img);
    mcc = computeMatthewsCorellation(ctru, cpre, isz);
end

% Probability of Z-Vector PC scores
if ~isempty(zgrade) && ~isempty(zcnv) && ~isempty(zpre)
    scr = zcnv(zpre);
    p   = zgrade(scr);
end

%% Show predictions (fidx > 0) or Just compute MCC and Probability (fidx = 0)
if fidx
    figclr(fidx);
    myimagesc(img);
    hold on;
    plt(ctru, 'b-', 2);
    plt(cpre, 'g-', 2);
    % plt(mtru, 'r.', 3);
    % plt(mpre, 'y.', 3);
    
    if ~isempty(ctru)
        lgn = {'Ground Truth' , 'Predicted'};
    else
        lgn = 'Predicted';
    end
    
    if ~isempty(mcc) && ~isempty(p)
        % Both mcc and p
        ttl = sprintf('Curve %d of %d [%s set]\nMCC %.03f | P %.03f', ...
            cidx, nflts, tset, mcc, p);
    elseif isempty(mcc) && ~isempty(p)
        % Only p [no mcc]
        ttl = sprintf('Curve %d of %d [%s set]\nP %.03f', ...
            cidx, nflts, tset, p);
    else
        ttl = sprintf('Curve %d of %d [%s set]', cidx, nflts, tset);
    end
    
    legend(lgn, 'FontSize', 10, 'Location', 'southeast');
    title(ttl, 'FontSize', 10);
    
    drawnow;
    
    % Store figure name to save later
    fnm = sprintf('%s_predictions_clip_left_filtered_curve%03dof%03d_%s', ...
        tdate, cidx, nflts, tset);
end
end
