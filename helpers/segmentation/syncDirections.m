function hfix = syncDirections(horg, slens, pik, flp)
%% syncDirections: flip all curves to most frequent direction
%
% Usage:
%   hfix = syncDirections(horg, slens, pik, flp)
%
% Input:
%   hyps: input curve structures
%   slens: length of curve sections (default [53 , 52 , 53 , 51])
%   pik: default choice for curves that don't need re-orienting [default 'opt']
%   flp: flip curves of flipped decisions
%
% Output:
%   hfix: curves with re-arranged directions
%
if nargin < 2; slens = [53 , 52 , 53 , 51]; end
if nargin < 3; pik   = 'opt';               end
if nargin < 4; flp   = 0;                   end

hfix       = horg;
crvs       = cellfun(@(x) x.uhyp.opt.c, horg, 'UniformOutput', 0);
[~ , adrc] = cellfun(@(x) getCurveDirection(x,slens), ...
    crvs, 'UniformOutput', 0);

%
ldrc  = strcmpi(adrc,'left');
rdrc  = ~ldrc;
lbest = sum(ldrc) > sum(rdrc);
rbest = ~lbest;
lidx  = find(lbest);
ridx  = find(rbest);

%
flps = cellfun(@(x) x.info.toFlip, horg);

%% Left-Facing
for i = 1 : numel(lidx)
    idx  = lidx(i);
    drc  = ldrc(:, idx);
    hcol = horg(:,idx);

    %
    flpchk = horg{1,idx}.info.toFlip;
    for ii = 1 : numel(hcol)
        if ~drc(ii); res = 'flp'; else; res = pik; end
        % Set best choice
        hcol{ii}.uhyp.best = hcol{ii}.uhyp.(res);

        % Do I need to flip the entire curve?
        hb     = hcol{ii}.uhyp.best;        
%         flpchk = ~hcol{ii}.info.toFlip;
        infchk = hb.g ~= Inf;
        if flp && infchk && flpchk
            hb.c = flipAndSlide(hb.c, slens);
            hb.z = contour2corestructure(hb.c);
            hb.m = flipLine(hb.m, slens(end));
            hb.b = hb.m(1,:);
        end

        hcol{ii}.uhyp.best = hb;
    end

    %
    hfix(:,idx) = hcol;
end

%% Right-Facing
for i = 1 : numel(ridx)
    idx  = ridx(i);
    drc  = rdrc(:,idx);
    hcol = horg(:,idx);

    %
%     flpchk = ~horg{1,idx}.info.toFlip;
    for ii = 1 : numel(hcol)
        if ~drc(ii); res = 'flp'; else; res = pik; end
        % Set best choice
        hcol{ii}.uhyp.best = hcol{ii}.uhyp.(res);

        % Do I need to flip the entire curve?
        hb     = hcol{ii}.uhyp.best;
        flpchk = ~hcol{ii}.info.toFlip;
        infchk = hb.g ~= Inf;
        if flp && infchk && flpchk
            hb.c = flipAndSlide(hb.c, slens);
            hb.z = contour2corestructure(hb.c);
            hb.m = flipLine(hb.m, slens(end));
            hb.b = hb.m(1,:);
        end

        hcol{ii}.uhyp.best = hb;
    end

    %
    hfix(:,idx) = hcol;
end

%% Check results
% cfix  = cellfun(@(x) x.uhyp.best.c, hfix, 'UniformOutput', 0);
% [~ , fdrc] = cellfun(@(x) getCurveDirection(x,slens), ...
%     cfix, 'UniformOutput', 0);

end