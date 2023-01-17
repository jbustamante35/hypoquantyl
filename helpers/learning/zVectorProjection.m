function Y = zVectorProjection(X, nsegs, evecs, mns, zdrc)
%% zVectorProjection: convert contour to Z-Vector PC score, or vice versa
%
%
% Usage:
%   zscr = zVectorProjection(cntr, nsegs, evecs, mns, zdrc)
%
% Input:
%   cntr:
%   nsegs:
%   evecs:
%   mns:
%   zdrc: direction [0: contour -> Z-Vec PC | 1: Z-Vec PC -> Z-Vec] (default 0)
%
% Output:
%   zscr:
%

%%
if nargin < 5; zdrc = 0; end

switch zdrc
    case 0
        % Contour to Z-Vector PC Score (default)
        zvec = contour2corestructure(X);
        zvec = zVectorConversion(zvec(:,1:4), nsegs, 1, 'prep');
        Y    = pcaProject(zvec, evecs, mns, 'sim2scr');
    case 1
        % Z-Vector PC Score to Z-Vector
        zvec    = pcaProject(X, evecs, mns, 'scr2sim');
        zvec    = zVectorConversion(zvec, nsegs, 1, 'rev');
        [~ , Y] = addNormalVector(zvec);
    case 2
        % Z-Vector to Z-Vector PC Score
        if size(X,2) == 6; X = X(:,1:4); end
        zvec = zVectorConversion(X, nsegs, 1, 'prep');
        Y    = pcaProject(zvec, evecs, mns, 'sim2scr');
    case 3
        % Determine which direction to convert
        if size(X,2) == 2
            % X is a contour (zdrc = 0)
            zdrc = 0;
        elseif size(X,1) == 1
            % X is a set of Z-Vector PC scores (zdrc = 1)
            zdrc = 1;
        elseif size(X,1) > 1
            % X is a full Z-Vector (zdrc = 2)
            zdrc = 2;
        else
            fprintf(2, 'Can''t determine X [%d x %d]\n', size(X));
            Y = [];
            return;
        end

        % Recurse through function with this direction
        Y = zVectorProjection(X, nsegs, evecs, mns, zdrc);
end
end
