function ttl = fixtitle(str, vsn)
%% fixtitle: Fix names of titles for plotting
% Set vsn to 'carrots' to use for CarrotSweeper plotting, leave empty for most
% other uses.
if nargin < 2; vsn = 'carrots'; end

switch vsn
    case 'carrots'
        ttl = strrep(str, '_', '\_');
        ttl = strrep(ttl, '^', '\^');
        ttl = strrep(ttl, '{', '|');
        ttl = strrep(ttl, '}', '|');
        ttl = strrep(ttl, '+', ' ');
    case 'hypoquantyl'
        ttl = strrep(str, '_', '|');
        ttl = strrep(ttl, '^', '|');
    case 'other'
        ttl = strrep(str, '_', ' ');
        ttl = strrep(ttl, '^', '\^');
        ttl = strrep(ttl, '{', '|');
        ttl = strrep(ttl, '}', '|');
        ttl = strrep(ttl, '+', ' ');
    case 'file'
        ttl = strrep(str, ' ', '_');
end
end
