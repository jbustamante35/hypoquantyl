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
    
    %     properties (Constant)
    %         SEGLENGTH = [53 , 52 , 53 , 51];
    %     end
    
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
        
        function trc = getTrace(obj, vsn, fnc)
            %% Returns contour type and function to do on contour
            if nargin < 2; vsn = obj.MAINTRACE; end
            if nargin < 3; fnc = obj.MAINFUNC;  end
            
            trc = obj.Parent.getOutline(vsn);
            switch fnc
                case 'raw'
                    % Just return un-processed contour
                    
                case 'interp'
                    % Interpolate to specific size
                    npts = obj.Parent.getProperty('INTERPOLATIONSIZE');
                    trc  = interpolateOutline(trc, npts);
                    
                case 'reverse'
                    % Flip and Slide to opposite direction
                    seg_lengths = obj.SEGLENGTH;
                    trc         = flipAndSlide(trc, seg_lengths);
                    
                case 'left'
                    % Get left-facing contour
                    drc = obj.Direction;
                    if isempty(drc); drc = obj.getDirection(1, vsn); end
                    
                    % Flip left if facing right
                    if strcmpi(drc, 'right')
                        seg_lengths = obj.SEGLENGTH;
                        trc         = flipAndSlide(trc, seg_lengths);
                    end
                    
                case 'right'
                    % Get left-facing contour
                    drc = obj.Direction;
                    if isempty(drc); drc = obj.getDirection(1, vsn); end
                    
                    % Flip right if facing left
                    if strcmpi(drc, 'left')
                        seg_lengths = obj.SEGLENGTH;
                        trc         = flipAndSlide(trc, seg_lengths);
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
                        req);
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
            %   nsplt:
            %   midx:
            %   addMid:
            %   rot:
            %   rtyp:
            %   dpos:
            %
            % Output:
            %   Z:
            %
            
            %% Parse inputs
            [ndims , vsn , fnc , nsplt , midx , addMid , rot , rtyp , dpos , ...
                bdsp] = deal([]);
            obj  = varargin{1};
            args = parseInputs(varargin(2:end));
            for fn = fieldnames(args)'
                feval(@()assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
            end
            
            %% Returns the dimensions from ndims [default to all]
            trc = obj.getTrace(vsn, fnc);
            stp = obj.SEGMENTSTEPS;
            Z   = contour2corestructure(trc, nsplt, stp, midx);
            
            % Add midpoints to tangent and normal
            if addMid
                mid = Z(:,1:2);
                Z   = [mid , Z(:,3:4) + mid , Z(:,5:6) + mid];
            end
            
            % Return specified dimensions
            if ~ndims; ndims  = ':'; end
            Z = Z(:, ndims);
            
            % Convert tangent-normal to rotation vector
            if rot
                % Convert to radians (default) or degrees
                Z = zVectorConversion(Z, [], [], 'rot', rtyp, dpos);
            end
            
            % Displace by midpoint of contour's base
            if bdsp
                if isempty(obj.BasePoint)
                    obj.setBasePoint(vsn, fnc);                    
                end                    
                
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
                p.addOptional('nsplt', obj.SEGMENTSIZE);
                p.addOptional('midx', obj.TOCENTER);
                p.addOptional('addMid', 0);
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
        
        function seg = getSegment(obj, idx, vsn, fnc, trc)
            %% Get top, bottom, left, or right
            if nargin < 3; vsn = obj.MAINTRACE; end
            if nargin < 4; fnc = obj.MAINFUNC;  end
            if nargin < 5; trc = [];            end
            
            if isempty(trc); trc = obj.getTrace(vsn, fnc); end
            
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
        
        function crn = getCornerPoint(obj, num, vsn, fnc)
            %%
            if nargin < 3; vsn = obj.MAINTRACE; end
            if nargin < 4; fnc = obj.MAINFUNC;  end
            
            trc = obj.getTrace(vsn, fnc);
            idx = obj.getIndex(num);
            crn = trc(idx,:);
        end
        
        function mid = getTopMid(obj, vsn, fnc)
            %%
            if nargin < 2; vsn = obj.MAINTRACE; end
            if nargin < 3; fnc = obj.MAINFUNC;  end
            
            seg = obj.getSegment(2, vsn, fnc);
            mid = mean(seg,1);
        end
        
        function mid = getBotMid(obj, vsn, fnc)
            %%
            if nargin < 2; vsn = obj.MAINTRACE; end
            if nargin < 3; fnc = obj.MAINFUNC;  end
            
            seg = obj.getSegment(4, vsn, fnc);
            mid = mean(seg,1);
        end
        
        function [nrm , tng] = getTopNorm(obj, vsn, fnc)
            %%
            if nargin < 2; vsn = obj.MAINTRACE; end
            if nargin < 3; fnc = obj.MAINFUNC;  end
            
            top = obj.getSegment(2, vsn, fnc);
            tng = top(end,:) - top(1,:);
            tng = tng / norm(tng);
            nrm = [tng(2) , -tng(1)];
        end
        
        function [nrm , tng] = getBotNorm(obj, vsn, fnc)
            %%
            if nargin < 2; vsn = obj.MAINTRACE; end
            if nargin < 3; fnc = obj.MAINFUNC;  end
            
            top = obj.getSegment(4, vsn, fnc);
            tng = top(end,:) - top(1,:);
            tng = tng / norm(tng);
            nrm = [tng(2) , -tng(1)];
        end
        
        function plotNorms(obj, fidx, ovr, vsn, fnc)
            %%
            if nargin < 2; fidx = 1;             end
            if nargin < 3; ovr  = 1;             end
            if nargin < 4; vsn  = obj.MAINTRACE; end
            if nargin < 5; fnc  = obj.MAINFUNC;  end
            
            tmid          = obj.getTopMid(vsn, fnc);
            bmid          = obj.getBotMid(vsn, fnc);
            [tnrm , ttng] = obj.getTopNorm(vsn, fnc);
            [bnrm , btng] = obj.getBotNorm(vsn, fnc);
            bnrm = -bnrm;
            
            if ~ovr
                figclr(fidx);
                myimagesc(obj.getImage);
                hold on;
            end
            
            quiver(tmid(1), tmid(2), tnrm(1), tnrm(2), 30, 'Color', 'c');
            quiver(tmid(1), tmid(2), ttng(1), ttng(2), 30, 'Color', 'b');
            quiver(bmid(1), bmid(2), bnrm(1), bnrm(2), 30, 'Color', 'm');
            quiver(bmid(1), bmid(2), btng(1), btng(2), 30, 'Color', 'r');
        end
        
        function plotSegments(obj, fidx, sidx, vsn, fnc)
            %%
            if nargin < 2; fidx = 1;             end
            if nargin < 3; sidx = 1 : 4;         end
            if nargin < 4; vsn  = obj.MAINTRACE; end
            if nargin < 5; fnc  = obj.MAINFUNC;  end
            
            figclr(fidx);
            myimagesc(obj.getImage(fnc));
            hold on;
            clrs = {'r-' , 'g-' , 'b-' , 'y-'};
            for e = sidx
                seg = obj.getSegment(e, vsn, fnc);
                plt(seg, clrs{e}, 2);
            end
        end
        
        function plotCorners(obj, fidx, sidx, ovr, vsn, fnc)
            %%
            if nargin < 2; fidx = 1;             end
            if nargin < 3; sidx = 1 : 4;         end
            if nargin < 4; ovr  = 1;             end
            if nargin < 5; vsn  = obj.MAINTRACE; end
            if nargin < 6; fnc  = obj.MAINFUNC;  end
            
            clrs = {'r.' , 'g.' , 'b.' , 'y.'};
            if ~ovr
                figclr(fidx);
                myimagesc(obj.getImage);
                hold on;
            end
            
            for e = sidx
                crn = obj.getCornerPoint(e, vsn, fnc);
                plt(crn, 'k.', 25);
                plt(crn, clrs{e}, 20);
            end
        end
        
        function plotMidline(obj, fidx, ovr, vsn, fnc)
            %%
            if nargin < 2; fidx = 1;             end
            if nargin < 3; ovr  = 1;             end
            if nargin < 4; vsn  = 'nate';        end
            if nargin < 5; fnc  = obj.MAINFUNC;  end
            
            if ~ovr
                figclr(fidx);
                myimagesc(obj.getImage(fnc));
                hold on;
            end
            
            mline = obj.getMidline(vsn, fnc);
            plt(mline, 'r--', 2);
        end
        
        function plotHypocotyl(obj, fidx, vsn, fnc, mid)
            %% plotHypocotyl
            if nargin < 2; fidx = 1;             end
            if nargin < 3; vsn  = obj.MAINTRACE; end
            if nargin < 4; fnc  = obj.MAINFUNC;  end
            if nargin < 5; mid  = 'nate';        end
            
            obj.plotSegments(fidx, 1 : 4, vsn, fnc);
            obj.plotCorners(fidx, 1 : 4, 1, vsn, fnc);
            obj.plotNorms(fidx, 1, vsn, fnc);
            
            if ~isempty(mid)
                obj.plotMidline(fidx, 1, mid, fnc);
            end
            
            drawnow;
        end
        
        function lng = getSegmentLength(obj, num, vsn, fnc, trc)
            %% getSegmentLength
            if nargin < 3; vsn = obj.MAINTRACE; end
            if nargin < 4; fnc = obj.MAINFUNC;  end
            if nargin < 5; trc = [];            end
            
            seg = obj.getSegment(num, vsn, fnc, trc);
            lng = sum(sum(diff(seg, 1, 1).^2, 2).^0.5);
        end
        
        function [drc1 , drc2] = getDirection(obj, toSet, vsn)
            %% getDirection
            if nargin < 2; toSet = 0;             end % Set Direction property
            if nargin < 3; vsn   = obj.MAINTRACE; end
            if nargin < 4; fnc   = obj.MAINFUNC;  end
            
            trc = obj.getTrace(vsn, 'raw');
            l1  = obj.getSegmentLength(1, vsn, fnc, trc);
            l3  = obj.getSegmentLength(3, vsn, fnc, trc);
            
            if l3 > l1
                drc1 = -1;
                drc2 = 'left';
            else
                drc1 = 1;
                drc2 = 'right';
            end
            
            if toSet
                obj.Direction = drc2;
            end
        end
        
        function setBasePoint(obj, vsn, fnc)
            %% setBasePoint
            if nargin < 2; vsn = obj.MAINTRACE; end
            if nargin < 3; fnc = obj.MAINFUNC;  end
            
            obj.BasePoint = obj.getBotMid(vsn, fnc);
        end
        
        function agl = getApicalAngle(obj, vsn, fnc)
            %% getApicalAngle
            if nargin < 2; vsn = obj.MAINTRACE; end
            if nargin < 3; fnc = obj.MAINFUNC;  end
            
            nrm = obj.getTopNorm(vsn, fnc);
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
                vsn = obj.MAINTRACE;
                fnc = obj.MAINFUNC;
                
                figclr(fidx);
                img   = obj.getImage(fnc);
                cntr  = obj.getTrace(vsn, fnc);
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
        
        function [mline , skl] = setMidline(obj, mline, typ, vsn, fnc)
            %% Set coordinates for traced midline or autogenerate it
            % Input:
            %   obj: this Curve object
            %   mline: raw coordinates for midline
            %   typ: manual or automatic generation of midline (default 'man')
            %
            % Output:
            %   mline:
            %   skl:
            
            if nargin < 2; mline = [];            end % Default to empty
            if nargin < 3; typ   = 'man';         end % Default manually-traced
            if nargin < 4; vsn   = obj.MAINTRACE; end % Default clipped contour
            if nargin < 5; fnc   = obj.MAINFUNC;  end % Default contour direction
            
            skl = [];
            switch typ
                case 'man'
                    %% Manually trace midline
                    try
                        % Anchor first coordinate to base of contour
                        trc        = obj.getTrace(vsn, fnc);
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
                        
                        img   = obj.getImage(fnc);
                        trc   = obj.getTrace(vsn, fnc);
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
                        trc  = obj.getTrace(vsn, fnc);
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
        
        function mline = getMidline(obj, mth, typ)
            %% Return raw or interpolated midline
            % Computes interpolated or normalized midline at execution. This
            % saves memory by not storing them in the object.
            if nargin < 2; mth = 'auto'; end % Default auto-generated
            if nargin < 3; typ = 'int';  end % Default interpolated
            
            % Get midline type
            switch mth
                case 'man';  mline = obj.ManMidline;
                case 'auto'; mline = obj.AutoMidline;
                case 'nate'; mline = obj.NateMidline;
                otherwise
                    fprintf(2, 'Midline method %s must be [man|auto|nate]\n', ...
                        mth);
            end
            
            % Get interpolated, raw, or origin-centered midline
            switch typ
                case 'int'
                    % Interpolated midline coordinates
                    if ~isempty(mline)
                        pts   = obj.MLINEINTRP;
                        mline = interpolateOutline(mline, pts);
                    else
                        return;
                    end
                    
                case 'raw'
                    % Keep raw coordinates
                    
                case 'left'
                    % Force left-facing midline
                    drc = obj.Direction;
                    if isempty(drc); drc = obj.getDirection(1, vsn); end
                    
                    % Flip left if facing right
                    if strcmpi(drc, 'right')                      
                        mline = flipLine(mline, obj.SEGLENGTH(end));
                    end
                    
                case 'right'
                    % Force right-facing midline
                    drc = obj.Direction;
                    if isempty(drc); drc = obj.getDirection(1, vsn); end
                    
                    % Flip left if facing right
                    if strcmpi(drc, 'left')
                        mline = flipLine(mline, obj.SEGLENGTH(end));
                    end
                    
                case 'norm'
                    % Interpolated and zero-centered around origin
                    mline = obj.normalizeCurve('midline', mth);
                    
                otherwise
                    fprintf(2, 'Midline type %s must be [int|raw|left|right|norm]\n', ...
                        typ);
                    mline = [];
                    return;
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
            ptch = reshape(cm, [sq , numel(midx)]);
            
            if fidx
                vscl = 5;
                tng  = arrayfun(@(x) [(zm(x,3:4) * vscl) + zm(x,1:2) ; zm(x,1:2)], ...
                    1 : size(zm,1), 'UniformOutput', 0)';
                nrm  = arrayfun(@(x) [(zm(x,5:6) * vscl) + zm(x,1:2) ; zm(x,1:2)], ...
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
            
            if ~isempty(mline)
                obj.setMidline(mline, 'auto');
            else
                return;
            end
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
        
        function img = getImage(varargin)
            %% Return image data for Curve at desired frame
            obj = varargin{1};
            switch nargin
                case 1
                    % Get image from ImageDataStore
                    img = obj.Parent.getImage;
                case 2
                    req = varargin{2};
                    if sum(strcmpi(req, {'gray' , 'bw'}))
                        % Get grayscale or bw image
                        img = obj.Parent.getImage(req);
                    elseif sum(strcmpi(req, {'left' , 'right'}))
                        % Get left-facing or right-facing [default to grayscale]
                        img = obj.Parent.getImage;
                        if ~strcmpi(req, obj.Direction)
                            img = fliplr(img);
                        end
                    else
                        img = obj.Parent.getImage;
                    end
                case 3
                    req = varargin{2};
                    buf = varargin{3}; % Buffer image
                    img = obj.Parent.getImage(req, buf);
                otherwise
                    fprintf(2, 'Error getting image\n');
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

