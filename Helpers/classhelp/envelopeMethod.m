function env = envelopeMethod(seg, sz)
%% envelopeMethod: subfunction for generateing EnvelopeSegments
% This function converts normalized segment coordinates to its coordainte within within
% that segment. The [1 2] coordinates outputted correspond to the normalized distance
% between starting and ending points (1) and the distance from the center line.

dist2ends = ((1 : length(seg)) / length(seg))';

de = @(s,e,o) o * (s - e) / norm(s - e);
off = de(seg(1,:), seg(end,:), sz) ;
augL = seg - off;
augR = seg + off;


dist2center = pdist(seg);
env = [dist2ends dist2center];

end