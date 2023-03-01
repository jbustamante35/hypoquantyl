function [cpre ,  mpre , zpre , bpre , gpre , citrs] = predictFromImage(img, bpredict, zpredict, cpredict, mline, mscore, bpre, zpre, toStruct, addbvec, cidx, ymin)
%% predictFromImage:
%
%
% Usage:
%   [cpre ,  mpre , zpre , bpre , gpre , citrs] = predictFromImage( ...
%       img, bpredict, zpredict, cpredict, mline, mscore, zpre, toStruct, ...
%       nobvec, cidx, ymin)
%
% Input:
%   img: image to predict [does not normalize]
%   bpredict: model to predict B-Vector
%   zpredict: model to predict Z-Vector
%   cpredict: model to predict contour
%   mline: function handle to generate midline from contour
%   mscore: function handle to score prediction
%   z: initial Z-Vector seed (must be B-Vector subtracted) [default []]
%   toStruct: if single output, store into structure [default 0]
%   addbvec: don't add back B-Vector to Z-Vector (when I screw up) [default 0]
%   cidx: index to use as label [turns on verbosity]
%   ymin: base rows to set as B-Vector [default 10]
%
% Output:
%   cpre:
%   mpre:
%   zpre:
%   bpre:
%   gpre:
%   citrs: contours from each recursive iteration [after smoothing]
%

%%
if nargin < 7;  bpre     = []; end
if nargin < 8;  zpre     = []; end
if nargin < 9;  toStruct = 0;  end
if nargin < 10; addbvec  = 1;  end
if nargin < 11; cidx     = 0;  end
if nargin < 12; ymin     = 10; end

% Grab lower section for B-Vector prediction
isz   = size(img,1);
wrows = isz - ymin : isz;

[~ , sprA , sprB]            = jprintf(' ', 0, 0, 80);
% [bpre ,  cpre , mpre , gpre] = deal([]);
[cpre , mpre , gpre] = deal([]);

% ---------------------------------------------------------------------------- %
try
    % Predict B-Vector or use provided
    if cidx; t = tic; n = fprintf('BVector [%03d]', cidx); end
    if isempty(bpre); bpre = bpredict(img, wrows, 0); end
    if cidx; jprintf('', toc(t), 1, 80 - sum(n)); end
catch e
    fprintf(2, '\n%s\nError predicting B-Vector\n%s\n%s\n%s\n\n', ...
        sprA, sprB, e.getReport, sprA);
end

% ---------------------------------------------------------------------------- %
try
    % Predict Z-Vector or use provided
    if cidx; t = tic; n = fprintf('ZVector [%03d]', cidx); end

    % Predict Z-Vector and add by B-Vector
    if isempty(zpre); zpre = zpredict(img, 0); end
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
    [cpre , ~ , citrs] = cpredict(img, zpre);
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
try
    % Grade prediction
    if cidx; t = tic; n = fprintf('Grade [%03d]', cidx); end
    gpre = mscore(img, mpre);
    if cidx; jprintf('', toc(t), 1, 80 - sum(n)); end
catch e
    fprintf(2, '\n%s\nError grading prediction\n%s\n%s\n%s\n\n', ...
        sprA, sprB, e.getReport, sprA);
end

% ---------------------------------------------------------------------------- %
% Store into structure
if toStruct
    cpre = struct('c', cpre, 'z', zpre, 'm', mpre, 'b', bpre, 'g', gpre);
    mpre = citrs;
end
end
