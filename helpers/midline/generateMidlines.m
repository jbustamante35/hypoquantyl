function mlines = generateMidlines(crvs, slens, msz, par, rho, edg, res)
%% generateMidlines: easier way to set midline for Curve objects
%
% Usage:
%   crvs = generateMidlines(crvs, mtyp, ctyp)
%
% Input:
%   crvs: Curve objects
%   mtyp: midline type [default 'nate']
%   ctyp: contour type [default 'Clip']
%
% Output:
%   crvs: Output of Curve
if nargin < 2; msz   = 50;                  end
if nargin < 2; slens = [53 , 52 , 53 , 51]; end
if nargin < 5; par   = 0;                   end
if nargin < 2; rho   = 8;                   end
if nargin < 3; edg   = 2;                   end
if nargin < 4; res   = 0.13;                end

%%
[~ , sprA] = jprintf(' ', 0, 0, 80);

if iscell(crvs)
    ncrvs = numel(crvs);
else
    ncrvs = 1;
    crvs  = {crvs};
end

mlines = cell(ncrvs, 1);
ta = tic;
fprintf(['\n%s\n\nGenerating Midlines [%03d Curves]' ...
    '[%d Rho | %d Edg | %.02f Res]\n\n%s\n'], sprA, ncrvs, rho, edg, res, sprA);

if par
    % With parallelization
    parfor cidx = 1 : ncrvs
        te = tic;
        fprintf(['| Curve %03d of %03d | rho %02d | ' ...
            'edg %02d | res %.02f | '], cidx, ncrvs, rho, edg, res);
        mlines{cidx} = nateMidline(crvs{cidx}, slens, rho, edg, res, msz, 0);
        fprintf('%.02f sec |\n', mytoc(te, 'sec'));
    end
else
    % On single-thread
    for cidx = 1 : ncrvs
        te = tic;
        fprintf(['| Curve %03d of %03d | rho %02d | ' ...
            'edg %02d | res %.02f | '], cidx, ncrvs, rho, edg, res);
        mlines{cidx} = nateMidline(crvs{cidx}, slens, rho, edg, res, msz, 0);
        fprintf('%.02f sec |\n', mytoc(te, 'sec'));
    end
end
fprintf('%s\n\nFinished %d Tests! [%.03f min]\n\n%s\n', ...
    sprA, ncrvs, mytoc(ta, 'min'), sprA);

end