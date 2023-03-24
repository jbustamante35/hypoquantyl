%% Curve: class for handling contours and curves
% Descriptions

classdef Curve < handle & matlab.mixin.Copyable
    properties (Access = public)
        Parent
        NumberOfSegments
        TraceSize
        MidlineSize
        Direction
        BasePoint
        ApicalAngle
    end

    properties (Access = protected)
        SEGMENTSIZE    = 25;        % Number of coordinates per segment [default 200]
        SEGMENTSTEPS   = 1;         % Size of step to next segment [default 50]
        ENVELOPESIZE   = 11;        % Hard-coded max distance from original segment to envelope
        MLINEINTRP     = 50;        % Default size to interpolate midline
        MLINETERMINATE = 0.7;       % Default termination percent for midline
        MLINEPSIZE     = [10 , 10]; % Default sampling size for midline patch
        TOCENTER       = 1;         % Default center index for splitting segments
        MAINTRACE      = 'Clip';    % Default contour version
        MAINFUNC       = 'raw';     % Default contour direction
        SEGLENGTH      = [53 , 52 , 53 , 51]; % Lengths of sections
        MANBUF         = 0;         % Cropping buffer around image
        ARTBUF         = 0;         % Artificial buffer around image
        IMGSCL         = 1;         % Rescale size for for image
        ManMidline
        AutoMidline
        NateMidline
    end

    %%
    methods (Access = public)
        %% Constructor and primary methods
        function obj = Curve(varargin)
            %% Constructor method for single Cure
            if ~isempty(varargin)
                % Parse inputs to set properties
                vargs = varargin;
            else
                % Set default properties for empty object
                vargs = {};
            end

            prps   = properties(class(obj));
            deflts = {...
                'NumberOfSegments', 0 ; ...
                'MidlineSize', 0      ; ...
                'TraceSize', 0};
            obj    = classInputParser(obj, prps, deflts, vargs);
        end

        function trc = getTrace(obj, vsn, fnc, mbuf, scl)
            %% Returns contour type and function to do on contour
            % Inputs:
            %   obj: this Curve object
            %   vsn: contour version [Full | Clip] (default Clip)
            %   fnc: direction [left|right] or operation [raw|interp|reverse|repos|norm|back]
            %   mbuf: cropping buffer (default 0)
            %   scl: image scaling from 101 x 101 (default 1)
            if nargin < 2; vsn  = obj.MAINTRACE; end
            if nargin < 3; fnc  = obj.MAINFUNC;  end
            if nargin < 4; mbuf = obj.MANBUF;    end
            if nargin < 5; scl  = obj.IMGSCL;    end

            [trc , ~ , soo] = obj.Parent.getOutline(':', vsn, mbuf, scl);
            xtra            = ((soo / 2) + mbuf);

            % Slide if using buffered coordinates
            drc = obj.Direction;
            if isempty(drc); drc = obj.getDirection(trc, 1, vsn); end

            %
            switch fnc
                case 'raw'
                    % Just return un-processed contour

                case 'interp'
                    % Interpolate to specific size
                    npts = obj.Parent.getProperty('INTERPOLATIONSIZE');
                    trc  = interpolateOutline(trc, npts);

                case 'reverse'
                    % Flip and Slide back to centered position
                    seg_lengths = obj.SEGLENGTH;
                    trc         = flipAndSlide(trc, seg_lengths, mbuf, scl);

                case 'left'
                    % Get left-facing contour
                    % Flip left if facing right
                    if strcmpi(drc, 'right')
                        seg_lengths = obj.SEGLENGTH;
                        trc         = flipAndSlide(trc, seg_lengths, mbuf, -scl, xtra);
                    end

                case 'right'
                    % Get left-facing contour
                    % Flip right if facing left
                    if strcmpi(drc, 'left')
                        seg_lengths = obj.SEGLENGTH;
                        trc         = flipAndSlide(trc, seg_lengths, mbuf, scl, -xtra);
                    end

                case 'repos'
                    % Reposition
                    trc = obj.Parent.NormalOutline(trc);

                case 'norm'
                    trc = obj.normalizeCurve('trace');

                case 'back'
                    [trc , ~] = obj.normalizeCurve('trace');

                otherwise
                    fprintf(2, 'Trace %s must be [raw|interp|reverse|repos|norm|back]\n', ...
                        fnc);
                    trc = [];
                    return;
            end

            % Set size of trace
            obj.TraceSize = size(trc, 1);
        end

        function Z = getZVector(varargin)
            %% Compute the Z-Vector skeleton for this contour
            % Input:
            %   ndims:
            %   vsn:
            %   fnc:
            %   mbuf:
            %   scl:
            %   nsplt:
            %   midx:
            %   addMid2vec:
            %   rot:
            %   rtyp:
            %   dpos:
            %
            % Output:
            %   Z:

            %% Parse inputs
            [ndims , vsn , fnc , mbuf , scl , nsplt , midx , addMid2vec , rot , ...
                rtyp , dpos , bdsp] = deal([]);
            obj  = varargin{1};
            args = parseInputs(varargin(2:end));
            for fn = fieldnames(args)'
                feval(@()assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
            end

            %% Returns the dimensions from ndims [default to all]
            trc = obj.getTrace(vsn, fnc, mbuf, scl);
            stp = obj.SEGMENTSTEPS;
            Z   = contour2corestructure(trc, nsplt, stp, midx);

            % Add midpoints to tangent and normal
            if addMid2vec
                mid = Z(:,1:2);
                Z   = [mid , Z(:,3:4) + mid , Z(:,5:6) + mid];
            end

            % Return specified dimensions
            if ~ndims; ndims  = ':'; end
            Z = Z(:, ndims);

            % Convert tangent-normal to rotation vector (default) and
            % convert to radians (default) or degrees (rot = 1)
            if rot; Z = zVectorConversion(Z, [], [], 'rot', rtyp, dpos); end

            % Displace by midpoint of contour's base
            if bdsp
                obj.setBasePoint(vsn, fnc, mbuf, scl);
                bpt      = obj.BasePoint;
                Z(:,1:2) = Z(:,1:2) - bpt;
            end

            obj.NumberOfSegments = size(Z,1);

            %% Input Parser
            function args = parseInputs(varargin)
                %% Parse input parameters
                p = inputParser;
                p.addOptional('ndims', 0);
                p.addOptional('vsn', obj.MAINTRACE);
                p.addOptional('fnc', obj.MAINFUNC);
                p.addOptional('mbuf', obj.MANBUF);
                p.addOptional('scl', obj.IMGSCL);
                p.addOptional('nsplt', obj.SEGMENTSIZE);
                p.addOptional('midx', obj.TOCENTER);
                p.addOptional('addMid2vec', 0);
                p.addOptional('rot', 0);
                p.addOptional('rtyp', 'rad');
                p.addOptional('dpos', 1);
                p.addOptional('bdsp', 0);

                % Parse arguments and output into structure
                p.parse(varargin{1}{:});
                args = p.Results;
            end
        end

        function segs = getSegmentedOutline(varargin)
            %% Compute the segmented outline
            % This will segment the outline each time, rather than storing it
            % into the object after being run once. This will deprecate the
            % SegmentOutline method.
            try
                obj = varargin{1};
                vsn = obj.MAINTRACE;
                trc = obj.getTrace(vsn);

                switch nargin
                    case 1
                        len  = obj.SEGMENTSIZE;
                        stp  = obj.SEGMENTSTEPS;
                        midx = obj.TOCENTER;
                    case 4
                        len  = varargin{2};
                        stp  = varargin{3};
                        midx = varargin{4};
                        obj.setProperty('SEGMENTSIZE', len);
                        obj.setProperty('SEGMENTSTEPS', stp);
                        obj.setProperty('TOCENTER', midx);
                    otherwise
                        len  = obj.SEGMENTSIZE;
                        stp  = obj.SEGMENTSTEPS;
                        midx = obj.TOCENTER;
                        msg  = sprintf(...
                            ['Input must be (segment_size, steps_per_segment)\n', ...
                            'Segmenting with default parameters (%d, %d)\n'], ...
                            len, stp);
                        fprintf(2, msg);
                end

                segs                 = split2Segments(trc, len, stp, 1, midx);
                obj.NumberOfSegments = size(segs,3);
            catch
                fprintf(2, 'Error splitting outline into multiple segments\n');
                segs = [];
            end
        end

        function idx = getIndex(obj, num)
            %%
            L   = cumsum([1 , obj.SEGLENGTH]);
            idx = L(num);
        end

        function seg = getSegment(obj, idx, vsn, fnc, mbuf, scl, trc)
            %% Get top, bottom, left, or right
            if nargin < 3; vsn  = obj.MAINTRACE; end
            if nargin < 4; fnc  = obj.MAINFUNC;  end
            if nargin < 5; mbuf = obj.MANBUF;    end
            if nargin < 6; scl  = obj.IMGSCL;    end
            if nargin < 7; trc  = [];            end

            if isempty(trc); trc = obj.getTrace(vsn, fnc, mbuf, scl); end

            switch idx
                case 1
                    str = obj.getIndex(1);
                    stp = obj.getIndex(2);
                case 2
                    str = obj.getIndex(2);
                    stp = obj.getIndex(3);
                case 3
                    str = obj.getIndex(3);
                    stp = obj.getIndex(4);
                case 4
                    str = obj.getIndex(4);
                    stp = obj.getIndex(5);
                otherwise
                    fprintf(2, '');
                    seg = [];
                    return;
            end

            seg = trc(str:stp,:);
        end

        function crn = getCornerPoint(obj, num, vsn, fnc, mbuf, scl)
            %%
            if nargin < 3; vsn  = obj.MAINTRACE; end
            if nargin < 4; fnc  = obj.MAINFUNC;  end
            if nargin < 5; mbuf = obj.MANBUF;    end
            if nargin < 6; scl  = obj.IMGSCL;    end

            trc = obj.getTrace(vsn, fnc, mbuf, scl);
            idx = obj.getIndex(num);
            crn = trc(idx,:);
        end

        function mid = getTopMid(obj, vsn, fnc, mbuf, scl)
            %% getTopMid: get midpoint of top segment
            % Inputs:
            %   obj: this Curve object
            %   vsn: contour version [Full|Clip] (default Clip)
            %   fnc: direction [left|right] or operation [see obj.getTrace]
            %   mbuf: cropping buffer (default 0)
            %   scl: image scaling from 101 x 101 (default 1)
            if nargin < 2; vsn  = obj.MAINTRACE; end
            if nargin < 3; fnc  = obj.MAINFUNC;  end
            if nargin < 4; mbuf = obj.MANBUF;    end
            if nargin < 5; scl  = obj.IMGSCL;    end

            seg = obj.getSegment(2, vsn, fnc, mbuf, scl);
            mid = mean(seg,1);
        end

        function mid = getBotMid(obj, vsn, fnc, mbuf, scl)
            %% getBotMid: get midpoint of bottom segment
            % Inputs:
            %   obj: this Curve object
            %   vsn: contour version [Full|Clip] (default Clip)
            %   fnc: direction [left|right] or operation [see obj.getTrace]
            %   mbuf: cropping buffer (default 0)
            %   scl: image scaling from 101 x 101 (default 1)
            if nargin < 2; vsn  = obj.MAINTRACE; end
            if nargin < 3; fnc  = obj.MAINFUNC;  end
            if nargin < 4; mbuf = obj.MANBUF;    end
            if nargin < 5; scl  = obj.IMGSCL;    end

            seg = obj.getSegment(4, vsn, fnc, mbuf, scl);
            mid = mean(seg,1);
        end

        function [nrm , tng] = getTopNorm(obj, vsn, fnc, mbuf, scl)
            %% getTopNorm: get normal to top segment
            % Inputs:
            %   obj: this Curve object
            %   vsn: contour version [Full|Clip] (default Clip)
            %   fnc: direction [left|right] or operation [see obj.getTrace]
            %   mbuf: cropping buffer (default 0)
            %   scl: image scaling from 101 x 101 (default 1)
            if nargin < 2; vsn  = obj.MAINTRACE; end
            if nargin < 3; fnc  = obj.MAINFUNC;  end
            if nargin < 4; mbuf = obj.MANBUF;    end
            if nargin < 5; scl  = obj.IMGSCL;    end

            top = obj.getSegment(2, vsn, fnc, mbuf, scl);
            tng = top(end,:) - top(1,:);
            tng = tng / norm(tng);
            nrm = [tng(2) , -tng(1)];
        end

        function [nrm , tng] = getBotNorm(obj, vsn, fnc, mbuf, scl)
            %% getBotNorm: get normal to bottom segment
            % Inputs:
            %   obj: this Curve object
            %   vsn: contour version [Full|Clip] (default Clip)
            %   fnc: direction [left|right] or operation [see obj.getTrace]
            %   mbuf: cropping buffer (default 0)
            %   scl: image scaling from 101 x 101 (default 1)
            if nargin < 2; vsn  = obj.MAINTRACE; end
            if nargin < 3; fnc  = obj.MAINFUNC;  end
            if nargin < 4; mbuf = obj.MANBUF;    end
            if nargin < 5; scl  = obj.IMGSCL;    end

            top = obj.getSegment(4, vsn, fnc, mbuf, scl);
            tng = top(end,:) - top(1,:);
            tng = tng / norm(tng);
            nrm = [tng(2) , -tng(1)];
        end

        function plotHypocotyl(obj, fidx, vsn, fnc, mid, mbuf, abuf, scl, clr, ttl)
            %% plotHypocotyl
            if nargin < 2;  fidx = 1;             end
            if nargin < 3;  vsn  = obj.MAINTRACE; end
            if nargin < 4;  fnc  = obj.MAINFUNC;  end
            if nargin < 5;  mid  = 'nate';        end
            if nargin < 6;  mbuf = obj.MANBUF;    end
            if nargin < 7;  abuf = obj.ARTBUF;    end
            if nargin < 8;  scl  = obj.IMGSCL;    end
            if nargin < 9;  clr  = 0;             end
            if nargin < 10; ttl  = [];            end

            %
            if fidx; figclr(fidx, ~logical(clr)); end
            img = obj.getImage('gray', 'upper', fnc, [], mbuf, abuf, scl);
            myimagesc(img);
            hold on;

            segs = 1 : 4;
            obj.plotSegments(fidx, segs, clr, vsn, fnc, mbuf, abuf, scl);
            obj.plotCorners( fidx, segs, clr, vsn, fnc, mbuf, abuf, scl);
            obj.plotNorms(fidx, clr, vsn, fnc, mbuf, abuf, scl);
            if ~isempty(mid)
                obj.plotMidline(fidx, clr, mid, fnc, mbuf, abuf, scl);
            end

            if isempty(ttl); [~ , ttl] = obj.makeName; end

            title(ttl, 'FontSize', 6);
            drawnow;
            hold off;
        end

        function plotSegments(obj, fidx, sidx, clr, vsn, fnc, mbuf, abuf, scl)
            %%
            if nargin < 2; fidx = 1;             end
            if nargin < 3; sidx = 1 : 4;         end
            if nargin < 4; clr  = 0;             end
            if nargin < 5; vsn  = obj.MAINTRACE; end
            if nargin < 6; fnc  = obj.MAINFUNC;  end
            if nargin < 7; mbuf = obj.MANBUF;    end
            if nargin < 8; abuf = obj.ARTBUF;    end
            if nargin < 9; scl  = obj.IMGSCL;    end

            % Set new figure | Clear figure
            if fidx; figclr(fidx, ~logical(clr)); end
            if clr
                img = obj.getImage('gray', 'upper', fnc, [], mbuf, abuf, scl);
                myimagesc(img);
            end

            hold on;

            clrs = {'r-' , 'g-' , 'b-' , 'y-'};
            for e = sidx
                seg = obj.getSegment(e, vsn, fnc, mbuf, scl);
                plt(seg, clrs{e}, 2);
            end
        end

        function plotCorners(obj, fidx, sidx, clr, vsn, fnc, mbuf, abuf, scl)
            %%
            if nargin < 2; fidx = 1;             end
            if nargin < 3; sidx = 1 : 4;         end
            if nargin < 4; clr  = 0;             end
            if nargin < 5; vsn  = obj.MAINTRACE; end
            if nargin < 6; fnc  = obj.MAINFUNC;  end
            if nargin < 7; mbuf = obj.MANBUF;    end
            if nargin < 8; abuf = obj.ARTBUF;    end
            if nargin < 9; scl  = obj.IMGSCL;    end

            % Set new figure | Clear figure
            if fidx; figclr(fidx, ~logical(clr)); end
            if clr
                img = obj.getImage('gray', 'upper', fnc, [], mbuf, abuf, scl);
                myimagesc(img);
            end

            hold on;

            clrs = {'r.' , 'g.' , 'b.' , 'y.'};
            for e = sidx
                crn = obj.getCornerPoint(e, vsn, fnc, mbuf, scl);
                plt(crn, 'k.', 25);
                plt(crn, clrs{e}, 20);
            end
        end

        function plotNorms(obj, fidx, clr, vsn, fnc, mbuf, abuf, scl)
            %%
            if nargin < 2; fidx = 1;             end
            if nargin < 3; clr  = 0;             end
            if nargin < 4; vsn  = obj.MAINTRACE; end
            if nargin < 5; fnc  = obj.MAINFUNC;  end
            if nargin < 6; mbuf = obj.MANBUF;    end
            if nargin < 7; abuf = obj.ARTBUF;    end
            if nargin < 8; scl  = obj.IMGSCL;    end

            % Set new figure | Clear figure
            if fidx; figclr(fidx, ~logical(clr)); end
            if clr
                img = obj.getImage('gray', 'upper', fnc, [], mbuf, abuf, scl);
                myimagesc(img);
            end

            hold on;

            %
            tmid          = obj.getTopMid(vsn, fnc, mbuf, scl);
            bmid          = obj.getBotMid(vsn, fnc, mbuf, scl);
            [tnrm , ttng] = obj.getTopNorm(vsn, fnc, mbuf, scl);
            [bnrm , btng] = obj.getBotNorm(vsn, fnc, mbuf, scl);
            bnrm = -bnrm;

            %
            quiver(tmid(1), tmid(2), tnrm(1), tnrm(2), 30, 'Color', 'c');
            quiver(tmid(1), tmid(2), ttng(1), ttng(2), 30, 'Color', 'b');
            quiver(bmid(1), bmid(2), bnrm(1), bnrm(2), 30, 'Color', 'm');
            quiver(bmid(1), bmid(2), btng(1), btng(2), 30, 'Color', 'r');
        end

        function plotMidline(obj, fidx, clr, vsn, fnc, mbuf, abuf, scl)
            %%
            if nargin < 2; fidx = 1;             end
            if nargin < 3; clr  = 0;             end
            if nargin < 4; vsn  = 'nate';        end
            if nargin < 5; fnc  = obj.MAINFUNC;  end
            if nargin < 6; mbuf = obj.MANBUF;    end
            if nargin < 7; abuf = obj.ARTBUF;    end
            if nargin < 8; scl  = obj.IMGSCL;    end

            % Set new figure | Clear figure
            if fidx; figclr(fidx, ~logical(clr)); end
            if clr
                img = obj.getImage('gray', 'upper', fnc, [], mbuf, abuf, scl);
                myimagesc(img);
            end

            hold on;

            mline = obj.getMidline(vsn, fnc, mbuf, scl);
            plt(mline, 'r--', 2);
        end

        function lng = getSegmentLength(obj, num, vsn, fnc, trc, mbuf, scl)
            %% getSegmentLength
            if nargin < 3; vsn  = obj.MAINTRACE; end
            if nargin < 4; fnc  = obj.MAINFUNC;  end
            if nargin < 5; trc  = [];            end
            if nargin < 6; mbuf = obj.MANBUF;    end
            if nargin < 7; scl  = obj.IMGSCL;    end

            seg = obj.getSegment(num, vsn, fnc, mbuf, scl, trc);
            lng = sum(sum(diff(seg, 1, 1).^2, 2).^0.5);
        end

        function [drc1 , drc2] = getDirection(obj, trc, toSet, vsn, fnc, mbuf, scl)
            %% getDirection
            if nargin < 2; trc   = [];            end % Default contour
            if nargin < 3; toSet = 0;             end % Set Direction property
            if nargin < 4; vsn   = obj.MAINTRACE; end
            if nargin < 5; fnc   = obj.MAINFUNC;  end
            if nargin < 6; mbuf  = obj.MANBUF;    end
            if nargin < 7; scl   = obj.IMGSCL;    end

            if isempty(trc); trc = obj.getTrace(vsn, 'raw', mbuf, scl); end
            l1 = obj.getSegmentLength(1, vsn, fnc, trc, mbuf, scl);
            l3 = obj.getSegmentLength(3, vsn, fnc, trc, mbuf, scl);

            if l3 > l1
                drc1 = -1;
                drc2 = 'left';
            else
                drc1 = 1;
                drc2 = 'right';
            end

            if toSet; obj.Direction = drc2; end
        end

        function setBasePoint(obj, vsn, fnc, mbuf, scl)
            %% setBasePoint
            if nargin < 2; vsn  = obj.MAINTRACE; end
            if nargin < 3; fnc  = obj.MAINFUNC;  end
            if nargin < 4; mbuf = obj.MANBUF;    end
            if nargin < 5; scl  = obj.IMGSCL;    end

            obj.BasePoint = obj.getBotMid(vsn, fnc, mbuf, scl);
        end

        function agl = getApicalAngle(obj, vsn, fnc, mbuf, scl)
            %% getApicalAngle
            if nargin < 2; vsn  = obj.MAINTRACE; end
            if nargin < 3; fnc  = obj.MAINFUNC;  end
            if nargin < 4; mbuf = obj.MANBUF;    end
            if nargin < 5; scl  = obj.IMGSCL;    end

            nrm = obj.getTopNorm(vsn, fnc, mbuf, scl);
            agl = (atan2(-nrm(2), -nrm(1)) * 180) / pi;

            obj.ApicalAngle = agl;
        end

        function DrawMidline(obj, fidx, showcnt)
            %% Draw midline on this image
            % This method is effectively DrawOutline from the CircuitJB class,
            % I literally just changed the name from Outline to Midline.
            %
            % Input:
            %   obj: this Curve object
            %   fidx: figure handle to plot onto
            %   pline: primed midline computed from distance transform
            %   showcnt: show contour when tracing midline
            if nargin < 2; fidx    = 1; end
            if nargin < 3; showcnt = 1; end

            try
                % Trace outline and store as RawOutline
                vsn  = obj.MAINTRACE;
                fnc  = obj.MAINFUNC;
                mbuf = obj.MANBUF;
                abuf = obj.ARTBUF;
                scl  = obj.IMGSCL;

                figclr(fidx);
                img   = obj.getImage('gray', 'upper', fnc, [], mbuf, abuf, scl);
                cntr  = obj.getTrace(vsn, fnc, mbuf, scl);
                pline = primeMidline(img, cntr);
                cp    = [cntr ; pline];

                %% Trace midline from scratch
                str = sprintf('Midline\n%s', fixtitle(obj.Parent.Origin));
                if showcnt
                    c = drawPoints(img, 'y', str, cp);
                else
                    c = drawPoints(img, 'y', str);
                end

                mline = c.Position;
                obj.setMidline(mline, 'man', 'raw');
            catch e
                frm = obj.Parent.getFrame;
                fprintf(2, 'Error setting outline at frame %d \n%s\n', ...
                    frm, e.getReport);
            end
        end

        function [mline , skl] = setMidline(obj, mline, typ, vsn, fnc, mbuf, scl)
            %% Set coordinates for traced midline or autogenerate it
            % Input:
            %   obj: this Curve object
            %   mline: raw coordinates for midline
            %   typ: generation of midline [man|auto|nate] (default 'man')
            %   vsn: version of contour [Full|Clip] (default 'Clip')
            %   fnc: direction [left|right] or operation [raw|int|norm]
            %   mbuf: cropping buffer for image [default 0]
            %   scl: image scaling from 101 x 101 [default 1]
            %
            % Output:
            %   mline: midline coordinates
            %   skl: skeleton structure (for debugging)

            if nargin < 2; mline = [];            end % Default to empty
            if nargin < 3; typ   = 'man';         end % Default manually-traced
            if nargin < 4; vsn   = obj.MAINTRACE; end % Default clipped contour
            if nargin < 5; fnc   = obj.MAINFUNC;  end % Default contour direction
            if nargin < 6; mbuf  = obj.MANBUF;    end % Cropping buffer
            if nargin < 7; abuf  = obj.ARTBUF;    end % Artificial buffer
            if nargin < 8; scl   = obj.IMGSCL;    end % Image scale

            skl = [];
            switch typ
                case 'man'
                    %% Manually trace midline
                    try
                        % Anchor first coordinate to base of contour
                        trc        = obj.getTrace(vsn, fnc, mbuf, scl);
                        [~ , bidx] = resetContourBase(trc);
                        mline(1,:) = trc(bidx,:);

                        obj.ManMidline = mline;
                    catch e
                        fprintf(2, 'Error setting ManMidline\n%s\n', ...
                            e.getReport);
                    end

                case 'auto'
                    %% Midline using distance transform
                    try
                        if isempty(mline)
                            tpct = obj.MLINETERMINATE;
                        else
                            tpct = mline;
                        end

                        img   = obj.getImage('gray', 'upper', ...
                            fnc, [], mbuf, abuf, scl);
                        trc   = obj.getTrace(vsn, fnc, mbuf, scl);
                        intrp = obj.MLINEINTRP;

                        [mline , skl] = primeMidline(img, trc, intrp, tpct);

                        obj.AutoMidline = mline;

                    catch e
                        fprintf(2, 'Error generating AutoMidline\n%s\n', ...
                            e.getReport);
                    end

                case 'nate'
                    %% Nathan Method [optimized equal distance to radius]
                    try
                        trc  = obj.getTrace(vsn, fnc, mbuf, scl);
                        mpts = obj.MLINEINTRP;

                        % If mline contains [rho , edg , res] values
                        if ~isempty(mline)
                            rho = mline(1);
                            edg = mline(2);
                            res = mline(3);
                        else
                            % Default parameters
                            rho = 5;
                            edg = 3;
                            res = 0.1;
                        end

                        [mline , skl] = nateMidline( ...
                            trc, obj.SEGLENGTH, rho, edg, res, mpts);

                        obj.NateMidline = mline;
                    catch e
                        fprintf(2, 'Error setting NateMidline [%s]\n%s\n', ...
                            typ, e.getReport);
                    end
            end
        end

        function mline = getMidline(obj, vsn, fnc, mbuf, scl)
            %% Return raw or interpolated midline
            % Computes interpolated or normalized midline at execution. This
            % saves memory by not storing them in the object.
            if nargin < 2; vsn  = 'auto';     end % Default auto-generated
            if nargin < 3; fnc  = 'int';      end % Default interpolated
            if nargin < 4; mbuf = obj.MANBUF; end % Cropping buffer
            if nargin < 5; scl  = obj.IMGSCL; end % Image scale

            % Get midline type
            switch vsn
                case 'man';  mline = obj.ManMidline;
                case 'auto'; mline = obj.AutoMidline;
                case 'nate'; mline = obj.NateMidline;
                otherwise
                    fprintf(2, 'Method %s must be [man|auto|nate]\n', vsn);
            end

            % Get interpolated, raw, or origin-centered midline
            %             dsp = obj.SEGLENGTH(end) * scl;
            sld = obj.SEGLENGTH(end);
            switch fnc
                case 'raw'
                    % Keep raw coordinates

                case 'flip'
                    % Flip original direction
                    mline = flipLine(mline, sld, scl);

                case 'left'
                    % Force left-facing midline
                    drc = obj.Direction;
                    if isempty(drc); drc = obj.getDirection(1, vsn); end

                    % Flip left if facing right
                    if strcmpi(drc, 'right')
                        mline = flipLine(mline, sld, scl);
                    end

                case 'right'
                    % Force right-facing midline
                    drc = obj.Direction;
                    if isempty(drc); drc = obj.getDirection(1, vsn); end

                    % Flip left if facing right
                    if strcmpi(drc, 'left')
                        mline = flipLine(mline, sld, scl);
                    end

                case 'int'
                    % Interpolated midline coordinates
                    if ~isempty(mline)
                        pts   = obj.MLINEINTRP;
                        mline = interpolateOutline(mline, pts);
                    else
                        return;
                    end

                case 'norm'
                    % Interpolated and zero-centered around origin
                    mline = obj.normalizeCurve('midline', vsn);

                otherwise
                    fprintf(2, 'Midline type %s must be [int|raw|left|right|norm]\n', ...
                        fnc);
                    mline = [];
                    return;
            end

            % Remap for buffering and re-scaling
            if mbuf ~= obj.MANBUF || scl ~= obj.IMGSCL
                mline = obj.Parent.contourRemap(mline, mbuf, scl);
            end

            obj.MidlineSize = size(mline, 1);
        end

        function [obj , mfix] = FixMidline(obj, fidx, interp_fixer, mth)
            %% Fix the raw midline coordinates (manual or auto)
            if nargin < 2; fidx         = 1;     end % Figure handle
            if nargin < 3; interp_fixer = 40;    end % Default interpolation size
            if nargin < 4; mth          = 'man'; end % Default to manually-trace

            vsn   = obj.MAINTRACE;
            fnc   = obj.MAINFUNC;
            img   = obj.getImage(fnc);
            mline = obj.getMidline(mth, 'raw');
            cntr  = obj.getTrace(vsn, fnc);
            mfix  = OutlineFixer('Object', obj, 'Image', img, 'Curve', mline, ...
                'Curve2', cntr, 'FigureIndex', fidx, 'InterpFix', interp_fixer);
        end

        function ptch = midlinePatch(obj, midx, fidx, mth, fnc)
            %% Sample image along midline index
            % Sampling image using square domains along midline
            % Input:
            %   midx: index along midline to sample image
            %   fidx: index to figure handle to visualize patches
            %   mth: method of midline to use [man|auto|nate] (default 'nate')
            %   fnc: method of midline to use [man|auto|nate] (default 'nate')
            if nargin < 2; midx = ':';          end % Default to all midline indices
            if nargin < 3; fidx = 0;            end % Don't visualize
            if nargin < 4; mth  = 'nate';       end % Default to NateMidline
            if nargin < 5; fnc  = obj.MAINFUNC; end % Default to original direction

            img   = obj.getImage(fnc);
            mline = obj.getMidline(mth, 'int');
            psz   = obj.MLINEPSIZE;

            % Generate square domains to use for sampling image
            toRemove            = [1 , 3 , 4]; % Omit domains for disk and lines
            [sq , s]            = deal(psz);
            [scls , doms , dsz] = setupParams( ...
                'toRemove', toRemove, 'squareScale', sq, 'squareDomain', s);

            % Sample image
            zm               = curve2framebundle(mline);
            [cm  , ~ , smpd] = ...
                sampleAtDomain(img, zm(midx,:), scls{1}, doms{1}, dsz{1}, 0);
            ptch             = reshape(cm, [sq , numel(midx)]);

            if fidx
                vscl = 5;
                tng  = arrayfun(@(x) ...
                    [(zm(x,3:4) * vscl) + zm(x,1:2) ; zm(x,1:2)], ...
                    1 : size(zm,1), 'UniformOutput', 0)';
                nrm  = arrayfun(@(x) ...
                    [(zm(x,5:6) * vscl) + zm(x,1:2) ; zm(x,1:2)], ...
                    1 : size(zm,1), 'UniformOutput', 0)';

                figclr(fidx);
                subplot(121);
                myimagesc(ptch);
                ttl = sprintf('Midline Patch %03d [%d %d]', ...
                    midx, size(ptch,1), size(ptch,2));
                title(ttl, 'FontSize', 10);

                subplot(122);
                myimagesc(img);
                hold on;
                cellfun(@(t) plt(t, 'b-', 2), tng, 'UniformOutput', 0);
                cellfun(@(n) plt(n, 'r-', 2), nrm, 'UniformOutput', 0);
                plt(smpd(1:2,:)', 'g.', 8);
                plt(zm(midx,1:2), 'y.', 10);

                ttl = sprintf('Sample %03d on Patch [%d %d]', ...
                    midx, size(ptch));
                title(ttl, 'FontSize', 10);
                drawnow;
            end
        end

        function [trc , bcrd] = normalizeCurve(obj, typ, midmth)
            %% Reconfigure interpolation size of raw midlines
            if nargin < 2;  typ    = 'trace'; end % Default to contour
            if nargin < 3;  midmth = 'nate';  end % Default to NateMidline

            switch typ
                case 'trace'
                    vsn = obj.MAINTRACE;
                    [trc , ~ , bcrd] = resetContourBase(obj.getTrace(vsn));

                case 'midline'
                    % Normalized midline
                    mline      = obj.getMidline(midmth, 'int');
                    [~ , bcrd] = obj.normalizeCurve('trace');
                    trc        = mline - bcrd;

                otherwise
                    fprintf(2, 'Method %s not found [trace|midline]\n', typ);
                    return;
            end
        end

        function obj = reconfigMidline(obj)
            %% Reset 1st midline coordinates to base of contours
            mline = obj.getMidline('auto', 'raw');
            if ~isempty(mline); obj.setMidline(mline, 'auto'); else; return; end
        end

        function [sp , sd] = getSPatch(varargin)
            %% Generates an S-Patch from a segment
            % This computes the S-Patch from the given segment each time, rather
            % than storing it in the object. This saves disk space, and will
            % deprecate the GenerateSPatches method.
            try
                obj     = varargin{1};
                segs    = obj.getSegmentedOutline;
                allSegs = 1 : obj.NumberOfSegments;
                img     = obj.getImage;

                switch nargin
                    case 1
                        % Get S-Patch for all segments
                        [sp , sd] = arrayfun(@(x) setSPatch(segs(:,:,x), img), ...
                            allSegs, 'UniformOutput', 0);
                    case 2
                        % Get S-Patch for single segment
                        sIdx = varargin{2};
                        [sp , sd] = setSPatch(segs(:,:,sIdx), img);
                    otherwise
                        fprintf(2, 'Segment index must be between 1 and %d\n', ...
                            obj.NumberOfSegments);
                        [sp , sd] = deal([]);
                end

            catch
                fprintf(2, 'Error getting S-Patch\n');
                [sp , sd] = deal([]);
            end
        end

        function [zp , zd] = getZPatch(varargin)
            %% Generates an Z-Patch from a segment's Z-Vector
            % This computes the S-Patch from the given segment each time, rather
            % than storing it in the object. This saves disk space, and will
            % deprecate the GenerateSPatches method.
            try
                obj = varargin{1};
                if obj.NumberOfSegments == 0; obj.getSegmentedOutline; end

                fnc     = obj.MAINFUNC;
                img     = double(obj.getImage(fnc));
                allSegs = 1 : obj.NumberOfSegments;
                z       = obj.getZVector(':', 1);

                switch nargin
                    case 1
                        % Get Z-Patch for all segments
                        [zp , zd] = arrayfun(@(x) setZPatch(z(x,:), img), ...
                            allSegs, 'UniformOutput', 0);
                    case 2
                        % Get S-Patch for single segment
                        sIdx = varargin{2};
                        [zp , zd] = setZPatch(z(sIdx,:), img);
                    case 3
                        % Get S-Patch at specific scale
                        sIdx = varargin{2};
                        scl  = varargin{3};
                        [zp , zd] = setZPatch(z(sIdx,:), img, scl, [], 2, []);

                    otherwise
                        fprintf(2, 'Segment index must be between 1 and %d\n', ...
                            obj.NumberOfSegments);
                        [zp , zd] = deal([]);
                end

            catch
                fprintf(2, 'Error getting Z-Patch\n');
                [zp , zd] = deal([]);
            end
        end
    end

    %% -------------------------- Helper Methods ---------------------------- %%
    methods (Access = public)
        %% Various helper methods
        function mid = getMidPoint(varargin)
            %% Returns all MidPoint values or MidPoint at requested segment
            switch nargin
                case 1
                    obj = varargin{1};
                    mid = obj.MidPoints;

                case 2
                    obj = varargin{1};
                    req = varargin{2};
                    try
                        pt  = reshape(obj.MidPoints, 2, size(obj.MidPoints,3))';
                        mid = pt(req,:);
                    catch
                        r = num2str(req);
                        fprintf(2, 'Error requesting MidPoint %s\n', r);
                    end

                otherwise
                    obj = varargin{1};
                    mid = obj.MidPoints;
            end
        end

        function prm = getParameter(varargin)
            %% Return all or single Ppar or Pmat
            switch nargin
                case 2
                    obj   = varargin{1};
                    param = varargin{2};
                    prm   = obj.(param);

                case 3
                    obj   = varargin{1};
                    param = varargin{2};
                    idx   = varargin{3};

                    if ismatrix(obj.(param))
                        prm = obj.(param)(idx);
                    else
                        prm = obj.(param)(:,:,idx);
                    end

                otherwise
                    fprintf(2, 'Input must be (param) or (param, idx)\n');
                    prm = [];
            end
        end

        function [fnm , ttl , itr] = makeName(obj)
            %% makeTitle: make a simple title for this object
            gnm  = obj.Parent.GenotypeName;
            gttl = fixtitle(gnm);
            sidx = obj.Parent.Parent.Parent.getSeedlingIndex;
            frm  = obj.Parent.getFrame;
            drc  = obj.Direction;

            % For files names
            fnm = sprintf('%s_%s_seedling%02d_frame%02d_face%s', ...
                tdate, gnm, sidx, frm, drc);

            % For figure titles
            ttl = sprintf('%s\nSeedling %d Frame %d', gttl, sidx, frm);

            % For console output
            itr = sprintf('%s | Seedling %d | Frame %d | Face %s', ...
                gnm, sidx, frm, drc);
        end

        function img = getImage(obj, req, rgn, drc, flp, mbuf, abuf, scl)
            %% getImage: return image data for Curve
            % Input:
            %   obj: this Curve object
            %   req: image type [gray | bw]
            %   rgn: region [upper | lower]
            %   drc: direction [left | right | []]
            %   flp: force fliped direction [0 | 1 | []]
            %   mbuf: cropped buffering [default 0]
            %   abuf: artificial buffering [default 0]
            %   scl: scaling from original size (101 x 101) [default 1]
            if nargin < 2; req  = 'gray';     end
            if nargin < 3; rgn  = 'upper';    end
            if nargin < 4; drc  = [];         end
            if nargin < 5; flp  = [];         end
            if nargin < 6; mbuf = obj.MANBUF; end
            if nargin < 7; abuf = obj.ARTBUF; end
            if nargin < 8; scl  = obj.IMGSCL; end

            % Use default direction and flip orientation
            if isempty(drc); drc = obj.Direction;           end
            if isempty(flp); flp = obj.Parent.checkFlipped; end

            img = obj.Parent.getImage(req, rgn, flp, mbuf, abuf, scl);

            if ~strcmpi(drc, obj.Direction); img = fliplr(img); end
        end

        function fnm = showCurve(varargin)
            %% showCurve: display features of this object
            [fidx , sav , clr , req , rgn , buf , vsn , fnc , mth] = ...
                deal([]);

            obj  = varargin{1};
            args = parseInputs(varargin(2:end));
            for fn = fieldnames(args)'
                feval(@()assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
            end

            %
            if clr; figclr(fidx); else; set(0, 'CurrentFigure', fidx); end
            img   = obj.getImage(req, rgn, fnc, buf);
            cntr  = obj.getTrace(vsn, fnc);
            mline = obj.getMidline(mth, fnc);
            bvec  = obj.getBotMid(vsn, fnc);

            %
            myimagesc(img);
            hold on;
            plt(cntr, 'g-', 2);
            plt(mline, 'r-', 2);
            plt(bvec, 'c.', 20);
            plt(bvec, 'ko', 5);
            hold off;

            %
            gnm  = obj.Parent.GenotypeName;
            gttl = fixtitle(gnm);
            sidx = obj.Parent.Parent.Parent.getSeedlingIndex;
            frm  = obj.Parent.getFrame;
            ttl  = sprintf('%s\nSeedling %d Frame %d', gttl, sidx, frm);
            title(ttl, 'FontSize', 10);

            %
            if sav
                cdir = 'showcurves';
                fnm  = sprintf('%s_%s_seedling%02d_frame%02d_face%s', ...
                    tdate, gnm, sidx, frm, fnc);
                saveFiguresJB(fidx, {fnm}, cdir);
            end

            %% Input Parser
            function args = parseInputs(varargin)
                %% Parse input parameters
                p = inputParser;

                p.addOptional('fidx', 1);
                p.addOptional('sav', 0);
                p.addOptional('clr', 0);
                p.addOptional('req', 'gray');
                p.addOptional('rgn', 'upper');
                p.addOptional('buf', 0);
                p.addOptional('vsn', obj.MAINTRACE);
                p.addOptional('fnc', obj.Direction);
                p.addOptional('mth', 'nate');

                % Parse arguments and output into structure
                p.parse(varargin{1}{:});
                args = p.Results;
            end
        end

        function prp = getProperty(obj, prp)
            %% Return property of this object
            try
                prp = obj.(prp);
            catch e
                fprintf(2, 'Property %s does not exist\n%s\n', ...
                    prp, e.getReport);
            end
        end

        function setProperty(obj, req, val)
            %% Set requested property if it exists [for private properties]
            try
                obj.(req) = val;
            catch e
                fprintf(2, 'Property %s not found\n%s\n', req, e.getReport);
            end
        end

        function resetProperty(obj, req)
            %% Reset property back to original value
            try
                cpy = Curve;
                val = cpy.getProperty(req);
                obj.setProperty(req, val);
            catch
                fprintf(2, 'Error resetting property %s\n', req);
                return;
            end
        end
    end

    %% ------------------------- Private Methods --------------------------- %%
    methods (Access = private)
        %% Private helper methods
    end
end

