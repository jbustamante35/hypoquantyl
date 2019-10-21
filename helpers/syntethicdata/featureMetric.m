function met = featureMetric(crv, frm)
%% featureMetric: measure features of a curve
% This function measures various features of an inputted curve. The current
% features we measure are:
%   Perimiter(P): length around the curve
%   Area(A): area the curve surrounds
%   Angle(Ang): angle of the curve
%   X-Mean(Xm): mean value of the X-coordinates
%   Y-Mean(Ym): mean value of the Y-coordinates
%
% So the output looks like:
%   [P , A , Ang , Xm , Ym]
%
% Usage:
%   met = featureMetric(crv, frm)
%
% Input:
%   crv: coordinates of a curve
%   frm: affine transformation frame
%
% Output:
%   met: feature metrics
%

%% Close the curve
if ~all(crv(1,:) == crv(end,:))
    crv = [crv ; crv(1,:)];
end

%% Perimeter
dl = diff(crv, 1, 1);
dl = sum(dl .* dl, 2).^0.5;
L  = sum(dl);

% Area
A = polyarea(crv(:,1), crv(:,2));

% PCA on curve (for obtaining angle and means)
cpc = 2;
pc  = myPCA(crv, cpc);

% inv(frm) * pc.EigVectors(:,1);
% atan2

E   = [pc.EigVectors(:,1) , -pc.EigVectors(:,1)];

% E   = [pc.EigVectors(:,1) , -pc.EigVectors(:,1) , ...
%     pc.EigVectors(:,2) , -pc.EigVectors(:,2)];

% Angle of the curve
nrm  = frm(:,2);
angl = min(nrm' * E);
angl = (acos(-angl) * 180) / pi;

% Project means into frame
mns = pc.MeanVals;

%% Store metrics in an array
met = [L ; A ; angl ; mns(1) ; mns(2)];

end


