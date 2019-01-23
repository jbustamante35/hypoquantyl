%% Cuve: class for sections of contours for a CircuitJB object
% Descriptions

classdef Curve < handle
    properties (Access = public)
        Parent
        Trace
        NumberOfSegments
        RawSegments
        NormalSegments
        EnvelopeSegments
        RawSmooth
        NormalSmooth
        EnvelopeSmooth
        MidPoints
        Tangents
        Normals
        EndPoints
        MidpointPatches
        ImagePatches
        CoordPatches
    end
    
    properties (Access = protected)
        SEGMENTSIZE  = 200;     % Number of coordinates per segment
        SEGMENTSTEPS = 50;      % Size of step to next segment
        ENVELOPESIZE = 20;      % Hard-coded max distance from original segment to envelope [deprecated]
        SMOOTHSPAN   = 0.7;     % Moving average span for smoothing segment coordinates
        SMOOTHMETHOD = 'sgolay' % Smoothing method
        GAUSSSIGMA   = 3;       % Sigma parameter for gaussian smoothing of ImagePatches
        ENV_ITRS     = 25;      % Number of intermediate curves between segment and envelope
        ENV_SCALE    = 4;       % Size to scale unit length vector to define max envelope distance
        Pmats
        Ppars
        OuterStruct
        OuterEnvelope
        OuterEnvelopeMax
        OuterDists
        InnerStruct
        InnerEnvelope
        InnerEnvelopeMax
        InnerDists        
    end
    
    %%
    methods (Access = public)
        %% Constructor and primary methods
        function obj = Curve(varargin)
            %% Constructor method for single Cure
            if ~isempty(varargin)
                % Parse inputs to set properties
                args = obj.parseConstructorInput(varargin);
                
                fn = fieldnames(args);
                for k = fn'
                    obj.(cell2mat(k)) = args.(cell2mat(k));
                end
                
            else
                % Set default properties for empty object
            end
            
        end
        
        function obj = RunFullPipeline(obj, ver)
            %% Runs full pipeline from Parent's Trace to generate ImagePatch
            tRun = tic;
            fprintf('\nRunning Full Pipeline for %s\n', obj.Parent.Origin);
            tic; obj.SegmentOutline; fprintf('Splitting full outline: %.02f sec\n', toc);            
            tic; obj.NormalizeSegments; fprintf('Midpoint Normalization conversion: %.02f sec\n', toc);
            tic; obj.SmoothSegments; fprintf('Smoothing Segments: %.02f sec\n', toc);
            tic; obj.CreateEnvelopeStructure(ver); fprintf('Creating Envelope Structure: %.02f sec\n', toc);
            tic; obj.Normal2Envelope(ver); fprintf('Converting to Envelope coordinates: %.02f sec\n', toc);
            tic; obj.GenerateImagePatch(ver); fprintf('Generating Image Patch: %.02f sec\n', toc);
            fprintf('%.02f sec to complete a single contour\n\n', toc(tRun));
            
        end
        
        function obj = SegmentOutline(varargin)
            %% Split CircuitJB outline into defined number of segments
            % This function will generate all individual curves around the
            % contour to the total defined by the SEGMENTSIZE parameter. Output
            % will be N curves of length SEGMENTSIZE, where N is the number of
            % curves around an outline of the CircuitJB object's InterpOutline.
            
            try
                obj = varargin{1};
                
                switch nargin
                    case 1
                        len = obj.SEGMENTSIZE;
                        stp = obj.SEGMENTSTEPS;
                        
                    case 3
                        len = varargin{2};
                        stp = varargin{3};
                        
                    otherwise
                        len = obj.SEGMENTSIZE;
                        stp = obj.SEGMENTSTEPS;
                        msg = sprintf(...
                            ['Input must be (segment_size, steps_per_segment)\n', ...
                            'Segmenting with default parameters (%d, %d)\n'], ...
                            len, stp);
                        fprintf(2, msg);
                        
                end
                
                obj = loadRawSegmentData(obj, obj.Trace, len, stp);
                
            catch
                fprintf(2, 'Error splitting outline into multiple segments\n');
            end
            
        end
        
        function obj = NormalizeSegments(obj)
            %% Convert RawSegments using Midpoint Normalization Method
            % Uses the midpoint-normalization method to convert coordinates in
            % the raw image coordinate frame into the normalized coordinate
            % frame (see midpointNorm())
            if isempty(obj.RawSegments)
                obj.SegmentOutline;
            elseif isempty(obj.Trace)
                obj.Trace = obj.Parent.FullOutline;
                obj.SegmentOutline;
            end
            
            % Run midpoint-normalization on all raw segments
            obj.NormalSegments = zeros(size(obj.RawSegments));
            for s = 1 : size(obj.RawSegments,3)
                [obj.NormalSegments(:,:,s), obj.Pmats(:,:,s), ...
                    obj.MidPoints(:,:,s), obj.Tangents(:,:,s), ...
                    obj.Normals(:,:,s)] = midpointNorm(obj.RawSegments(:,:,s));
            end
            
        end
        
        function obj = Normal2Envelope(obj, ver)
            %% Convert NormalSegments to coordinates within envelope
            % Uses the envelope method to convert normalized coordinates to
            % coordinates within an envelope structure (see envelopeMethod()).
            switch ver
                case 'main'
                    typ = 'Segments';
                    
                case 'smooth'
                    typ = 'Smooth';
                    
                otherwise
                    typ = 'Segments';
            end
            seg = sprintf('Envelope%s', typ);
            
            if isempty(obj.(seg))
                obj.CreateEnvelopeStructure(ver);
            end
            
            % Get distance to envelope.
            % Each coordinate should be same distance all around
            O    = obj.getEnvelopeStruct('O');
            I    = obj.getEnvelopeStruct('I');
            dOut = O(1).Dists(1,:);
            dInn = I(1).Dists(1,:);
            maxD = pdist([dOut ; dInn]) / 2;
            
            % Convert normalized coordinates to envelope coordinates
            env = arrayfun(@(x) envelopeMethod(obj.NormalSegments(:,:,x), ...
                obj.NormalSegments(:,:,x), maxD), ...
                1:obj.NumberOfSegments, 'UniformOutput', 0);
            obj.(seg) = cat(3, env{:});
            
        end
        
        function obj = CreateEnvelopeStructure(obj, ver)
            %% Method 2: mathematical version of augmentEnvelope
            % Define maximum distance to envelope and create all intermediate
            % curves between main segment and envelope segment. For more detail
            % see assessImagePatches function.
            
            % Generate Outer and Inner Envelope boundaries and Intermediate
            % segments between boundaries
            obj.generateEnvelopeBounds(ver);
            obj.generateEnvelopeIntermediates(ver);
            
        end
        
        function obj = SmoothSegments(obj)
            %% Smooth RawTrace then go through full normalization pipeline
            % Check if segments have been normalized
            if isempty(obj.NormalSegments)
                obj.NormalizeSegments;
            end
            
            smthFun          = @(x) segSmooth(obj.NormalSegments(:,:,x), ...
                obj.SMOOTHSPAN, obj.SMOOTHMETHOD);
            R                = arrayfun(@(x) smthFun(x), ...
                1 : obj.NumberOfSegments, 'UniformOutput', 0);
            obj.NormalSmooth = cat(3, R{:});
            
            % Reverse Midpoint-normalization on smoothed segments
            obj.RawSmooth = zeros(size(obj.RawSmooth));
            for s = 1 : size(obj.NormalSmooth, 3)
                obj.RawSmooth(:,:,s) = reverseMidpointNorm( ...
                    obj.NormalSmooth(:,:,s), ...
                    obj.Pmats(:,:,s)) + obj.MidPoints(:,:,s);
            end
            
            % Create Envelope structure with smoothed segments
            obj.generateEnvelopeBounds('smooth');
            obj.generateEnvelopeIntermediates('smooth');
            
            % Convert normalized coordinates to envelope coordinates
            obj.Normal2Envelope('smooth');
            
        end
        
        function obj = GenerateImagePatch(obj, ver)
            %% Generates ImagePatches property from envelope coordinates
            % Image patch can be created with main or smoothed segments,
            % defined by ver parameter.
            
            switch ver
                case 'main'
                    typ = 'Segments';
                    
                case 'smooth'
                    typ = 'Smooth';
                    
                otherwise
                    typ = 'Segments';
            end
            
            % Map main curve first
            seg = sprintf('Normal%s', typ); % Should be envelope segments when I get this right
            %             seg = sprintf('Envelope%s', typ);
            
            [obj.ImagePatches, obj.CoordPatches, obj.MidpointPatches] = ...
                arrayfun(@(x) obj.setImagePatch(obj.(seg)(:,:,x), x), ...
                1:obj.NumberOfSegments, 'UniformOutput', 0);
            
        end
    end
    
    %%
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
                        pt = reshape(obj.MidPoints, 2, size(obj.MidPoints,3))';
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
        
        function pts = getEndPoint(varargin)
            %% Returns all EndPoint values or EndPoint at requested segment
            switch nargin
                case 1
                    % Returns all segment endpoints
                    obj = varargin{1};
                    pts = obj.EndPoints;
                    
                case 2
                    % Arguments are Curve object and segment index
                    obj = varargin{1};
                    req = varargin{2};
                    try
                        pts = obj.EndPoints(:,:,req);
                    catch
                        r = num2str(req);
                        fprintf(2, 'Error requesting EndPoints %s\n', r);
                    end
                    
                case 3
                    % Arguments are Curve object, segment index, and
                    % start (0) or endpoint (1)
                    obj = varargin{1};
                    req = varargin{2};
                    pnt = varargin{3};
                    if any(pnt == 1:2)
                        pts = obj.EndPoints(pnt,:,req);
                    else
                        p = num2str(pnt);
                        r = num2str(req);
                        fprintf(2, ...
                            'Error requesting EndPoints (pnt%s,seg%s)\n', p, r);
                    end
                    
                otherwise
                    obj = varargin{1};
                    pts = obj.EndPoints;
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
                    prm   = obj.(param)(:,:,idx);
                    
                otherwise
                    fprintf(2, 'Input must be (param) or (param, idx)\n');
                    prm = [];
            end
        end
        
        function env = getEnvelopeStruct(obj, req)
            %% Returns OuterEnvelope, InnerEnvelope, or both
            if ischar(req)
                switch req
                    case 'O'
                        env = obj.OuterStruct;
                        
                    case 'I'
                        env = obj.InnerStruct;
                        
                    case 'B'
                        env = {obj.OuterStruct, obj.InnerStruct};
                        
                    otherwise
                        env = {obj.OuterStruct, obj.InnerStruct};
                end
            else
                fprintf(2, 'Input must be ''O'', ''I'', or ''B''\n');
                env = [];
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
            env = obj.EnvelopeSegments;
            crv = obj.NormalSegments;
            sz  = obj.ENVELOPESIZE;
            pm  = obj.Pmats;
            mid = obj.MidPoints;
            
            % Iterate through envelope segments and convert to image segments
            env2raw = @(n) envelope2coords(env(:,:,n), crv(:,:,n), ...
                sz, pm(:,:,n), mid(:,:,n));
            raw = arrayfun(@(n) env2raw(n), ...
                1 : obj.NumberOfSegments, 'UniformOutput', 0);
            raw = cat(3, raw{:});
            
        end
        
        function obj = updateEnvelopeStructure(obj)
            %% Update Inner/Outer envelope structure
            obj.OuterStruct = struct('Max', obj.OuterEnvelopeMax, ...
                'Full', obj.OuterEnvelope, ...
                'Dists', obj.OuterDists);
            
            obj.InnerStruct = struct('Max', obj.InnerEnvelopeMax, ...
                'Full', obj.InnerEnvelope, ...
                'Dists', obj.InnerDists);
        end
        
        function [imgPatch, crdsPatch, midsPatch] = setImagePatch(obj, seg, segIdx)
            %% Generate an image patch at desired frame
            % Map original curve segment
            [img, val, Pm, mid] = getMapParams(obj, segIdx);
            [pxCrv, crdCrv]     = mapCurve2Image(seg, img, Pm, mid);
            
            % Map full envelope structure
            envOut          = obj.getEnvelopeStruct('O');
            envInn          = obj.getEnvelopeStruct('I');
            [pxOut, crdOut] = cellfun(@(x) mapCurve2Image(x, img, Pm, mid), ...
                envOut(segIdx).Full, 'UniformOutput', 0);
            [pxInn, crdInn] = cellfun(@(x) mapCurve2Image(x, img, Pm, mid), ...
                envInn(segIdx).Full, 'UniformOutput', 0);
            
            % Create image patch for ImagePatches
            allOut   = fliplr(cat(2, pxOut{:}));
            allInn   = cat(2, pxInn{:}); % Align by flipping inner envelope
            fullpx   = [allOut pxCrv allInn];
            
            % Replace all NaN values then perform gaussian filtering
            fullpx(isnan(fullpx)) = val;
            imgPatch              = imgaussfilt(fullpx, obj.GAUSSSIGMA);
            
            % Coordinates from image patch for CoordsPatches
            crdsOut   = cat(3, crdOut{:});
            crdsInn   = cat(3, crdInn{:}); % Align by flipping inner envelope
            crdsPatch = struct('out', crdsOut, 'mid', crdCrv, 'inn', crdsInn);                        
            
            % Create midpoint-centered patch for MidpointPatches
            patchBuff = 0.08;
            patchSize = 50;
            midsPatch = patchFromCoord(seg, Pm, mid, img, patchBuff, patchSize);
            midsPatch(isnan(midsPatch)) = val;
            
        end
        
        function [crvsX, crvsY] = rasterizeSegments(obj, req)
            %% Rasterize all segments of requested type
            % This method is used to prepare for Principal Components Analysis.
            % The req parameter is the requested segment type to rasterize and
            % should be RawSegments, NormalSegments, or EnvelopeSegments.
            try
%                 segtype = getSegmentType(obj, req);
                segtype = getSegmentType(req);
                X       = obj.(segtype)(:,1,:);
                Y       = obj.(segtype)(:,2,:);
                crvsX   = rasterizeImagesHQ(X);
                crvsY   = rasterizeImagesHQ(Y);
            catch
                fprintf(2, 'Error rasterizing segments\n');
                [crvsX, crvsY] = deal([]);
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
        
    end
    
    %%
    methods (Access = private)
        %% Private helper methods
        function args = parseConstructorInput(varargin)
            %% Parse input parameters for Constructor method
            p = inputParser;
            p.addOptional('Parent', CircuitJB);
            p.addOptional('Trace', []);
            p.addOptional('NumberOfSegments', 0);
            p.addOptional('RawSegments', []);
            p.addOptional('NormalSegments', []);
            p.addOptional('EnvelopeSegments', []);
            p.addOptional('RawSmooth', []);
            p.addOptional('NormalSmooth', []);
            p.addOptional('EnvelopeSmooth', []);
            p.addOptional('ImagePatches', []);
            p.addOptional('MidPoints', []);
            p.addOptional('Tangents', []);
            p.addOptional('Normals', []);
            p.addOptional('EndPoints', []);
            p.addOptional('Pmats', []);
            p.addOptional('Ppars', []);
            p.addOptional('OuterStruct', []);
            p.addOptional('OuterEnvelope', []);
            p.addOptional('OuterEnvelopeMax', []);
            p.addOptional('OuterDists', []);
            p.addOptional('InnerStruct', []);
            p.addOptional('InnerEnvelope', []);
            p.addOptional('InnerEnvelopeMax', []);
            p.addOptional('InnerDists', []);
            p.addOptional('CoordPatches', []);
            p.addOptional('MidpointPatches', []);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
        function obj = loadRawSegmentData(obj, trace, segment_length, step_size)
            %% Set data for RawSegments, EndPoints, and NumberOfSegments
            obj.RawSegments      = ...
                split2Segments(trace, segment_length, step_size);
            obj.EndPoints        = ...
                [obj.RawSegments(1,:,:) ; obj.RawSegments(end,:,:)];
            obj.NumberOfSegments = size(obj.RawSegments,3);
            
        end
        
        function [img, medBg, Pmat, midpoint] = getMapParams(obj, segIdx)
            %% Returns parameters for mapping curve to image for setImagePatch
            img      = obj.Parent.getImage('gray');
            msk      = obj.Parent.getImage('bw');
            medBg    = median(img(msk == 1));
            Pmat     = obj.getParameter('Pmats', segIdx);
            midpoint = obj.getMidPoint(segIdx);
            
        end
        
        function obj = generateEnvelopeBounds(obj, ver)
            %% Define Outer and Inner Envelope structures
            % Input:
            %   S: curve segment index to generate envelope boundary from
            %   ENV_SCALE: scaled distance from curve to envelope boundary
            %
            % Output:
            %   OuterEnvelopeMax: segment defining main curve to outer envelope
            %   OuterDists: unit length vectors, outer envelope to main curve
            %   InnerEnvelopeMax: segment defining main curve to inner envelope
            %   InnerDists: unit length vector, inner envelope to main curve
            
            switch ver
                case 'main'
                    typ = 'Segments';
                    
                case 'smooth'
                    typ = 'Smooth';
                    
                otherwise
                    typ = 'Segments';
            end
            seg = sprintf('Normal%s', typ);
            
            defCrv = @(S) defineCurveEnvelope(obj.(seg)(:,:,S), obj.ENV_SCALE);
            [obj.OuterEnvelopeMax, obj.InnerEnvelopeMax, ...
                obj.OuterDists, obj.InnerDists] = arrayfun(@(x) defCrv(x), ...
                1:obj.NumberOfSegments, 'UniformOutput', 0);
            
            obj.updateEnvelopeStructure;
            
        end
        
        function obj = generateEnvelopeIntermediates(obj, ver)
            %% Generate Intermediate Envelope segments
            % Input:
            %   S: curve segment to generate envelope from
            %   dst: unit length vectors defining curve-envelope distance
            %   ENV_ITRS: number of curves between envelope and main segment
            %
            % Output:
            %   OuterEnvelope: segments between outer segment and main curve
            %   InnerEnvelope: segments between inner segment and main curve
            %
            
            switch ver
                case 'main'
                    typ = 'Segments';
                    
                case 'smooth'
                    typ = 'Smooth';
                    
                otherwise
                    typ = 'Segments';
            end
            seg = sprintf('Normal%s', typ);
            
            genFull = @(S,dst) generateFullEnvelope(S, dst, obj.ENV_ITRS);
            
            obj.OuterEnvelope = arrayfun(@(x) genFull(obj.(seg)(:,:,x), ...
                obj.OuterDists{x}), 1:obj.NumberOfSegments, 'UniformOutput', 0);
            obj.InnerEnvelope = arrayfun(@(x) genFull(obj.(seg)(:,:,x), ...
                obj.InnerDists{x}), 1:obj.NumberOfSegments, 'UniformOutput', 0);
            
            obj.updateEnvelopeStructure;
            
        end
    end
end

