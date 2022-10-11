function sout = convertStruct(sinn, fout)
%% convertStruct: rename fieldnames in a structure
%
%
% Usage:
%   sout = convertStruct(sinn, fout)
%
% Input:
%   sinn: old structure
%   fout: fieldnames for new structure [must have same number of fields]
%
% Output:
%   sout: renamed structure
%

finn = fieldnames(sinn)';
for k = 1 : numel(finn)
    sout.(fout{k}) = sinn.(finn{k});
end
end