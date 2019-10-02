function S = pcaProject(vec, eigs, mns, req)
%% pcaProject: project PCA data from scores to simulated data or vice versa
% This function generates simulated data by the following computation:
%   (X * Y') + Z
%
% where X -> principal component scores
%       Y -> eigenvectors
%       Z -> dataset means to add back to translate to original reference frame
%
% Usage:
%   S = pcaProject(scrs, eigs, mns, req)
%
% Input:
%   vec: vector of either inputted data or PC scores
%   eigs: [n x m] matrix representing eigenvectors
%   mns:  [1 x n] means array to add back to original reference frame
%   req: project to simulated data ('scr2sim') or to PC scores ('sim2score')
%
% Output:
%   S: [1 x n] array of simulated data or PC scores
%

scr2sim = 'scr2sim';
sim2scr = 'sim2scr';
switch req
    case scr2sim
        S = ((vec * eigs') + mns);
    case sim2scr
        S = (vec - mns) * eigs;
    otherwise
        fprintf(2, 'Parameter ''req'' must be [%s|%s]\n', scr2sim, sim2scr);
        S = [];
        return
end

end
