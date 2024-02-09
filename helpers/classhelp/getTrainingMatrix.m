function [gidx, sidx, hidx] = getTrainingMatrix(Ein, crc, fmt)
%% getTrainingMatrix: extract the training matrix indices from trained data
% Description
%
% Usage:
%    [gidx, sidx, hidx] = getTrainingMatrix(Ein, crc, fmt)
%
% Input:
%    Ein: Experiment object to draw Curve from
%    crc: Curve object to extract training matrix
%    fmt: format for output [sep|cat] (defaults to sep - 3 separate outputs)
%
% Output:
%    gidx: index of Genotype object
%    sidx: index of Seedling object
%    hidx: index of Hypocotyl object
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%% Default to separate output format
if nargin < 3; fmt = 'sep'; end

% Extract indices
if numel(crc) > 1
    [gidx , sidx , hidx] = arrayfun(@(c) ...
        getIndices(Ein, c), crc, 'UniformOutput', 0);
    gidx                 = cat(1, gidx{:});
    sidx                 = cat(1, sidx{:});
    hidx                 = cat(1, hidx{:});
else
    [gidx , sidx , hidx] = getIndices(Ein, crc);
end

% Keep output separate or combine into one matrix
if strcmpi(fmt, 'cat'); gidx = [gidx , sidx , hidx]; end
end

function [gidx , sidx , hidx] = getIndices(Ein, crc)
%% Extract indices from a CircuitJB object
% Genotype Index
gstr = string(arrayfun(@(x) ...
    x.GenotypeName, Ein.combineGenotypes, 'UniformOutput', 0));
gidx = find(crc.GenotypeName == gstr);

% Seedling Index
aa   = '{';
bb   = '}';
sstr = crc.Parent.SeedlingName;
aidx = strfind(sstr, aa);
bidx = strfind(sstr, bb);
sidx = str2double(sstr(aidx + 1 : bidx - 1));

% Hypocotyl Frame
hidx = crc.getFrame;
end
