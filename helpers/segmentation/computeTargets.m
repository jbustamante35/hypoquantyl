function [dvecs, dsz] = computeTargets(trgs, zvecs, toShape, par)
%% computeTargets: compute vector displacements from tangent and frame bundles
%
%
% Usage:
%   [dvecs, dsz] = computeTargets(trgs, zvecs, toShape, par)
%
% Input:
%   trgs: target coordinates of a split contour
%   zvecs: tangent bundle containing midpoints-tangents-normals
%   toShape: reshape to vectorized size
%   par: boolean to run with parallelization (default false)
%
% Output:
%   dvecs: displacement vectors to serve as target values for a neural net
%   dsz: dimensions of resulting d-vectors
%

%%
if nargin < 4
    par = false;
end

%%
if par == 2
    %% Run with parallization
    nCrvs   = size(trgs,3);
    allCrvs = 1 : nCrvs;
    trgs    = arrayfun(@(y) trgs(:,:,y), allCrvs, 'UniformOutput', 0);
    zvecs   = arrayfun(@(z) zvecs(:,:,z), allCrvs, 'UniformOutput', 0);
    dvecs   = cell(1, nCrvs);
    parfor tr = allCrvs
        aff       = tb2affine(zvecs{tr}, [1 , 1], toShape);
        dvecs{tr} = computeDVector(aff, permute(trgs{tr}, [2 1]))';
    end
    
    dvecs = cat(3, dvecs{:});
    
else
    switch par
        case 0
            %% Single-thread but use from cell arrays
            nCrvs   = numel(trgs);
            allCrvs = 1 : nCrvs;
            nVecs   = size(zvecs{1},1);
            allVecs = 1 : nVecs;
            
            taff = cellfun(@(z) tb2affine(z, [1 , 1], toShape), ...
                zvecs, 'UniformOutput', 0);
            
            dvecs = cell(nCrvs, nVecs);
            for c = allCrvs
                for n = allVecs
                    dvecs{c,n} = (squeeze(taff{c}(n,:,:)) * trgs{c}(:,:,n)')';
                end
            end
            dvecs = cat(3, dvecs{:});
            
        otherwise
            %% Run with single-thread
            nCrvs   = size(trgs,3);
            allCrvs = 1 : nCrvs;
            dvecs   = zeros(size(trgs));
            for tr = allCrvs
                aff           = tb2affine(zvecs(:,:,tr), [1 , 1], toShape);
                dvecs(:,:,tr) = computeDVector(aff, permute(trgs(:,:,tr), [2 , 1]))';
            end
    end
end

%% Reshape to specific size
if toShape
    dvecs = permute(dvecs, [1 , 3 , 2]);
    dsz   = size(dvecs);
    dvecs = reshape(dvecs, [prod(dsz(1:2)) , prod(dsz(3))]);
else
    dsz = size(dvecs);
end

end

function dvecs = computeDVector(aff, trg)
%% computeDVector: compute displacement vectors in normalized frame
%
%
% Usage:
%   dvecs = computeDVector(aff, trg)
%
% Input:
%   aff: matrix to perform affine transform into normalized reference frame
%   trg: target coordinate to express in normalized reference frame
%
% Output:
%   dvecs: displacement vectors to target coordinate in normalized frame
%

%%
dvecs = zeros(size(trg));
for e = 1 : size(aff,1)
    taff       = squeeze(aff(e,:,:));
    dvecs(:,e) = taff * trg(:,e);
end

end
