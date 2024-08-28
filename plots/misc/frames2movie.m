function frames2movie(vw, fins)
%% frames2movie: convert directory of image frames to movie
%
% Usage:
%   frames2movie(vw, fins)
%
% Input:
%   VW: VideoWriter object
%   fins: cell array of input filenames to move frames
%

% if nargin < 3; frate = 12;  end
% if nargin < 4; fqual = 100; end

tt = tic;
vnm   = vw.Filename;
nfrms = numel(fins);
fprintf('Loading %d filenames to images...', nfrms);
imgs  = cellfun(@(x) imread(x), fins, 'UniformOutput', 0);
fprintf('DONE! [%.03f sec]\n', mytoc(tt));

vw.open;
for frm = 1 : nfrms
    tf = tic;
    fprintf('Writing frame %02d of %02d to %s...', frm ,nfrms, vnm);
    writeVideo(vw, imgs{frm});
    fprintf('DONE! [%.03f sec]\n', mytoc(tf));
end
vw.close;
end