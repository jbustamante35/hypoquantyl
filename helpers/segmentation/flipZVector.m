function [z , b] = flipZVector(z, sld)
%% flipZVector:
%
% Usage:
%   [z , b] = flipZVector(z, sld)
%
% Input:
%   z:
%   sld:
%
% Output:
%   z:
%

if nargin < 2; sld = 51; end

% Flip Z-Vector if first pass was flipped
% z = [z(:,1:2) + bseed , z(:,3:end)];
zm = z(:,1:2);
zt = z(:,3:4) + zm;
zn = z(:,5:6) + zm;
fm = flipLine(zm, sld);
ft = flipLine(zt, sld) - fm;
fn = flipLine(zn, sld) - fm;
b  = mean(fm(labelContour(fm), :), 1);

z = [fm - b , ft , fn];
end