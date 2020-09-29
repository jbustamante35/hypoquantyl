%% Cuve: class for sections of contours for a CircuitJB object
% Descriptions

classdef Curve < handle
    properties (Access = public)
        Parent
        NumberOfSegments
        TraceSize
    end
    
    properties (Access = protected)
        SEGMENTSIZE  = 25; % Number of coordinates per segment [default 200]
        SEGMENTSTEPS = 1;  % Size of step to next segment [default 50]
        ENVELOPESIZE = 11; % Hard-coded max distance from original segment to envelope
        Trace
        RawSegments
        SVectors
        ZVector
        SPatches
        ZPatches
        Pmats
        Ppars
        SData
        ZData
        EnvelopeSegments
        EndPoints
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
        
        function obj = RunFullPipeline(obj, par)
            %% Runs full pipeline from Parent's Trace to generate ImagePatch
            % par: 0 to use normal for loop, 1 to use with parallel processing
            if nargin < 2
                par = 0;
            end
            
            tRun = tic;
            msg  = repmat('-', 1, 80);
            fprintf('\n%s\nRunning Full Pipeline for %s...', ...
                msg, obj.Parent.Origin);
            
            % tic; fprintf('Splitting full outline...')            ; obj.SegmentOutline         ; fprintf('done [%.02f sec]\n', toc);
            % tic; fprintf('Midpoint Normalization conversion...') ; obj.NormalizeSegments(par) ; fprintf('done [%.02f sec]\n', toc);
            % tic; fprintf('Generating S-Patches...')              ; obj.GenerateSPatches(par)  ; fprintf('done [%.02f sec]\n', toc);
            % tic; fprintf('Generating Z-Patches...')              ; obj.GenerateZPatches(par)  ; fprintf('done [%.02f sec]\n', toc);
            % tic; fprintf('Envelope coordinates conversion...')   ; obj.Normal2Envelope(par)   ; fprintf('done [%.02f sec]\n', toc);
            
            fprintf('DONE! [%.02f sec ]\n%s', toc(tRun), msg);
            
        end
        
        function trc = getTrace(obj, req)
            %% Returns the manually-drawn contour
            switch nargin
                case 1
                    trc = obj.Parent.FullOutline;
                case 2
                    switch req
                        case 'int'
                            trc = obj.Parent.FullOutline;
                        case 'raw'
                            % Used for manually-traced contours (I think)
                            trc = obj.Parent.RawOutline;
                        otherwise
                            fprintf(2, 'Trace %s must be [int|raw]\n', req);
                            trc = [];
                    end
                otherwise
                    fprintf(2, 'Error getting trace\n');
                    trc = [];
            end
            
            obj.TraceSize = size(trc, 1);
            
        end
        
        function Z = getZVector(obj, ndims, addMid)
            %% Compute the Z-Vector skeleton for this contour
            % This will compute the Z-Vector each time, rather than storing it
            % in a variable after being run once. This will deprecate the
            % ZVector property.
            
            switch nargin
                case 1
                    ndims  = ':';
                    addMid = 0;
                case 2
                    addMid = 0;
            end
            
            % Returns the dimensions from ndims [default to all]
            Z = contour2corestructure(...
                obj.getTrace, obj.SEGMENTSIZE, obj.SEGMENTSTEPS);
            
            if addMid
                mid = Z(:,1:2);
                Z   = [mid , Z(:,3:4) + mid , Z(:,5:6) + mid];
            end
            
            Z = Z(:, ndims);
            
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
            mid     = obj.ZVector(:,1:2);
            allSegs = 1 : obj.NumberOfSegments;
            
            % Iterate through envelope segments and convert to image segments
            env2raw = @(n) envelope2coords(env(:,:,n), crv(:,:,n), ...
                sz, pm(:,:,n), mid(:,:,n));
            raw = arrayfun(@(n) env2raw(n), allSegs, 'UniformOutput', 0);
            raw = cat(3, raw{:});
            
        end
        
        function [X, Y] = rasterizeSegments(obj)
            %% Rasterize all segments of requested type
            % This method is used to prepare for Principal Components Analysis.
            % The req parameter is the requested segment type to rasterize and
            % should be RawSegments, SVectors, or EnvelopeSegments.
            try
                nsegs = obj.getNormalizedSegments;
                X     = squeeze(nsegs(:,1,:))';
                Y     = squeeze(nsegs(:,2,:))';
            catch
                fprintf(2, 'Error rasterizing %d segments\n', size(nsegs,3));
                [X, Y] = deal([]);
            end
            
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
            %
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

