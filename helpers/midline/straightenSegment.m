function crv = straightenSegment(crv, seg_lengths)
%% straightenSegment
%
%
% Usage:
%   crv = straightenSegment(crv, seg_lengths)
%
% Input:
%   crv:
%   seg_lengths
%
% Output:
%   cpre:
%

%%
% Index of top and bottom
L    = cumsum([1 , seg_lengths]);
sTop = crv(L(2) : L(3), :);
sBot = crv(L(4) : L(5)-1, :);

% Interpolate corners to segment lengths
fTop = interpolateOutline(sTop([1,end],:), size(sTop,1));
fBot = interpolateOutline(sBot([1,end],:), size(sBot,1));

% Replace with straightened sections
crv(L(2) : L(3),:)   = fTop;
crv(L(4) : L(5)-1,:) = fBot;

end

