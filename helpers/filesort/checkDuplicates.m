function [didx , dchk , dvec] = checkDuplicates(idxs)
%% checkDuplicates
%
% Usage:
%   checkDuplicates(uidxs)
%
% Input:
%   idxs: vector (single or by rows) to check
%
% Output:
%   didx: indices of duplicates
%   dchk: check result [no duplicates (0) | has duplicates (1)]
%   dvec: duplicated result

[dun , dor] = unique(idxs, 'rows', 'first');
dchk        = size(dun,1) < size(idxs,1);
didx        = setdiff(1 : size(idxs,1), dor);
dvec        = idxs(didx,:);
end