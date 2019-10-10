function Y = prepareTargets(cntr, len, step)
%% prepareTargets:
%

segs   = split2Segments(cntr, len, step, 'new');
hlfIdx = ceil(size(segs,1) / 2);
Y      = [squeeze(segs(hlfIdx,:,:))' , ones(size(segs,3), 1)];

end

