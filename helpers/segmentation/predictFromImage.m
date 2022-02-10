function [cpre ,  mpre , zpre , bpre] = predictFromImage(img, bpredict, zpredict, cpredict, mline, zpre, cidx, ymin)
%% predictFromImage:
%
%
% Usage:
%   [cpre ,  mpre , zpre , bpre] = predictFromImage( ...
%       img, bpredict, zpredict, cpredict, mline, z, cidx, ymin)
%
% Input:
%   img:
%   bpredict:
%   zpredict:
%   cpredict:
%   mline:
%   z:
%   cidx:
%   ymin:
%
% Output:
%   cpre:
%   mpre:
%   zpre:
%   bpre:
%

%%
if nargin < 6; zpre  = []; end
if nargin < 7; cidx  = 0;  end
if nargin < 8; ymin  = 10; end

%
isz   = size(img,1);
wrows = isz - ymin : isz;

% Predict B-Vector
if cidx; t = tic; n = fprintf('BVector [%03d]', cidx); end
bpre = bpredict(img,wrows,0);
if cidx; jprintf('', toc(t), 1, 80 - sum(n)); end

% Predict Z-Vector or use provided
if cidx; t = tic; n = fprintf('ZVector [%03d]', cidx); end
if isempty(zpre)
    % Predict Z-Vector and add by B-Vector
    zpre = zpredict(img,0);
end
zpre = [zpre(:,1:2) + bpre , zpre(:,3:4) , zpre(:,5:6)];
if cidx; jprintf('', toc(t), 1, 80 - sum(n)); end

% Predict contour
if cidx; t = tic; n = fprintf('DVector [%03d]', cidx); end
cpre = cpredict(img, zpre);
if cidx; jprintf('', toc(t), 1, 80 - sum(n)); end

% Generate midline
if cidx; t = tic; n = fprintf('Midline [%03d]', cidx); end
mpre = mline(cpre);
if cidx; jprintf('', toc(t), 1, 80 - sum(n)); end
end
