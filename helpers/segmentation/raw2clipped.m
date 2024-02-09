function [cntr , cinit , segs , T] = raw2clipped(cntr, mth, nroutes, rlen, fidx)
%% redoContour: redo contour with proper separation of segments
%
%
% Usage:
%   [cntr , cinit , segs , T] = raw2clipped(cntr, mth, nroutes, rlen, fidx)
%
% Input:
%   cntr: input contour
%   mth: method to find corners [default 1]
%   nroutes: number of regions to set [default 4]
%   rlen: length of each route [default [53 , 52 , 53 , 51]]
%   fidx: figure handle index to display to [default 0]
%
% Output:
%   cntr: proessed contour
%   cinit: coordinate indices for starts of corners
%   segs: coordinates for each segment
%   T: table of results from brute force method [method 2 only]
if nargin < 2; mth     = 1;                   end
if nargin < 3; nroutes = 4;                   end
if nargin < 4; rlen    = [53 , 52 , 53 , 51]; end
if nargin < 5; fidx    = 0;                   end

%
[T , shft] = deal(0);
switch mth
    case 1
        %% Get top-bottom sections, then left-right sections [best]
        [blbl , tlbl] = labelContour(cntr, 1, 2);

        bidxs = find(blbl);
        tidxs = find(tlbl);

        % Right section: closest bottom section index to end of top section
        [~ , lend]  = min(cntr(tidxs,1));
        [~ , rstrt] = max(cntr(tidxs,1));
        [~ , rend]  = max(cntr(bidxs,1));

        % Corners are sorted left and right indices
        lidxs = [1 ; tidxs(lend)];
        ridxs = [tidxs(rstrt) ; bidxs(rend)];
        crns  = sort([lidxs ; ridxs]);
    case 2
        %% Brute force search
        % Constant parameterrs
        mph = 0.03; % Minimum peak height

        % Filter size
        min_flts  = 1;
        max_flts  = 10;
        itr_flts  = 2;

        % Coordinate shifting
        min_shfts = 1;
        max_shfts = 15;
        itr_shfts = 4;

        % Minimum peak distance
        min_mpds  = 10;
        max_mpds  = 30;
        itr_mpds  = 6;

        flts  = min_flts  : round(max_flts  / itr_flts)  : max_flts;
        shfts = min_shfts : round(max_shfts / itr_shfts) : max_shfts;
        mpds  = min_mpds  : round(max_mpds  / itr_mpds)  : max_mpds;

        % Tracking parameter values and outputs
        T      = zeros(numel(flts) * numel(shfts) * numel(mpds), 9);
        itr    = 1;
        npeaks = nroutes;

        if fidx; figclr(fidx); end
        for flt = flts
            for shft = shfts
                for mpd = mpds
                    tmp        = cntr;
                    [~ , kw]   = cwtK(tmp, flt, 'closed');
                    kw         = circshift(kw, shft);
                    tmp        = circshift(tmp, shft);
                    [~ , crns] = findpeaks(kw, 'NPeaks', npeaks,...
                        'MinPeakHeight', mph, 'MinPeakDistance', mpd);
                    tmp        = circshift(tmp, -shft);
                    ncrns      = numel(crns);
                    T(itr,1:5) = [itr , flt , shft , mpd , ncrns];
                    T(itr, 6 : (5 + ncrns)) = crns';
                    itr        = itr + 1;

                    % Show current parameters
                    if fidx
                        showClips(fidx, tmp, kw, crns, flt, shft, mpd, ncrns);
                    end
                end
            end
        end

        %% Choose best parameters [minimum filt, shift, mpd]
        t    = T(T(:,5) >= nroutes,:);
        minF = min(t);
        flt  = minF(2);
        tf   = t(t(:,2) == flt,:);
        minS = min(tf);
        shft = minS(3);
        ts   = t(t(:,3) == shft,:);
        minD = min(ts);
        mpd  = minD(4);

        % Use best parameters
        [~ , kw]   = cwtK(cntr, flt, 'closed');
        kw         = circshift(kw, shft);
        cntr       = circshift(cntr, shft);
        [~ , crns] = findpeaks(kw, 'NPeaks', npeaks,...
            'MinPeakHeight', mph, 'MinPeakDistance', mpd);
        cntr       = circshift(cntr, -shft);
    case 3
        %% Remove duplicate corners except for the last point [old]
        len  = round(size(cntr, 1) / nroutes, -1);
        segs = arrayfun(@(x) ((len * x) + 1 : (len * (x + 1)))', ...
            0 : (nroutes - 1), 'UniformOutput', 0)';
        crns = cellfun(@(x) x(end), segs(1:end));
end

%% Split into segments from corners, interpolate, then stitch
cntr  = cntr(1:end-1,:);
cinit = [1 ; crns(2:end) - shft]';
cends = [cinit(2:4) - 1 , size(cntr,1)];
segs  = arrayfun(@(i,e,l) interpolateOutline(cntr(i:e,:), l), ...
    cinit, cends, rlen, 'UniformOutput', 0);

% Close contour
cntr = cat(1, segs{:});
if sum(cntr(1,:) ~= cntr(end,:)); cntr = [cntr ; cntr(1,:)]; end
end

function showClips(fidx, cntr, kw, crns, flt, shft, mpd, ncrns)
%% showClip:
%
set(0, 'CurrentFigure', fidx);

subplot(211);
plot3(cntr(:,1), cntr(:,2), kw, 'Color', 'k', 'LineWidth', 2);
hold on;
plot3(cntr(crns,1), cntr(crns,2), kw(crns), 'Color', 'r', ...
    'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 20);
ttl = sprintf('Filt %d | Shift %d | MPD %d | Corners %d', ...
    flt, shft, mpd, ncrns);
title(ttl, 'FontSize', 10);
hold off;

subplot(212);
plt(kw, 'k-', 2);
hold on;
plt([crns , kw(crns)], 'r.', 20);
ttl = sprintf('Filt %d | Shift %d | MPD %d | Corners %d', ...
    flt, shft, mpd, ncrns);
title(ttl, 'FontSize', 10);
hold off;

drawnow;
end