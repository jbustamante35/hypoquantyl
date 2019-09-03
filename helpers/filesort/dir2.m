function list = dir2(varargin)
%% dir2: same as 'dir', but filters out a list directory names
%
% Taken from Bill Cheatham's answer from Stack Overflow:
% https://stackoverflow.com/questions/21781046/matlab-list-files-excluding-directories-in-a-folder
%

list         = dir(varargin{:});
self_indices = ismember({list.name}, {'.', '..', '.DS_STORE'});
list(self_indices) = [];

end