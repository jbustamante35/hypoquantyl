function S = input2sim(scrs, eigs, mns)
%% input2sim: convert input data to simulated data from PCA
% This function generates simulated data by the following computation:
%   (X * Y') + Z
%
% where X -> principal component scores
%       Y -> eigenvectors
%       Z -> dataset means to add back to translate to original reference frame
%
% Usage:
%   S = input2sim(scrs, eigs, mns)
%
% Input:
%   scrs: [1 x m] array of principal component (PC) scores
%   eigs: [n x m] matrix representing eigenvectors
%   mns:  [1 x n] means array to add back to original reference frame
%
% Output:
%   S: [1 x n] array of simulated data
%

S = ((scrs * eigs') + mns);

end