function ttl = fixtitle(str, ver)
%% fixtitle: Fix names of titles for plotting
% Set ver to 'carrots' to use for CarrotSweeper plotting, leave empty for most
% other uses.

if nargin > 1 && isequal(ver, 'carrots')
    ttl = strrep(str, '_', '\_');
    ttl = strrep(ttl, '^', '\^');
    ttl = strrep(ttl, '{', '|');
    ttl = strrep(ttl, '}', '|');
else
    ttl = strrep(str, '_', '|');
    ttl = strrep(ttl, '^', '|');
end
end
