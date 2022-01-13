function [cpre ,  mpre , zpre , bpre] = predictFromImage(img, bpredict, zpredict, cpredict, mline, ymin, cidx)
%% predictFromImage:
%
%
% Usage:
%   [cpre ,  mpre , zpre , bpre] = predictFromImage( ...
%       img, bpredict, zpredict, cpredict, mline, ymin, cidx)
%
% Input:
%
%
% Output:
%
%

%%
if nargin < 6; ymin  = 10; end
if nargin < 7; cidx  = 0;  end

%
isz   = size(img,1);
wrows = isz - ymin : isz;

%
if cidx; t = tic; n = fprintf('BVector [%03d]', cidx); end
bpre = bpredict(img,wrows,0);
if cidx; jprintf('', toc(t), 1, 80 - sum(n)); end

%
if cidx; t = tic; n = fprintf('ZVector [%03d]', cidx); end
zpre = zpredict(img,0);
zpre = [zpre(:,1:2) + bpre , zpre(:,3:4) , zpre(:,5:6)];
if cidx; jprintf('', toc(t), 1, 80 - sum(n)); end

%
if cidx; t = tic; n = fprintf('DVector [%03d]', cidx); end
cpre = cpredict(img, zpre);
if cidx; jprintf('', toc(t), 1, 80 - sum(n)); end

%
if cidx; t = tic; n = fprintf('Midline [%03d]', cidx); end
mpre = mline(cpre);
if cidx; jprintf('', toc(t), 1, 80 - sum(n)); end
end
