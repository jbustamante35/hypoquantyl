function traceMidlines(CRVS, idxs, overwrite, fidx, auto)
%% traceMidlines: trace a set of midlines on Curves
% Description
%
% Usage:
%   traceMidlines(CRVS, idxs, overwrite, fidx, auto)
%
% Input:
%   CRVS: array of Curve objects to trace midlines for
%   idxs: indices to draw randomly from array of Curves (optional)
%   overwrite: boolean to decide to skip (0) or overwrite (1) if data exists
%   fidx: figure handle index to trace onto
%   auto: boolean to prime initial midline using distance transform
%
% Output: [n/a]
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%%
switch nargin
    case 1
        idxs      = 1 : numel(CRVS);
        overwrite = 0;
        fidx      = 1;
        auto      = 0;
    case 2
        overwrite = 0;
        fidx      = 1;
        auto      = 0;
    case 3
        fidx = 1;
        auto = 0;
    case 4
        auto = 0;
    case 5
    otherwise
        fprintf(2, 'Error with inputs (%d)\n', nargin);
        return;
end

%%
if numel(CRVS) > 1
    C = CRVS(idxs);
else
    C = CRVS;
end

ncrvs = numel(C);

for n = 1 : ncrvs
    c = C(n);

    if auto
        %% Prime midlines using distance transform
        % NOTE: This only works with one curve at a time for now
        img   = c.getImage;
        cntr  = c.getTrace;
        pline = primeMidline(img, cntr);
        c.setMidline(pline);
        c.FixMidline(fidx);

    else
        %% Trace midline from scratch
        if isempty(c.getMidline)
            c.DrawMidline(fidx);
        else
            if overwrite
                c.DrawMidline(fidx);
            end
        end

    end
end

end

