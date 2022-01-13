function [gmid , gimg , gsrc , hsrc] = getDomainInputs(g, hidx, frm, toFlip, bpredict, zpredict, cpredict, mline, varargin)
%% getDomainInputs:
%
%
% Usage:
%   [gmid , gimg , gsrc , hsrc] = getDomainInputs(g, hidx, frm, toFlip, ...
%       bpredict, zpredict, cpredict, mline, varargin)
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

% Get Seedling and Hypocotyl
s    = g.getSeedling(hidx);
h    = s.MyHypocotyl;
gimg = g.getImage(frm);

% ---------------------------------------------------------------------------- %
%% Get upper and lower regions
% Upper regions
himg            = h.getImage(frm, 'gray', 'upper', toFlip);
[hcupp , hmupp] = predictFromImage(himg, bpredict, zpredict, cpredict, mline);

% Lower regions
hmsk        = h.getImage(frm, 'bw', 'lower', toFlip);
[~ , hclow] = extractContour(hmsk, npts, init, creq);
hclow       = raw2clipped(hclow, 1, 4, slens, fidx);
hmlow       = mline(hclow);

% Flip curves back to original direction
if toFlip
    hcupp = flipAndSlide(hcupp, slens);
    hmupp = flipLine(hmupp, slen);
    hclow = flipAndSlide(hclow, slens);
    hmlow = flipLine(hmlow, slen);
end

% ---------------------------------------------------------------------------- %
%% Remap upper and lower, then stitch midlines
[gcupp , gmupp] = thumb2full(h, frm, hcupp, hmupp, 'upper');
[gclow , gmlow] = thumb2full(h, frm, hclow, hmlow, 'lower');

% Stitch regions
gmid = interpolateOutline([gmlow ; gmupp], msz);

% ---------------------------------------------------------------------------- %
%% Output seedling and hypocotyl region's contours and midlines
hsrc.cupp = hcupp;
hsrc.clow = hclow;
hsrc.mupp = hmupp;
hsrc.mlow = hmlow;

gsrc.cupp = gcupp;
gsrc.clow = gclow;
gsrc.mupp = gmupp;
gsrc.mlow = gmlow;
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;
p.addOptional('npts', 210);
p.addOptional('init', 'alt');
p.addOptional('creq', 'Normalize');
p.addOptional('slens', [53 , 52 , 53 , 51]);
p.addOptional('fidx', 0);
p.addOptional('slen', 51);
p.addOptional('msz', 500);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end