function args = parseInput(varargin)
%% parseInput: input parser for requestImageData
% 
% 
% Usage:
% 
% 
% Input:
% 
% 
% Output:
% 

p = inputParser;
p.addRequired('Object');
p.addOptional('Request', '');
p.addOptional('Frame', 0);
p.parse(varargin{:});
args = p.Results;

end