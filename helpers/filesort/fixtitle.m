function ttl = fixTitle(str)
%% Fix names of titles for plotting
ttl = strrep(str, '_', '|');
ttl = strrep(ttl, '^', '|');
end
