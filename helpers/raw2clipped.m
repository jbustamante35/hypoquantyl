function [cntr , cinit , segs] = raw2clipped(cntr, mth, nroutes, rlen, fidx)
%% redoContour: redo contour with proper separation of segments
if nargin < 2; mth     = 1;                   end
if nargin < 3; nroutes = 4;                   end
if nargin < 4; rlen    = [53 , 52 , 53 , 51]; end
if nargin < 5; fidx    = 0;                   end

%
switch mth
    case 1
        %% Find Corners
        % Constant parameterrs
        mph = 0.03; % Minimum peak height

        % Total iterations for each parameter
        nflts  = 4; % Curvature filter size
        nshfts = 5; % Coordinate shifting
        nmpds  = 5; % Minimum peak distance

        % Increase factor for each parameter
        ffac   = 2; % Curvature filter size
        sfac   = 3; % Coordinate shifting
        dfac   = 3; % Minimum peak distance

        % Tracking parameter values and outputs
        T      = zeros(nshfts * nmpds * nflts, 9);
        itr    = 1;
        npeaks = 4;

        if fidx
            figclr(fidx);
        end

        for nf = 1 : nflts
            for ns = 1 : nshfts
                for nm = 1 : nmpds
                    flt  = nf * ffac;
                    shft = ns * sfac;
                    mpd  = nm * dfac;

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
                        subplot(211);
                        plot3(tmp(:,1), tmp(:,2), kw, ...
                            'Color', 'k', 'LineWidth', 2);
                        hold on;
                        plot3(tmp(crns,1), tmp(crns,2), kw(crns), ...
                            'Color', 'r', 'LineStyle', 'none', ...
                            'Marker', '.', 'MarkerSize', 20);
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
                end
            end
        end

        %% Choose best parameters [minimum filt, shift, mpd]
        t    = T(T(:,5) >= 4,:);
        minF = min(t);
        flt  = minF(2);
        tf   = t(t(:,2) == flt,:);
        minS = min(tf);
        shft = minS(3);
        ts   = t(t(:,4) == shft,:);
        minD = min(ts);
        mpd  = minD(4);

        % Use best parameters
        [~ , kw]   = cwtK(cntr, flt, 'closed');
        kw         = circshift(kw, shft);
        cntr       = circshift(cntr, shft);
        [~ , crns] = findpeaks(kw, 'NPeaks', npeaks,...
            'MinPeakHeight', mph, 'MinPeakDistance', mpd);
        cntr       = circshift(cntr, -shft);

    case 2
        %% Remove duplicate corners except for the last point
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
if sum(cntr(1,:) ~= cntr(end,:))
    cntr = [cntr ; cntr(1,:)];
end
end
