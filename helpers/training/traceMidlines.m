function [mlines , mvec] = traceMidlines(CRVS, idxs, overwrite, fidx, interp_size)
%% traceMidlines: trace a set of midlines on Curves
% Description
%
% Usage:
%    [mlines , mvec] = traceMidlines(CRVS, idxs, overwrite, fidx, interp_size)
%
% Input:
%    CRVS: array of Curve objects to trace midlines for
%    idxs: indices to draw randomly from array of Curves (optional)
%    overwrite: boolean to decide to skip (0) or overwrite (1) if data exists
%    fidx: figure handle index to trace onto
%    interp_size: number of midline coordinates to interpolate to
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
        interp_size = 0;
    case 2
        overwrite   = 0;
        fidx        = 1;
        interp_size = 0;
    case 3
        fidx        = 1;
        interp_size = 0;
    case 4
        interp_size = 0;
    case 5
    otherwise
        fprintf(2, 'Error with inputs (%d)\n', nargin);
        [mlines , mvec] = deal([]);
        return;
end

%%
C      = CRVS(idxs);
ncrvs  = numel(C);
mlines = cell(ncrvs, 1);

for n = 1 : ncrvs
    c = C(n);
    
    if isempty(c.getMidline)
        c.DrawMidline(interp_size, fidx);
    else
        if overwrite
            c.DrawMidline(interp_size, fidx);
        end
    end
    mlines{n} = c.getMidline('Interp');
end

%% Vectorize
mX   = cellfun(@(m) m(:,1)', mlines, 'UniformOutput', 0);
mY   = cellfun(@(m) m(:,2)', mlines, 'UniformOutput', 0);
mvec = {cat(1, mX{:}) , cat(1, mY{:})};

end

