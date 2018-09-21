function structOut = struct2logical(structIn)
%% struct2logical: find empty data in all fields of a structure
% This function iterates through each field of a structure or structure array and outputs a
% structure defining which fields have non-empty data.
% 
% Usage:
%   structOut = struct2logical(structIn)
%
% Input:
%   structIn: structure or structure array to check for empty fields 
%
% Output:
%   structOut: single structure with matching fields containing logical indices of non-empty data 
%

% Set up anonymous functions
catCell   = @(x) cat(1, x)';
emptChk   = @(y) cellfun(@(x) ~isempty(x), y, 'UniformOutput', 0);
chkStruct = @(x) cell2mat(emptChk(catCell(x)));

% Run logical check function iteratively through each field 
for fn = fieldnames(structIn)'
    fname             = string(fn(~isspace(fn)));
    structOut.(fname) = chkStruct({structIn.(fname)});
end

end