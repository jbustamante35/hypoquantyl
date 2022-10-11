function [cpre ,  mpre , zpre , bpre] = predictFromImage(img, bpredict, zpredict, cpredict, mline, zpre, toStruct, addbvec, cidx, ymin)
%% predictFromImage:
%
%
% Usage:
%   [cpre ,  mpre , zpre , bpre] = predictFromImage( ...
%       img, bpredict, zpredict, cpredict, mline, zpre, toStruct, nobvec, cidx, ymin)
%
% Input:
%   img:
%   bpredict:
%   zpredict:
%   cpredict:
%   mline:
%   z:
%   toStruct: if single output, store into structure [default 0]
%   addbvec: don't add back B-Vector to Z-Vector (when I screw up) [default 0]
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
if nargin < 6;  zpre     = []; end
if nargin < 7;  toStruct = 0;  end
if nargin < 8;  addbvec  = 1;  end
if nargin < 9;  cidx     = 0;  end
if nargin < 10; ymin     = 10; end

% Grab lower section for B-Vector prediction
isz   = size(img,1);
wrows = isz - ymin : isz;

[~ , sprA , sprB]     = jprintf(' ', 0, 0, 80);
[bpre ,  cpre , mpre] = deal([]);

% ---------------------------------------------------------------------------- %
try
    % Predict B-Vector
    if cidx; t = tic; n = fprintf('BVector [%03d]', cidx); end
    bpre = bpredict(img,wrows,0);
    if cidx; jprintf('', toc(t), 1, 80 - sum(n)); end
catch e
    fprintf(2, '\n%s\nError predicting B-Vector\n%s\n%s\n%s\n\n', ...
        sprA, sprB, e.getReport, sprA);
end

% ---------------------------------------------------------------------------- %
try
    % Predict Z-Vector or use provided
    if cidx; t = tic; n = fprintf('ZVector [%03d]', cidx); end
    if isempty(zpre)
        % Predict Z-Vector and add by B-Vector
        zpre = zpredict(img,0);
    end
    % zpre = [zpre(:,1:2) + bpre , zpre(:,3:4) , zpre(:,5:6)];
    if addbvec; zpre = [zpre(:,1:2) + bpre , zpre(:,3:end)]; end
    if cidx; jprintf('', toc(t), 1, 80 - sum(n)); end
catch e
    fprintf(2, '\n%s\nError predicting Z-Vector\n%s\n%s\n%s\n\n', ...
        sprA, sprB, e.getReport, sprA);
end

% ---------------------------------------------------------------------------- %
try
    % Predict contour
    if cidx; t = tic; n = fprintf('DVector [%03d]', cidx); end
    cpre = cpredict(img, zpre);
    if cidx; jprintf('', toc(t), 1, 80 - sum(n)); end
catch e
    fprintf(2, '\n%s\nError predicting D-Vector\n%s\n%s\n%s\n\n', ...
        sprA, sprB, e.getReport, sprA);
end

% ---------------------------------------------------------------------------- %
try
    % Generate midline
    if cidx; t = tic; n = fprintf('Midline [%03d]', cidx); end
    mpre = mline(cpre);
    if cidx; jprintf('', toc(t), 1, 80 - sum(n)); end
catch e
    fprintf(2, '\n%s\nError generating midline\n%s\n%s\n%s\n\n', ...
        sprA, sprB, e.getReport, sprA);
end

% ---------------------------------------------------------------------------- %
% Store into structure
if toStruct
    %         cpre = struct('cpre', cpre, 'zpre', zpre, 'mpre', mpre, 'bpre', bpre);
    cpre = struct('c', cpre, 'z', zpre, 'm', mpre, 'b', bpre);
end
end
