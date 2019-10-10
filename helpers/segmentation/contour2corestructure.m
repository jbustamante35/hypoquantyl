function [Z , L, segs, lab] = contour2corestructure(cntr, len, step)
%% contour2corestructure: create the tangent bundle of a contour
%
%
%
% Label contour
lab = labelContour(cntr);

% Split contour into segments
segs = split2Segments(cntr, len, step, 'new');
lab  = split2Segments(lab, len, step, 'new');

% Get Tangent Bundle and Displacements along bundle in the tangent frame
coref1  = squeeze(segs(end,:,:) - segs(1,:,:));
mid     = squeeze(segs(1,:,:)) + 0.5 * coref1;
coremag = sum(coref1 .* coref1, 1).^-0.5;
coref1  = bsxfun(@times, coref1, coremag)';
coref2  = [coref1(:,2) , -coref1(:,1)];
Z       = [mid' , coref1 , coref2];

% Distance between anchor points
L = (coremag.^-1)';

end