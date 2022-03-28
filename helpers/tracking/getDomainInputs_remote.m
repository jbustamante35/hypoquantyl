function [gmid , gsrc , hsrc] = getDomainInputs_remote(simg, uimg, lmsk, gbox, ubox, lbox, toFlip, varargin)
%% getDomainInputs_remote:
%
%
% Usage:
%   [gmid , gimg , gsrc , hsrc] = getDomainInputs_remote(simg, uimg, lmsk, ...
%       gbox, ubox, lbox, toFlip, mline, varargin)
%
% Input:
%   g:
%   hidx:
%   frm:
%   toFlip:
%   varargin: various options
%       bpredict:
%       zpredict:
%       cpredict:
%       mline:
%
% Output:
%   gmid:
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
if isempty(hclow)
    if ~isempty(lmsk)
        [hclow , hmlow] = mask2clipped(lmsk, ...
            dsz, npts, init, creq, mth, smth, slens, fidx);
    else
        [hclow , hmlow] = deal([]);
    end
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
p.addOptional('bpredict', []);
p.addOptional('zpredict', []);
p.addOptional('cpredict', []);
p.addOptional('mline', []);
p.addOptional('dsz', 3);
p.addOptional('npts', 210);
p.addOptional('init', 'alt');
p.addOptional('creq', 'Normalize');
p.addOptional('mth', 1);
p.addOptional('smth', 1);
p.addOptional('slens', [53 , 52 , 53 , 51]);
p.addOptional('slen', 51);
p.addOptional('msz', 50);
p.addOptional('fidx', 0);
p.addOptional('hcupp', []);
p.addOptional('hmupp', []);
p.addOptional('hclow', []);
p.addOptional('hmlow', []);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end