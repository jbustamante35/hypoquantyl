
function [X] = pullFront(X,dim)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % shift right -ndims must be three
    extraDIM = 0;
    if size(X,ndims(X)) == 1;extraDIM = 1;end
    X = shiftdim(X,-1);
    szX = [size(X) , ones(1,extraDIM)];
    tmpX = dim+1;
    % get the numbered index array
    permX = 1:numel(szX);
    % permute
    permX([1,tmpX]) = permX(flip([1,tmpX],2)); 
    % remove the spot left from permute from size - squeeze out one dim
    szX([1,tmpX]) = szX(flip([1,tmpX],2));
    szX(tmpX) = [];
    % perform permutation
    X = permute(X,permX);
    % reshape to squeeze out one single dim
    X = reshape(X,szX);
end
