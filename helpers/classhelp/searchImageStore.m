function img = searchImageStore(I, idx)
%% searchImageStore: returns images in an ImageDataStore at requested index or range of indices
% This function does a simple job and I'm getting to the point where I don't want to explain it in
% detail. I think it's pretty straight-forward.
%
% Usage:
%   img = searchImageStore(I, idx)
%
% Input:
%   I: object of class ImageDataStore
%   idx: index or range of indices
%
% Output:
%   img: image or range of images from ImageDataStore I
%

try
    if sum(size(idx)) > 2
        img = arrayfun(@(x) I.readimage(x), idx, 'UniformOutput', 0);
    elseif numel(idx) == 1
        img = I.readimage(idx);
    else
        fprintf(2, 'No image at index %d\n', idx);
    end
catch e
    fprintf(2, 'Error returning index %d from ImageDataStore %s\n%s', ...
        idx, I.ReadSize, e.getReport);
    img = [];
end
end