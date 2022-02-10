function [gmid , gsrc , hsrc] = getDomainInputs_remote(simg, uimg, lmsk, gbox, ubox, lbox, toFlip, bpredict, zpredict, cpredict, mline, varargin)
%% getDomainInputs_remote:
%
%
% Usage:
%   [gmid , gimg , gsrc , hsrc] = getDomainInputs_remote(g, hidx, frm, ...
%       toFlip, bpredict, zpredict, cpredict, mline, varargin)
%
% Input:
%   g:
%   hidx:
%   frm:
%   toFlip:
%   bpredict:
%   zpredict:
%   cpredict:
%   mline:
%   varargin:
%
% Output:
%   gmid:
%   gimg:
%   gsrc:
%   hsrc:
%

%% Parse additional inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

% ---------------------------------------------------------------------------- %
%% Get upper and lower regions
% Upper regions
if isempty(hcupp)
    [hcupp , hmupp] = predictFromImage( ...
        uimg, bpredict, zpredict, cpredict, mline);
end

% Lower regions
if ~isempty(lmsk)
    [~ , hclow] = extractContour(lmsk, npts, init, creq);
    hclow       = [smooth(hclow(:,1), smth) , smooth(hclow(:,2), smth)];
    hclow       = raw2clipped(hclow, mth, 4, slens, fidx);
    hmlow       = mline(hclow);
else
    [hclow , hmlow] = deal([]);
end

% ---------------------------------------------------------------------------- %
%% Remap upper and lower, then stitch midlines
[gcupp , gmupp] = thumb2full_remote(uimg, simg, hcupp, hmupp, ubox, gbox, ...
    toFlip, slens, slen);

if ~isempty(hmlow)
    [gclow , gmlow] = thumb2full_remote(lmsk, simg, hclow, hmlow, lbox, gbox, ...
        toFlip, slens, slen);
else
    [gclow , gmlow] = deal([]);
end

% Stitch regions
if ~isempty(gmlow)
    gmid = interpolateOutline([gmlow ; gmupp], msz);
else
    gmid = interpolateOutline(gmupp, msz);
end

% ---------------------------------------------------------------------------- %
%% Output seedling and hypocotyl region's contours and midlines
hsrc = struct('cupp', hcupp, 'clow', hclow, 'mupp', hmupp, 'mlow', hmlow);
gsrc = struct('cupp', gcupp, 'clow', gclow, 'mupp', gmupp, 'mlow', gmlow);
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;
p.addOptional('npts', 210);
p.addOptional('init', 'alt');
p.addOptional('creq', 'Normalize');
p.addOptional('slens', [53 , 52 , 53 , 51]);
p.addOptional('slen', 51);
p.addOptional('msz', 50);
p.addOptional('fidx', 0);
p.addOptional('smth', 1);
p.addOptional('mth', 2);
p.addOptional('hcupp', []);
p.addOptional('hmupp', []);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end