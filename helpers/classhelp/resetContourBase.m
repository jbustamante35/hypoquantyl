function [bnrm , ridx , bcrd, b] = resetContourBase(trc)
%% resetContourBase: normalize contour to set center of base to origin
% Get base
lbl  = labelContour(trc);
b    = trc(lbl,:);
bidx = ceil(size(b,1) / 2);
bcrd = b(bidx,:);

bfind = trc == bcrd;
rfind = arrayfun(@(x) find(bfind(:,x) == 1), 1 : 2, 'UniformOutput', 0);
ridx  = rfind{2}(ismember(rfind{2}, rfind{1}));

% Reset coordinates (first remove closing coordinate)
trc   = trc(1 : end-1,:);
bzero = trc - bcrd;
bshft = -ridx + 1;
bnrm  = circshift(bzero, bshft);
bnrm  = [bnrm ; bnrm(1,:)];

end