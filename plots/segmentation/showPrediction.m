function fdata = showPrediction(img, hyp, fidx, ttl, tsz, lsz, msz, ax, scr, soff, hopts)
%% showPrediction: show results from hypocotyl segmentation
%
%
% Usage:
%   fdata = showPrediction(img, hyp, fidx, ttl, ...
%       tsz, lsz, msz, ax, scr, soff, hopts)
%
% Input:
%   img: image to plot onto
%   hyp: output from segmentation
%   fidx: figure handle index
%   ttl: title string [default score]
%   tsz: font size for title [default 10]
%   lsz: line width for contour and midline [default 2]
%   msz: marker size for coordinates [default 3]
%   ax: axis style [default 'square']
%   scr: show score above prediction
%   soff: [x , y] offset to display score
%   hopts: additional options (if using Hypocotyl object directly)
%
% Output:
%   fdata: figure data

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%
switch class(hyp)
    case 'struct'
        try cpre = hyp.c;        catch; cpre = []; end
        try mpre = hyp.m;        catch; mpre = []; end
        try zpre = hyp.z(:,1:2); catch; zpre = []; end
        try bpre = hyp.b;        catch; bpre = []; end
        try gpre = hyp.g;        catch; gpre = []; end
    case 'Curve'
        if isempty(hopts)
            fnc    = 'Clip';
            drc    = 'raw';
            mdrc   = 'raw';
            buf    = 0;
            scl    = 1;
            mscore = [];
        else
            fnc    = hopts{1};
            drc    = hopts{2}{1};
            mdrc   = hopts{2}{2};
            buf    = hopts{3};
            scl    = hopts{4};
            mscore = hopts{5};
        end
        
        if isempty(img)
            img = hyp.getImage('gray', 'upper', drc, [], buf, 0, scl);
        end

        cpre = hyp.getTrace(fnc, drc, buf, scl);
        mpre = hyp.getMidline('pca', mdrc, buf, scl);
        zpre = hyp.getZVector('fnc', drc, 'vsn', fnc, 'mbuf', buf, 'scl', scl);
        zpre = zpre(:,1:2);
        bpre = hyp.getBotMid(fnc, drc, buf, scl);
        gpre = mscore(img, mpre);
    otherwise
        [cpre , mpre , zpre , bpre] = deal([]);
        gpre = 0;
end

if ~isempty(fidx); figclr(fidx,1); end
myimagesc(img, 'gray', ax);
hold on;
plt(cpre, 'g-', lsz);
plt(mpre, 'r-', lsz);
plt(zpre, 'y.', msz);
plt(bpre, 'b.', 20);

% Show score above prediction
if scr
    xoff = soff(1);
    yoff = soff(2);
    gstr = num2str(round(gpre,2));
    mcrd = mpre(end,:) + [xoff , yoff];
    text(mcrd(1), mcrd(2), gstr, ...
        'FontSize', tsz, 'FontWeight', 'b', 'Color', 'b');
end

if isempty(ttl); ttl = sprintf('%s [%.03f]', ttl, gpre); end
title(ttl, 'FontSize', tsz);
% if p; pause(p); end
hold off;

fdata = [];
if nargout > 1; fdata = getframe(gcf); fdata = fdata.cdata; end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

if nargin < 3;  fidx  = 1;           end
if nargin < 4;  ttl   = '';          end
if nargin < 5;  tsz   = 10;          end
if nargin < 6;  lsz   = 2;           end
if nargin < 7;  msz   = 3;           end
if nargin < 8;  ax    = 'square';    end
if nargin < 9;  scr   = 0;           end
if nargin < 10; soff  = [-25 , -70]; end
if nargin < 11; hopts = [];          end

% Misc Options
p.addOptional('xtrp', []);
p.addOptional('ytrp', []);
p.addOptional('fsmth', 0);
p.addOptional('smooth_shape', 'disk');
p.addOptional('interp_method', 'cubic');

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
