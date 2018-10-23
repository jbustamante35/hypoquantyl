function c = empty2nan(c, val)
%% empty2nan: set all empty cells in a cell array to given value
% This function was initially written for replacing all NaN cells in a Genotype object's
% RawSeedlings property with Seedling objects with the name 'empty'. This allowed me to run the
% filtering algorithm to align Seedling objects in one frame with the Seedling object in the 
% following frame with the closest matching coordinate. 
% 
% Usage:
%   c = empty2nan(c, val)
%
% Input:
%   c: cell array to replace NaN values
%   val: value to replace NaNs in cell array c
%
% Output:
%   c: inputted cell array with replaced NaN values

c(cellfun(@isempty, c)) = {val};

end