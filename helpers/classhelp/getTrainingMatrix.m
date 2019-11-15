function [gIdx, sIdx, hIdx] = getTrainingMatrix(Ein, crc)
%% getTrainingMatrix: extract the training matrix indices from trained data
%
%
%

%% 
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

end


