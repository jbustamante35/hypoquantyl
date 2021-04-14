function Z = zVectorConversion(z, ttlSegs, numCrvs, method, rtyp, rpos)
%% zVectorConversion: prep Z-Vector for PCA or reconstruct from CNN output
% This function reshapes and transposes the Z-Vector into the proper shape for
% PCA, or reconstructs the original Z-Vector shape. The reshaping method is
% determined by the 'method' parameter.
%
% Usage:
%   Z = zVectorConversion(z, ttlSegs, numCrvs, method, rtyp, rpos)
%
% Input:
%   z: Z-Vector shaped for either conversion or reconstruction
%   ttlSegs: number of segments per object
%   numCrvs: total number of objects in the dataset
%   method: (see below)
%   rtyp: convert rotation to degrees or radians [deg|rad] (default 'rad')
%   rpos: convert rotations to positive values (default 1)
%
%       arguments for method:
%           [prep] prepare for PCA by vectorizing slices
%           [rev ] revert to original shape with rows as slices
%           [rot ] convert tangent to rotation, or vice versa
%
% Output:
%   Z: converted Z-Vector
%
% NOTE:
%   The hard-coded column orders will need to change when I replace the
%   tangent-normal vectors with a rotation vector

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
            rZ    = arrayfun(@(x) reshape(z(:,x), [cSz , rSz])', ...
                1 : nDims, 'UniformOutput', 0);
            
            switch nDims
                case 1
                    % Only rotations
                    Z = cat(2, rZ{:});
                case 2
                    % Only midpoints or tangents
                    Z = cat(2, rZ{[1 , 2]});
                case 3
                    % Using rotation vector instead of tangent-normal
                    Z = cat(2, rZ{[1 , 2 , 3]});
                case 4
                    % If omitting Normal vectors
                    Z = cat(2, rZ{[1 3 , 2 4]});
                case 6
                    % Concat all Z-Vector dimensions
                    Z = cat(2, rZ{[1 3 5 , 2 4 6]});
            end
            
        case 'rev'
            %% Reconstruct PCA shape back into original shape
            % Extract indices for all dimensions
            idx1   = @(x) 1 + (ttlSegs * (x - 1));
            idx2   = @(x) (x * ttlSegs);
            
            ndims = size(z,2) / ttlSegs;
            switch ndims
                case 1
                    % Only rotations
                    zOrder = 1;
                case 2
                    % Only midpoints or tangents
                    zOrder = [1 , 2];
                case 3
                    % Rotation vectors
                    zOrder = [1 , 2 , 3];
                case 4
                    % If omitting Normal vectors
                    zOrder = [1 3 , 2 4];
                case 6
                    % Reverting all Z-Vector dimensions
                    zOrder = [1 4 , 2 5 , 3 6];
                otherwise
                    fprintf(2, 'Error with %d dimensions\n', ndims);
                    Z = [];
                    return;
            end
            
            cnvIdx = arrayfun(@(x) idx1(x) : idx2(x), ...
                zOrder, 'UniformOutput', 0);
            
            % Linearizes each field into separate columns
            catCrd    = @(x) x(:);
            cnvZ      = @(y) cellfun(@(x) catCrd(y(:, x)'), ...
                cnvIdx, 'UniformOutput', 0);
            cnvMethod = @(x) cell2mat(cnvZ(x));
            
            % Perform conversion
            Z = cnvMethod(z);
            
        case 'rot'
            %% Convert tangent vector to rotation vector, or vice versa
            switch nargin
                case 4
                    rtyp = 'rad';
                    rpos = 1;
                case 5
                    rpos = 1;
            end
            
            if size(z,2) >= 4
                m = z(:,1:2);
                t = z(:,3:4);
                r = arrayfun(@(x) tangent2rotation(t(x,:), 't2r', rtyp, rpos), ...
                    1 : size(t,1), 'UniformOutput', 0);
                r = cat(1, r{:});
                Z = [m , r];
                
            else
                m = z(:,1:2);
                r = z(:,3);
                t = arrayfun(@(x) tangent2rotation(r(x,:), 'r2t', rtyp, rpos), ...
                    1 : size(r,1), 'UniformOutput', 0);
                t = cat(1, t{:});
                
                % Add normal vector
                n = addNormalVector(m, t, 0, 1);
                Z = [m , t , n];
            end
            
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

function r = tangent2rotation(tng, drc, rtyp, rpos)
%% tangent2rotation: convert tangent vector to rotation, or vice versa
% Inputs:
%   tng: tangent or rotation vector
%   drc: conversion direction [t2r|r2t] (default t2r)
%   rtyp: keep rotation in degrees or radians [deg|rad] (default rad)
%   rpos: convert negative degrees to positive [only if deg = 'deg'] (default 1)

switch nargin
    case 1
        drc  = 't2r';
        rtyp = 'rad';
        rpos = 1;
    case 2
        rtyp = 'rad';
        rpos = 1;
    case 3
        rpos = 1;
    case 4
end

switch drc
    case 't2r'
        switch rtyp
            case 'rad'
                % Keep in radians
                r = atan2(tng(2), tng(1));
                
            case 'deg'
                % Convert to degrees [0 to +/- 180]
                r = rad2deg(atan2(tng(2), tng(1)));
                
                if rpos
                    % Convert negative rotations to >180
                    if r < 0
                        r = 360 + r;
                    end
                end
                
            otherwise
                fprintf(2, 'Error with conversion type %s [rad|deg]\n', rtyp);
                r = [];
                return;
        end
        
    case 'r2t'
        switch rtyp
            case 'rad'
                % Keep rotation matrix operation in radians
                rad = 1;
            case 'deg'
                rad = 0;
                
                % Convert rotations > 180 to negative rotations
                if tng >= 180
                    tng = tng - 360;
                end
        end
        
        r = arrayfun(@(x) [1 , 0] * Rmat(tng(x,:), rad), ...
            1 : size(tng,1), 'UniformOutput', 0);
        r = cat(1, r{:});
        
    otherwise
        fprintf(2, 'Error with conversion direction %s [t2r|r2t]\n', drc);
        r = [];
end

end

