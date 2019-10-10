function dst = measureBase(crv)
%% measureBase: measure the length of the base of a curve
% This function gets the euclidean distance between end points of a curve
%
% Usage:
%   dst = measureBase(crv)
%
% Input:
%   crv: coordinates of a curve
%
% Output:
%   dst: euclidean distance in pixels between end points of the curve

%% Label the lowest points of the curve
lab = labelContour(crv);

%%
len = size(crv,1);
tmp = [crv' , crv' , crv']';

%
dc = gradient(tmp')';
dl = sum(dc .* dc, 2).^0.5;

%
dl  = dl(len+1 : 2*len, :);
dst = sum(dl .* lab);

end

