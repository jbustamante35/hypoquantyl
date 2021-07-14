function c = empty2nan(c, val)
%% empty2nan: set all empty cells in a cell array to a specific value
% This was initially written to replace all NaN cells in the RawSeedlings of a
% Genotype with Seedling objects with the name 'empty'. This allowed me to run
% the algorithm that aligns Seedling objects in one frame with the Seedling
% object in the following frame based on the closest matching coordinate.
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