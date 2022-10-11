function [fnm , mcc , p] = showCurve(img, cpre, ctru, fidx, n, N, tset, zpre, zgrade, zcnv, lgn)
%% showCurve: visualization to show curve on image with extras
%
%
% Usage:
%   [fnm , mcc , p] = showCurve( ...
%       img, cpre, ctru, fidx, n, N, tset, zpre, zgrade, zcnv)
%
% Input:
%   img: image used for predictor
%   cpre: curve predicted from image
%   ctru: ground truth curve
%   fidx: index to figure handle
%   n: index of curve into dataset
%   N: total curves in dataset
%   tset: set from training (default '')
%   zpre: predicted Z-Vector to grade prediction (default [])
%   zgrade: prediction grading function (default [])
%   zcnv: function to convert Z-Vector from vectorized form (default [])
%   lgn: toggle display of legend [default 0]
%
% Output:
%   fnm: Figure name for saving later
%   mcc: Matthew's Corellation Coefficient of contour
%   p: Probability of Z-Vector PC scores
%

%%
if nargin < 4;  fidx   = 0;  end
if nargin < 5;  n      = 0;  end
if nargin < 6;  N      = 0;  end
if nargin < 7;  tset   = ''; end
if nargin < 8;  zpre   = []; end
if nargin < 9;  zgrade = []; end
if nargin < 10; zcnv   = []; end
if nargin < 11; lgn    = 0;  end

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
if ~isempty(fidx)
    if fidx; figclr(fidx); end
    myimagesc(img);
    hold on;
    plt(ctru, 'b-', 2);
    plt(cpre, 'g-', 2);

    % Generate Legend
    if lgn
        if ~isempty(ctru)
            lgn = {'Ground Truth' , 'Predicted'};
        else
            lgn = 'Predicted';
        end
    end

    % Append total in dataset
    if N; nstr = sprintf('%d of %d', n, N);
    else; nstr = sprintf('%d', n); end

    % Append set name
    if ~isempty(tset); nstr = sprintf('%s [%s]', nstr, tset); end

    % Generate title
    if ~isempty(mcc) && ~isempty(p)
        % Both mcc and p
        ttl = sprintf('Curve %s\nMCC %.03f | P %.03f', nstr, mcc, p);
    elseif isempty(mcc) && ~isempty(p)
        % Only p [no mcc]
        ttl = sprintf('Curve %s\nP %.03f', nstr, p);
    elseif ~isempty(mcc) && isempty(p)
        % Only mcc [no p]
        ttl = sprintf('Curve %s\nMCC %.03f', nstr, mcc);
    else
        % Only curve index
        ttl = sprintf('Curve %s', nstr);
    end

    if lgn; legend(lgn, 'FontSize', 10, 'Location', 'southeast'); end
    title(ttl, 'FontSize', 10);

    drawnow;

    % Store figure name to save later
    fnm = sprintf('%s_curveonimage_curve%03dof%03d_%s', ...
        tdate, n, N, tset);
end
end
