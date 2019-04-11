function Z = zVectorConversion(z, ttlSegs, numCrvs, method)
%% zVectorConversion: prep Z-Vector for PCA or reconstruct from CNN output
% This function reshapes and transposes the Z-Vector into the proper shape for
% PCA, or reconstructs the original Z-Vector shape. The reshaping method is
% determined by the 'method' parameter.
%
% Usage:
%   Z = zVectorConversion(z, ttlSegs, numCrvs, method)
%
% Input:
%   z: Z-Vector shaped for either conversion or reconstruction
%   ttlSegs: number of segments per object
%   numCrvs: total number of objects in the dataset
%   method: 'prep' to prepare for PCA, or 'rev' to revert to original shape
%
% Output:
%   Z: converted Z-Vector
%

%% Determine method and reshape appropriately
try
    switch method
        case 'prep'
            %% Prepare for PCA
            % Reshape 1 section at a time then concatenate into shape for PCA
            nDims = size(z, 2);
            Z     = zeros(numCrvs , (ttlSegs * nDims));
            rSz   = size(Z, 1);
            cSz   = size(Z, 2) / nDims;
            
            rZ    = arrayfun(@(x) reshape(z(:,x), [cSz rSz])', ...
                1:nDims, 'UniformOutput', 0);
            Z     = cat(2, rZ{[1 3 5 2 4 6]});
            
        case 'rev'
            %% Reconstruct PCA shape back into original shape
            % Extract indices for all dimensions
            idx1   = @(x) 1 + (ttlSegs * (x - 1));
            idx2   = @(x) (x * ttlSegs);
            zOrder = [1 4 , 2 5 , 3 6];
            cnvIdx = arrayfun(@(x) idx1(x) : idx2(x), ...
                zOrder, 'UniformOutput', 0);
            
            % Linearizes each field into separate columns
            catCrd    = @(x) x(:);
            cnvZ      = @(y) cellfun(@(x) catCrd(y(:, x)'), ...
                cnvIdx, 'UniformOutput', 0);
            cnvMethod = @(x) cell2mat(cnvZ(x));
            
            % Perform conversion
            Z = cnvMethod(z);
            
        otherwise
            %% No selection chosen
            % Returns empty vector
            Z = [];
    end
    
catch e
    fprintf('Error reshaping data\n%s\n', e.message);
    Z = [];
end


end