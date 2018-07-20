function P = probabilityMatrix(C, sz)
%% probabilityMatrix: function to generate a probability matrix from CircuitJB objects
% This function takes the masks from an object array of contours and creates a probability matrix
% of size sz from the overlay of all of those masks.
%
% Usage:
%   P = probabilityMatrix(C, sz, sv, f)
%
% Input:
%   C: array of CircuitJB objects
%   sz: [m x n] size to resize image matrix, determine from image data if false
%
% Output:
%   P: [m x n] probability matrix defined by sz parameter
%

if sz == false
    sz = size(C(1).getImage(1, 'gray'));
end

%% Compute mean of all masks and resize to desired image size
cat_mask   = arrayfun(@(x) x.getImage(1,'mask'), C, 'UniformOutput', 0);
cat_mask   = cat(3, cat_mask{:});
mean_mask  = mean(cat_mask,3);
clean_mask = mean_mask(:,any(mean_mask));
clean_mask = clean_mask(any(clean_mask, 2),:);
P          = imresize(clean_mask, sz);
end