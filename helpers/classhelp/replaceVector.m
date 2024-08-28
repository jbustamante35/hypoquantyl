function vout = replaceVector(vin, vrep, vidx)
%% replaceVector: replace part of a vector
%
% Usage:
%   vout = replaceVector(vin, vrep, vidx)
%
% Input:
%   vin: input vector
%   vrep: replacement vector (default [])
%   vidx: index or indices to replace vector (default [1 , 3])
%
% Output:
%   vout: vector with segment replaced

if nargin < 2; vrep = [];      end
if nargin < 3; vidx = [1 , 3]; end

nv = numel(vidx);
switch nv
    case 1
        if ~isempty(vrep)
            vout = [vin(1 : vidx) , vrep];
        else
            % Replace with repmat 
            nr   = (numel(vin) - vidx + 1);
            vout = [vin(1 : vidx - 1) , repmat(vin(vidx), 1, nr)];
        end
    case 2
        if vidx(2) == numel(vin)
            % vout = [vin(1 : vidx(1)) , vrep];
            vout = replaceVector(vin, vrep, vidx(1));
        else
            vout = [vin(1 : vidx(1)) , vrep , vin(vidx(2) : end)];
        end

end
end