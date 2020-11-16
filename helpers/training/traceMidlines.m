function [mlines , mvec] = traceMidlines(CRVS, idxs, overwrite, fidx)
%% traceMidlines: trace a set of midlines on Curves
% Description
%
% Usage:
%    [mlines , mvec] = traceMidlines(CRVS, idxs, overwrite, fidx)
%
% Input:
%    CRVS: array of Curve objects to trace midlines for
%    idxs: indices to draw randomly from array of Curves (optional)
%    overwrite: boolean to decide to skip (0) or overwrite (1) if data exists
%    fidx: figure handle index to trace onto
%
% Output:
%    mlines: cell array of midline coordinates
%    mvec: vectorized midlines in a 2D cell array for x- and y-coodinates
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%%
switch nargin
    case 1
        idxs        = 1 : numel(CRVS);
        overwrite   = 0;
        fidx        = 1;
    case 2
        overwrite   = 0;
        fidx        = 1;
    case 3
        fidx        = 1;
    case 4
    otherwise
        fprintf(2, 'Error with inputs (%d)\n', nargin);
        [mlines , mvec] = deal([]);
        return;
end

%%
if numel(CRVS) > 1
    C = CRVS(idxs);
else
    C = CRVS;
end

ncrvs  = numel(C);
mlines = cell(ncrvs, 1);

for n = 1 : ncrvs
    c = C(n);
    
    if isempty(c.getMidline)
        c.DrawMidline(fidx);
    else
        if overwrite
            c.DrawMidline(fidx);
        end
    end
    mlines{n} = c.getMidline('int');
end

%% Vectorize
mX   = cellfun(@(m) m(:,1)', mlines, 'UniformOutput', 0);
mY   = cellfun(@(m) m(:,2)', mlines, 'UniformOutput', 0);
mvec = {cat(1, mX{:}) , cat(1, mY{:})};

end

