function showPrediction(img, hyp, fidx, ttl, p, hopts)
%% showPrediction: show results from hypocotyl segmentation
%
%
% Usage:
%   showPrediction(img, hyp, fidx, ttl, p)
%
% Input:
%   img:
%   hyp: output from segmentation
%   fidx:
%   ttl:
%   p:
%
if nargin < 3; fidx  = 1;  end
if nargin < 4; ttl   = ''; end
if nargin < 5; p     = 0;  end
if nargin < 6; hopts = []; end

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
        cpre = hyp.getTrace(fnc, drc, buf, scl);
        mpre = hyp.getMidline('nate', mdrc, buf, scl);
        zpre = hyp.getZVector('fnc', drc, 'vsn', fnc, 'mbuf', buf, 'scl', scl);
        zpre = zpre(:,1:2);
        bpre = hyp.getBotMid(fnc, drc, buf, scl);
        gpre = mscore(img, mpre);
    otherwise
        [cpre , mpre , zpre , bpre] = deal([]);
        gpre = 0;
end

if ~isempty(fidx); set(0, 'CurrentFigure', fidx); end
myimagesc(img);
hold on;
plt(cpre, 'g-', 2);
plt(mpre, 'r-', 2);
plt(zpre, 'y.', 2);
plt(bpre, 'b.', 20);

ttl = sprintf('%s [%.03f]', ttl, gpre);
title(ttl, 'FontSize', 10);
if p; pause(p); end
hold off;
end