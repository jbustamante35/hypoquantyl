function zprj = zVectorProjection(zinn, nsegs, zeigs, zmns, zdrc)
%% zVectorProjection: convert contour to Z-Vector PC score, or vice versa
%
%
% Usage:
%   Y = zVectorProjection(Z, nsegs, zeigs, zmns, zdrc)
%
% Input:
%   cntr:
%   nsegs:
%   evecs:
%   mns:
%   zdrc: direction [0: C -> Zp | 1: Zp -> Z | 2: Z -> Zp] (default 3)
%
% Output:
%   Y:
%

%%
if nargin < 5; zdrc = 3; end

switch zdrc
    case 0
        % Contour to Z-Vector PC Score (default)
        zvec = contour2corestructure(zinn);
        zvec = zVectorConversion(zvec(:,1:4), nsegs, 1, 'prep');
        zprj = pcaProject(zvec, zeigs, zmns, 'sim2scr');
    case 1
        % Z-Vector PC Score to Z-Vector
        zvec    = pcaProject(zinn, zeigs, zmns, 'scr2sim');
        zvec    = zVectorConversion(zvec, nsegs, 1, 'rev');
        [~ , zprj] = addNormalVector(zvec);
    case 2
        % Z-Vector to Z-Vector PC Score
        if size(zinn,2) == 6; zinn = zinn(:,1:4); end
        zvec = zVectorConversion(zinn, nsegs, 1, 'prep');
        zprj = pcaProject(zvec, zeigs, zmns, 'sim2scr');
    case 3
        % Determine which direction to convert (default)
        if size(zinn,2) == 2
            % X is a contour (zdrc = 0)
            zdrc = 0;
        elseif size(zinn,1) == 1
            % X is a set of Z-Vector PC scores (zdrc = 1)
            zdrc = 1;
        elseif size(zinn,1) > 1
            % X is a full Z-Vector (zdrc = 2)
            zdrc = 2;
        else
            fprintf(2, 'Can''t determine X [%d x %d]\n', size(zinn));
            zprj = [];
            return;
        end

        % Recurse through function with this direction
        zprj = zVectorProjection(zinn, nsegs, zeigs, zmns, zdrc);
end
end
