function [Rx, Ry] = rasterizeImages(D)
%% rasterizeImages: function to take stack of data and create single rasterized dataset
% This function takes in a cell array representing a N-stack of [n x d] data and linearizes each to
% create a single large [N x d] data set representing the rasterized form. This form of data is used
% for Principal Components Analysis. 
% 
% Usage: 
%   [Rx, Ry] = rasterizeImages(im)
% 
% Input:
%   imgs: cell array of size N representing stack of [n x d] data
% 
% Output:
%   rast: single matrix of size [N x d] representing rasterized output of imgs
% 
% 

%% Iterate through cell array and linearize into next layer of rast
Rx = zeros(numel(D), numel(D{1}));
Ry = zeros(numel(D{1}), numel(D));
for i = 1 : numel(D)
    try
        Rx(i,:) = D{i}(:);
    catch         
        fprintf('Trying alternate method \n');
        Ry(i,:) = D{i}(:)';        
    end
end

end