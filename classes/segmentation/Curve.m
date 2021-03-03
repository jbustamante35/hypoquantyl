%% Curve: class for handling contours and curves
% Descriptions

classdef Curve < handle
    properties (Access = public)
        Parent
        NumberOfSegments
        TraceSize
        MidlineSize
    end
    
    properties (Access = protected)
        SEGMENTSIZE    = 25;        % Number of coordinates per segment [default 200]
        SEGMENTSTEPS   = 1;         % Size of step to next segment [default 50]
        ENVELOPESIZE   = 11;        % Hard-coded max distance from original segment to envelope
        MLINEINTRP     = 50;        % Default size to interpolate midline
        MLINETERMINATE = 0.7;       % Default termination percent for midline
        MLINEPSIZE     = [10 , 10]; % Default sampling size for midline patch
        Trace
        ManMidline
        AutoMidline
        SVectors          % TO BE REMOVED [but still needs method to compute]
%         RawMidline        % TO BE REMOVED
%         ZVector           % TO BE REMOVED
%         BackTrace         % TO BE REMOVED
%         RawSegments       % TO BE REMOVED
%         SPatches          % TO BE REMOVED
%         ZPatches          % TO BE REMOVED
%         Pmats             % TO BE REMOVED
%         Ppars             % TO BE REMOVED
%         SData             % TO BE REMOVED
%         ZData             % TO BE REMOVED
%         EnvelopeSegments  % TO BE REMOVED
%         EndPoints         % TO BE REMOVED
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
                'TraceSize', 0};
            obj    = classInputParser(obj, prps, deflts, vargs);
            
        end
        
        function trc = getTrace(obj, req)
            %% Returns the manually-drawn contour
            switch nargin
                case 1
                    trc = obj.Parent.FullOutline;
                case 2
                    switch req
                        case 'int'
                            trc           = obj.Parent.FullOutline;                            
                            obj.TraceSize = size(trc, 1);
                        
                        case 'raw'
                            % Used for manually-traced contours (I think)
                            trc = obj.Parent.getRawOutline;
                        
                        case 'norm'
                            trc = obj.normalizeCurve('trace');
                        
                        case 'back'
                            [trc , ~] = obj.normalizeCurve('trace');
                            
                        otherwise
                            fprintf(2, 'Trace %s must be [int|raw|norm]\n', req);
                            trc = [];
                    end
                    
                otherwise
                    fprintf(2, 'Error getting trace\n');
                    trc = [];
            end
            
            
        end
        
        function Z = getZVector(obj, ndims, addMid, rot)
            %% Compute the Z-Vector skeleton for this contour
            % This will compute the Z-Vector each time, rather than storing it
            % in a variable after being run once. This will deprecate the
            % ZVector property.
            
            switch nargin
                case 1
                    ndims  = ':';
                    addMid = 0;
                    rot    = 0;
                case 2
                    addMid = 0;
                    rot    = 0;
                case 3
                    rot = 0;
            end
            
            % Returns the dimensions from ndims [default to all]
            Z = contour2corestructure(...
                obj.getTrace, obj.SEGMENTSIZE, obj.SEGMENTSTEPS);
            
            if addMid
                mid = Z(:,1:2);
                Z   = [mid , Z(:,3:4) + mid , Z(:,5:6) + mid];
            end
            
            Z = Z(:, ndims);
            
            if rot
                Z = zVectorConversion(Z, [], [], 'rot');
            end
            
        end
        
        function segs = getSegmentedOutline(varargin)
            %% Compute the segmented outline
            % This will segment the outline each time, rather than storing it
            % into the object after being run once. This will deprecate the
            % SegmentOutline method.
            try
                obj = varargin{1};
                trc = obj.getTrace;
                
                switch nargin
                    case 1
                        len = obj.SEGMENTSIZE;
                        stp = obj.SEGMENTSTEPS;
                        
                    case 3
                        len = varargin{2};
                        stp = varargin{3};
                        obj.setProperty('SEGMENTSIZE', len);
                        obj.setProperty('SEGMENTSTEPS', stp);
                        
                    otherwise
                        len = obj.SEGMENTSIZE;
                        stp = obj.SEGMENTSTEPS;
                        msg = sprintf(...
                            ['Input must be (segment_size, steps_per_segment)\n', ...
                            'Segmenting with default parameters (%d, %d)\n'], ...
                            len, stp);
                        fprintf(2, msg);
                        
                end
                segs                 = split2Segments(trc, len, stp);
                obj.NumberOfSegments = size(segs,3);
                
            catch
                fprintf(2, 'Error splitting outline into multiple segments\n');
            end
        end
        
        function nsegs = getNormalizedSegments(obj)
            %% Generates the segments in the Midpoint-Normalized Frame
            % This computes the normalized segments from the contour each time,
            % rather than storing it in the object. This saves disk space, and
            % will deprecate the NormalizeSegments method.
            segs = obj.getSegmentedOutline;
            nsegs = arrayfun(@(x) midpointNorm(segs(:,:,x), 'new'), ...
                1 : obj.NumberOfSegments, 'UniformOutput', 0);
            nsegs = cat(3, nsegs{:});
            
        end
        
        function obj = DrawMidline(obj, fidx, showcnt)
            %% Draw midline on this image
            % This method is effectively DrawOutline from the CircuitJB class,
            % I literally just changed the name from Outline to Midline.
            %
            % Input:
            %   obj: this Curve object
            %   fidx: figure handle to plot onto
            %   pline: primed midline computed from distance transform
            %   showcnt: show contour when tracing midline
            
            switch nargin
                case 1
                    fidx    = 1;
                    showcnt = 1;
                case 2
                    showcnt = 1;
                case 3
                otherwise
                    fprintf(2, 'Error with inputs (%d)\n', nargin);
                    return;
            end
            
            try
                % Trace outline and store as RawOutline
                figclr(fidx);
                img   = obj.getImage;
                cntr  = obj.getTrace;
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
                obj.setRawMidline(mline);
                
            catch e
                frm = obj.Parent.getFrame;
                fprintf(2, 'Error setting outline at frame %d \n%s\n', ...
                    frm, e.getReport);
            end
        end
        
        function [obj , mline] = setRawMidline(obj, mline, typ)
            %% Set coordinates for traced midline or autogenerate it
            % Input:
            %   obj: this Curve object
            %   mline: raw coordinates for midline
            %   typ: manual or automatic generation of midline (default 'man')
            if nargin < 3
                typ = 'man';
            end
            
            switch typ
                case 'man'
                    try
                        % Anchor first coordinate to base of contour
                        trc        = obj.getTrace;
                        [~ , bidx] = resetContourBase(trc);
                        mline(1,:) = trc(bidx,:);
                        
                        obj.ManMidline = mline;
                        
                    catch e
                        fprintf(2, 'Error setting ManMidline\n%s\n', ...
                            e.getReport);
                    end
                    
                case 'auto'
                    try
                        % Use traditional methods to extract midline
                        img   = obj.getImage;
                        trc   = obj.getTrace;
                        intrp = obj.MLINEINTRP;
                        tpct  = obj.MLINETERMINATE;
                        mline = primeMidline(img, trc, intrp, tpct);
                        
                        obj.AutoMidline = mline;
                        
                    catch e
                        fprintf(2, 'Error generating AutoMidline\n%s\n', ...
                            e.getReport);
                    end
            end
            
        end
        
        function mline = getMidline(obj, typ, mth)
            %% Return raw or interpolated midline
            % Computes interpolated or normalized midline at execution. This
            % saves memory by not storing them in the object.
            switch nargin
                case 1
                    typ = 'int'; % Prefer interpolated
                    mth = 'man'; % Prefer manually-traced
                case 2
                    mth = 'man'; % Prefer manually-traced
            end
            
            % Get manually-traced or automated midline
            switch mth
                case 'man'
                    mline = obj.ManMidline;
                case 'auto'
                    mline = obj.AutoMidline;
                otherwise
                    fprintf(2, 'Midline method %s must be [man|auto]\n', mth);
            end
            
            % Get interpolated, raw, or origin-centered midline
            switch typ
                case 'int'
                    % Interpolated midline coordinates
                    if ~isempty(mline)
                        pts   = obj.MLINEINTRP;
                        mline = interpolateOutline(mline, pts);
                        
                        obj.MidlineSize = pts;
                    else
                        mline = [];
                        return;
                    end
                    
                case 'raw'
                    % Get raw coordinates
                    
                case 'norm'
                    % Interpolated and zero-centered around origin
                    mline = obj.normalizeCurve('midline', mth);
                    
                otherwise
                    fprintf(2, 'Midline type %s must be [int|raw|norm]\n', typ);
                    mline = [];
                    return;
            end
            
        end
        
        function [obj , mfix] = FixMidline(obj, fidx, interp_fixer, mth)
            %% Fix the raw midline coordinates (manual or auto)
            switch nargin
                case 1
                    fidx         = 1;
                    interp_fixer = 40;
                    mth          = 'man'; % Default to manually-traced
                case 2
                    interp_fixer = 40;
                    mth         = 'man'; % Default to manually-traced
                case 3
                    mth = 'man';  % Default to manually-traced
            end
            
            img   = obj.getImage;
            mline = obj.getMidline('raw', mth);
            cntr  = obj.getTrace;
            mfix  = OutlineFixer('Object', obj, 'Image', img, 'Curve', mline, ...
                'Curve2', cntr, 'FigureIndex', fidx, 'InterpFix', interp_fixer);
            
        end
        
        function ptch = midlinePatch(obj, midx, fidx, mth)
            %% Sample image along midline index
            % Sampling image using square domains along midline
            % Input:
            %   midx: index along midline to sample image
            %   fidx: index to figure handle to visualize patches
            %   mth: method of midline to use [man|auto] (default 'man')
            switch nargin
                case 1
                    midx = ':';   % Default to all midline indices
                    fidx = 0;     % Don't visualize
                    mth  = 'man'; % Default to manually-traced midline
                case 2
                    fidx = 0;     % Don't visualize
                    mth  = 'man'; % Default to manually-traced midline
                case 3
                    mth = 'man'; % Default to manually-traced midline
            end
            
            img   = obj.getImage;
            mline = obj.getMidline('int', mth);
            psz   = obj.MLINEPSIZE;
            % Generate square domains to use for sampling image
            toRemove            = [1 , 3 , 4]; % Omit domains for disk and lines
            [sq , s]            = deal(psz);
%             sq                  = [10 , 10]; % Can't set dot density
%             s                  = [20 , 20];
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
                myimagesc(obj.getImage);
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
            if nargin < 3
                midmth = 'man'; % Default to manually-traced midline
            end
            
            switch typ
                case 'trace'
                    [trc , ~ , bcrd] = ...
                        resetContourBase(obj.getTrace);
                    
                case 'midline'
                    % Normalized midline
                    mline      = obj.getMidline('int', midmth);
                    [~ , bcrd] = obj.normalizeCurve('trace');
                    trc        = mline - bcrd;
                    
                otherwise
                    fprintf(2, 'Method %s not found [trace|midline]\n', typ);
                    return;
            end
        end
        
        function obj = reconfigMidline(obj)
            %% Reset 1st midline coordinates to base of contours
            mline = obj.getMidline('raw');
            
            if ~isempty(mline)
                obj.setRawMidline(mline);
            else
                return;
            end
            
        end
        
        function obj = Normal2Envelope(obj, par)
            %% Convert SVectors to coordinates within envelope
            % Uses the envelope method to convert normalized coordinates to
            % coordinates within an envelope structure (see envelopeMethod()).
            
            % Generate S-Patches if haven't already
            if isempty(obj.SPatches)
                obj.GenerateSPatches(par);
            end
            
            % Get distance to envelope.
            envMax  = obj.ENVELOPESIZE;
            allSegs = 1:obj.NumberOfSegments;
            
            % Convert normalized coordinates to envelope coordinates
            env = arrayfun(@(x) envelopeMethod(obj.SVectors(:,:,x), ...
                obj.SVectors(:,:,x), envMax), allSegs, 'UniformOutput', 0);
            obj.EnvelopeSegments = cat(3, env{:});
            
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
                if obj.NumberOfSegments == 0
                    obj.getSegmentedOutline;
                end
                
                img     = double(obj.getImage('gray'));
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
        
        function nrm = Envelope2Normal(obj)
            %% Convert EnvelopeSegments to midpoint-normalized coordinates
            % This uses the inverse of the envelope method to revert envelope
            % segments back to normalized segments (see reverseEnvelopeMethod).
            nrm = reverseEnvelopeMethod(obj.EnvelopeSegments, obj.ENVELOPESIZE);
            
        end
        
        function raw = Envelope2Raw(obj)
            %% Convert segment in envelope coordinates to raw coordinates
            % [TODO] This needs to be changed in the future to be able to use
            % the predicted envelope segments.
            env     = obj.EnvelopeSegments;
            crv     = obj.SVectors;
            sz      = obj.ENVELOPESIZE;
            pm      = obj.Pmats;
            mid     = obj.getZVector(1:2);
            allSegs = 1 : obj.NumberOfSegments;
            
            % Iterate through envelope segments and convert to image segments
            env2raw = @(n) envelope2coords(env(:,:,n), crv(:,:,n), ...
                sz, pm(:,:,n), mid(:,:,n));
            raw = arrayfun(@(n) env2raw(n), allSegs, 'UniformOutput', 0);
            raw = cat(3, raw{:});
            
        end
        
        function [X , Y , XY] = rasterizeSegments(obj)
            %% Rasterize all segments of requested type
            % This method is used to prepare for Principal Components Analysis.
            % The req parameter is the requested segment type to rasterize and
            % should be RawSegments, SVectors, or EnvelopeSegments.
            try
                nsegs = obj.getNormalizedSegments;
                X     = squeeze(nsegs(:,1,:))';
                Y     = squeeze(nsegs(:,2,:))';
                XY    = [X , Y];
            catch
                fprintf(2, 'Error rasterizing %d segments\n', size(nsegs,3));
                [X, Y] = deal([]);
            end
            
        end
        
        function [XY , X , Y] = rasterizeCurve(obj, typ, midmth)
            %% Rasterize contour or midline coordinates
            if nargin < 3
                midmth = 'man'; % Default to manually-traced midline
            end
            
            switch typ
                case 'contour'
                    crv = obj.getTrace('norm');
                
                case 'midline'
                    crv = obj.getMidline('norm', midmth);
                
                otherwise
                    fprintf(2, 'Selected curve should be [contour|midline] %s\n', ...
                        typ);
                    [XY , X , Y] = deal([]);
                    return;
            end
            
            X  = crv(:,1)';
            Y  = crv(:,2)';
            XY = [X , Y];
            
        end
        
        function img = getImage(varargin)
            %% Return image data for Curve at desired frame
            obj = varargin{1};
            switch nargin
                case 1
                    try
                        % Get image from ImageDataStore
                        img = obj.Parent.getImage;
                    catch
                        % Check if hard-set image in the parent object
                        img = obj.Parent.getHardImage.gray;
                    end
                case 2
                    req = varargin{2};
                    img = obj.Parent.getImage(req);
                case 3
                    flp = varargin{3};
                    img = obj.Parent.getImage(0, flp);
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
        
        function obj = setProperty(obj, req, val)
            %% Set requested property if it exists [for private properties]
            try
                obj.(req) = val;
            catch e
                fprintf(2, 'Property %s not found\n%s\n', req, e.getReport);
            end
        end
        
        function obj = resetProperty(obj, req)
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
        function obj = loadRawSegmentData(obj, trace, segment_length, step_size)
            %% Set data for RawSegments, EndPoints, and NumberOfSegments
            %% NOTE [10.02.2019]
            % Splitting methods were optimized, but now makes one more segment
            % than the old method. Run the full dataset through the pipelines
            % when all the optimizations are done.
            obj.RawSegments      = ...
                split2Segments(trace, segment_length, step_size, 1);
            obj.NumberOfSegments = size(obj.RawSegments,3);
            
        end
        
        function [img, medBg, Pmat, midpoint] = getMapParams(obj, segIdx)
            %% Returns parameters for mapping curve to image for setImagePatch
            %% [NOTE] Deprecated [08.21.2019]
            img      = double(obj.getImage('gray'));
            msk      = obj.getImage('bw');
            medBg    = median(img(msk == 1));
            Pmat     = obj.getParameter('Pmats', segIdx);
            midpoint = obj.getMidPoint(segIdx);
            
        end
        
    end
end

