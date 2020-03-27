function [gIdx, sIdx, hIdx] = getTrainingMatrix(Ein, crc, fmt)
%% getTrainingMatrix: extract the training matrix indices from trained data
% Description
%
% Usage:
%    [gIdx, sIdx, hIdx] = getTrainingMatrix(Ein, crc, fmt)
%
% Input:
%    Ein: Experiment object to draw Curve from
%    crc: Curve object to extract training matrix
%    fmt: format for output [sep|cat] (defaults to sep - 3 separate outputs)
%
% Output:
%    gIdx: index of Genotype object
%    sIdx: index of Seedling object
%    hIdx: index of Hypocotyl object
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%% Default to separate output format
if nargin < 3
    fmt = 'sep';
end

% Genotype Index
gStr = ...
    string(arrayfun(@(x) x.GenotypeName, Ein.combineGenotypes, 'UniformOutput', 0));
gIdx = find(crc.GenotypeName == gStr);

% Seedling Index
aa = '{';
bb = '}';
sStr = crc.Parent.SeedlingName;
aIdx = strfind(sStr, aa);
bIdx = strfind(sStr, bb);
sIdx = str2double(sStr(aIdx+1:bIdx-1));

% Hypocotyl Frame
hIdx = crc.getFrame;

if strcmpi(fmt, 'cat')
    gIdx = [gIdx , sIdx , hIdx];
end

end


