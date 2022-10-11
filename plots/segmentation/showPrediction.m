function showPrediction(img, hyp, fidx, ttl)
%% showPrediction: show results from hypocotyl segmentation
%
%
% Usage:
%   showPrediction(img, hyp, fidx, ttl)
%
% Input:
%   img:
%   hyp: output from segmentation [
try cpre = hyp.c;        catch; cpre = []; end
try mpre = hyp.m;        catch; mpre = []; end
try zpre = hyp.z(:,1:2); catch; zpre = []; end
try bpre = hyp.b;        catch; bpre = []; end

set(0, 'CurrentFigure', fidx);
myimagesc(img);
hold on;
plt(cpre, 'g-', 2);
plt(mpre, 'r-', 2);
plt(zpre, 'y.', 2);
plt(bpre, 'b.', 20);

title(ttl, 'FontSize', 10);
drawnow;
hold off;
end