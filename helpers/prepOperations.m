function [dsp , rad] = prepOperations(zsrc, midx)
% function [dsp , rad] = prepOperations(asrc, mtrg, midx)
%% prepOperations
if nargin < 3; midx = 1; end

dsp  = zsrc(midx,1:2) - zsrc(midx,1:2);
tsrc = zsrc(midx,3:4);
rad  = atan2(tsrc(2), tsrc(1));

% dsp  = mtrg(midx,:) - asrc(1:2);
% tsrc = asrc(3:4);
% rad  = atan2(tsrc(2),tsrc(1));
% zm   = curve2framebundle(mtrg);
% atrg = zm(midx,:);
% ttrg = atrg(3:4);
% rad  = atan2(ttrg(2),ttrg(1));

end