function [yimg , ydom] = performOperations(isrc, dsrc, dsp, rad, stc, vsrc, dsz, D, R, S)
%% performOperations
%
if nargin < 8; [S , R , D] = makeOperations; end

%
smat = S(stc(1),stc(2));
rmat = R(rad);
dmat = D(dsp(1),dsp(2));

%
xall = dmat * rmat * smat * dsrc';
% xall = rmat * smat * dsrc'; % Try without displacing to target
% xall = smat * dsrc'; % No displacement or rotation to target
ydom = [(xall(1:2,:)' + vsrc)' ; ones(1, size(xall, 2))];
yimg = ba_interp2(isrc, ydom(1,:), ydom(2,:));
yimg = reshape(yimg, dsz);
yimg = rot90(yimg);
end