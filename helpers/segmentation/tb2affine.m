function aff = tb2affine(tb, scls, affineInvert)
%% tb2affine: scaling affine transformation for a tangent bundle [Z-Vector]
% Runs the affine transformation to create the patches
%
% Usage:
%   aff = tb2affine(tb, scls, isInverted)
%
% Input:
%   tb: tangent bundle of [N x 6] size (midpoint-tangent-normal)
%   scls: scaling factors of size [n x m] used to generate domains
%   affineInvert: return inversion of the affine transformation
%
% Output:
%   aff: affine transformation of all the points of the tangent bundle
%

if nargin < 3
    affineInvert = false;
end

for e = 1 : size(tb,1)
    % Force tangents and normals to be unit length vectors
    mid = tb(e,1:2);
    %     tng = tb(e,3:4) - mid;
    tng = tb(e,3:4);
    tng = tng / norm(tng);
    %     nrm = tb(e,5:6) - mid;
    nrm = tb(e,5:6);
    nrm = nrm / norm(nrm);
    
    % Run affine transformation for all tangent points for all scales
    baseaffine = [[tng , 0]' , [nrm , 0]' , [mid , 1]'];
    for s = 1 : size(scls,1)
        st  = diag([scls(s,:) , 1]);
        tmp = baseaffine * st;
        
        % Return the inverse of the transformation
        if affineInvert
            tmp = inv(tmp);
        end
        
        aff(e,:,:,s) = tmp;
        
        
    end
    
end

end

