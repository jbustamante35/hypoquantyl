function c = empty2nan(c, val)
%% empty2nan: set all empty cells in a cell array to given value
%
c(cellfun(@isempty, c)) = {val};

end