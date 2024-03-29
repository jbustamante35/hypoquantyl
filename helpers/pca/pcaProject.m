function S = pcaProject(vec, eigs, mns, req, n)
%% pcaProject: project PCA data from scores to simulated data or vice versa
% This function generates simulated data by the following computation:
%   (X * Y') + Z
%
% where X -> principal component scores
%       Y -> eigenvectors
%       Z -> dataset means to add back to translate to original reference frame
%
% Usage:
%   S = pcaProject(scrs, eigs, mns, req, dims)
%
% Input:
%   vec: vector of either inputted data or PC scores
%   eigs: [n x m] matrix representing eigenvectors
%   mns:  [1 x n] means array to add back to original reference frame
%   req: project to simulated data ('scr2sim') or to PC scores ('sim2score')
%   dims: dimensions to compute on
%
% Output:
%   S: [1 x n] array of simulated data or PC scores
%

%%
if nargin < 4; req  = []; end
if nargin < 5; n = ':';   end

vec     = vec(n, :);
scr2sim = 'scr2sim';
sim2scr = 'sim2scr';

% Determine projection direction
if isempty(req)
    if size(vec,2) == size(eigs,1)
        % Vector is in input space
        req = 'sim2scr';
    elseif size(vec,2) == size(eigs,2)
        % Vector is in pc space
        req = 'scr2sim';
    else
        % Try vectorizing and transposing vector
        vec = vec(:)';
        req = 'sim2scr';
    end
end

% Perform projection
switch req
    case scr2sim
        S = ((vec * eigs') + mns);
    case sim2scr
        S = (vec - mns) * eigs;
    otherwise
        fprintf(2, 'Parameter ''req'' must be [%s|%s] (%s)\n', ...
            scr2sim, sim2scr, req);
        S = [];
        return
end
end
