%% Cuve: class for sections of contours for a CircuitJB object
% Descriptions

classdef Curve < handle
    properties (Access = public)
        Parent
        Trace
        NumberOfSegments
        RawSegments
        %         NormalSegments             % Deprecated [08.21.2019]
        EnvelopeSegments
        %         RawSmooth        % Deprecated [08.21.2019]
        %         NormalSmooth     % Deprecated [08.21.2019]
        %         EnvelopeSmooth   % Deprecated [08.21.2019]
        %         MidPoints        % Deprecated [08.21.2019]
        %         Tangents         % Deprecated [08.21.2019]
        %         Normals          % Deprecated [08.21.2019]
        EndPoints
        SVectors
        ZVector
        SPatches
        ZPatches
        %         MidpointPatches % Deprecated [08.21.2019]
        %         ImagePatches    % Deprecated [08.21.2019]
        %         CoordPatches    % Deprecated [08.21.2019]
    end
    
    properties (Access = protected)
        SEGMENTSIZE  = 25;      % Number of coordinates per segment [default 200]
        SEGMENTSTEPS = 1;       % Size of step to next segment [default 50]
        %         ENVELOPESIZE = 20;      % Hard-coded max distance from original segment to envelope [deprecated]
        %         SMOOTHSPAN   = 0.7;     % Moving average span for smoothing segment coordinates                   % Deprecated [08.21.2019]
        %         SMOOTHMETHOD = 'sgolay' % Smoothing method                                                        % Deprecated [08.21.2019]
        %         GAUSSSIGMA   = 3;       % Sigma parameter for gaussian smoothing of ImagePatches                  % Deprecated [08.21.2019]
        %         ENV_ITRS     = 8;       % Number of intermediate curves between segment and envelope [default 25] % Deprecated [08.21.2019]
        %         ENV_SCALE    = 8;       % Size to scale unit length vector to define max envelope distance        % Deprecated [08.21.2019]
        MIDPATCHVER  = 'fixed'; % Set Z-Vector patches as fixed around midpoint
        Pmats
        Ppars
        %         OuterStruct       % Deprecated [08.21.2019]
        %         OuterEnvelope     % Deprecated [08.21.2019]
        %         OuterEnvelopeMax  % Deprecated [08.21.2019]
        %         OuterDists        % Deprecated [08.21.2019]
        %         InnerStruct       % Deprecated [08.21.2019]
        %         InnerEnvelope     % Deprecated [08.21.2019]
        %         InnerEnvelopeMax  % Deprecated [08.21.2019]
        %         InnerDists        % Deprecated [08.21.2019]
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
        
        function obj = RunFullPipeline(obj, par)
            %% Runs full pipeline from Parent's Trace to generate ImagePatch
            % par: 0 to use normal for loop, 1 to use with parallel processing
            tRun = tic;
            fprintf('\nRunning Full Pipeline for %s...\n', obj.Parent.Origin);
            
            tic; fprintf('Splitting full outline...')            ; obj.SegmentOutline    ; fprintf('done [%.02f sec]\n', toc);
            tic; fprintf('Midpoint Normalization conversion...') ; obj.NormalizeSegments ; fprintf('done [%.02f sec]\n', toc);
            tic; fprintf('Generating S-Patches...')              ; obj.GenerateSPatches(par)  ; fprintf('done [%.02f sec]\n', toc);
            tic; fprintf('Generating Z-Patches...')              ; obj.GenerateZPatches(par)  ; fprintf('done [%.02f sec]\n', toc);
            
            % [ DEPRECATED 08.21.2019 ]
            % No longer building from envelope segments
            % Optimizing algorithm for generating patches
            %             tic; fprintf('Smoothing Segments...')                ; obj.SmoothSegments              ; fprintf('done [%.02f sec]\n', toc);
            %             tic; fprintf('Creating Envelope Structure...')       ; obj.CreateEnvelopeStructure(ver); fprintf('done [%.02f sec]\n', toc);
            %             tic; fprintf('Converting to Envelope coordinates...'); obj.Normal2Envelope(ver)        ; fprintf('done [%.02f sec]\n', toc);
            %             tic; fprintf('Generating Image Patch...')            ; obj.GenerateImagePatch(ver)     ; fprintf('done [%.02f sec]\n', toc);
            
            fprintf('DONE! [%.02f sec ]\n\n', toc(tRun));
            
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
            obj.SVectors = zeros(size(obj.RawSegments));
            obj.ZVector        = zeros(obj.NumberOfSegments, 6);
            for s = 1 : size(obj.RawSegments,3)
                [obj.SVectors(:,:,s), obj.Pmats(:,:,s), ~, ~, ~, ...
                    obj.ZVector(s,:)] = midpointNorm(obj.RawSegments(:,:,s));
            end
            
        end
        
        function obj = Normal2Envelope(obj, ver)
            %% Convert SVectors to coordinates within envelope
            %% Deprecated [08.21.2019]
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
            env = arrayfun(@(x) envelopeMethod(obj.SVectors(:,:,x), ...
                obj.SVectors(:,:,x), maxD), ...
                1:obj.NumberOfSegments, 'UniformOutput', 0);
            obj.(seg) = cat(3, env{:});
            
        end
        
        function obj = CreateEnvelopeStructure(obj, ver)
            %% Method 2: mathematical version of augmentEnvelope
            %% Deprecated [08.21.2019]
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
            %% Deprecated [08.21.2019]
            % Check if segments have been normalized
            if isempty(obj.SVectors)
                obj.NormalizeSegments;
            end
            
            smthFun          = @(x) segSmooth(obj.SVectors(:,:,x), ...
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
        
        function [obj, SP, Ds] = GenerateSPatches(obj, par)
            %% Generates S-Patches from image frame coordinates
            %
            %
            
            %
            segs    = obj.SVectors;
            img     = obj.Parent.getImage('gray');
            allSegs = 1 : obj.NumberOfSegments;
            
            %%
            if par
                % Run with parallel processing
                [SP, Ds] = deal(cell(1, obj.NumberOfSegments));
                parfor p = allSegs
                    [SP{p}, Ds{p}] = setSPatch(segs(:,:,p), img);
                end
            else
                % Run with traditional for loop
                [SP, Ds] = arrayfun(@(p) setSPatch(segs(:,:,p), img), ...
                    allSegs, 'UniformOutput', 0);
            end
            
            %
            obj.SPatches = SP;
            
        end
        
        function [obj, ZP, Dz] = GenerateZPatches(obj, par)
            %% Generates Z-Patches from image frame coordinates
            %
            
            %
            zvec    = obj.ZVector;
            img     = double(obj.Parent.getImage('gray'));
            allSegs = 1 : obj.NumberOfSegments;
            
            %%
            if par
                % Run with parallel processing
                [ZP, Dz] = deal(cell(1, obj.NumberOfSegments));
                parfor p = allSegs
                    [ZP{p}, Dz{p}] = setZPatch(zvec(p,:), img);
                end
            else
                % Run with traditional for loop
                [ZP, Dz] = arrayfun(@(p) setZPatch(zvec(p,:), img), ...
                    allSegs, 'UniformOutput', 0);
            end
            
            %
            obj.ZPatches = ZP;
            
        end
        
        function obj = GenerateImagePatch(obj, ver)
            %% Generates ImagePatches property from envelope coordinates
            %% [NOTE] Deprecated [08.21.2019]
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
            ver = obj.MIDPATCHVER;
            %             seg = sprintf('Envelope%s', typ);
            
            [obj.ImagePatches, obj.CoordPatches, obj.MidpointPatches] = ...
                arrayfun(@(x) obj.setImagePatch(obj.(seg)(:,:,x), x, ver), ...
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
            %% [NOTE] Deprecated [08.21.2019]
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
            crv = obj.SVectors;
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
            %% [NOTE] Deprecated [08.21.2019]
            obj.OuterStruct = [];
            obj.OuterStruct = struct('Max', obj.OuterEnvelopeMax, ...
                'Full', obj.OuterEnvelope, ...
                'Dists', obj.OuterDists);
            
            obj.InnerStruct = [];
            obj.InnerStruct = struct('Max', obj.InnerEnvelopeMax, ...
                'Full', obj.InnerEnvelope, ...
                'Dists', obj.InnerDists);
        end
        
        function [imgPatch, crdsPatch, midsPatch] = setImagePatch(obj, seg, segIdx, ver)
            %% Generate an image patch at desired frame
            %% [NOTE] Deprecated [08.21.2019]
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
            midsPatch = ...
                patchFromCoord(seg, Pm, mid, img, patchBuff, patchSize, ver);
            midsPatch(isnan(midsPatch)) = val;
            
        end
        
        function [crvsX, crvsY] = rasterizeSegments(obj, req)
            %% Rasterize all segments of requested type
            % This method is used to prepare for Principal Components Analysis.
            % The req parameter is the requested segment type to rasterize and
            % should be RawSegments, SVectors, or EnvelopeSegments.
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
        
        
        function obj = setProperty(obj, req, val)
            %% Set requested property if it exists [for private properties]
            try
                obj.(req) = val;
            catch e
                fprintf(2, 'Property %s not found\n%s\n', req, e.getReport);
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
            %             p.addOptional('NormalSegments', []);              % Deprecated [08.21.2019]
            p.addOptional('EnvelopeSegments', []);
            p.addOptional('EndPoints', []);
            p.addOptional('SVectors', []);
            p.addOptional('ZVector', []);
            p.addOptional('SPatches', []);
            p.addOptional('ZPatches', []);
            p.addOptional('Pmats', []);
            p.addOptional('Ppars', []);
            %             p.addOptional('RawSmooth', []);        % Deprecated [08.21.2019]
            %             p.addOptional('NormalSmooth', []);     % Deprecated [08.21.2019]
            %             p.addOptional('EnvelopeSmooth', []);   % Deprecated [08.21.2019]
            %             p.addOptional('ImagePatches', []);     % Deprecated [08.21.2019]
            %             p.addOptional('MidPoints', []);        % Deprecated [08.21.2019]
            %             p.addOptional('Tangents', []);         % Deprecated [08.21.2019]
            %             p.addOptional('Normals', []);          % Deprecated [08.21.2019]
            %             p.addOptional('OuterStruct', []);      % Deprecated [08.21.2019]
            %             p.addOptional('OuterEnvelope', []);    % Deprecated [08.21.2019]
            %             p.addOptional('OuterEnvelopeMax', []); % Deprecated [08.21.2019]
            %             p.addOptional('OuterDists', []);       % Deprecated [08.21.2019]
            %             p.addOptional('InnerStruct', []);      % Deprecated [08.21.2019]
            %             p.addOptional('InnerEnvelope', []);    % Deprecated [08.21.2019]
            %             p.addOptional('InnerEnvelopeMax', []); % Deprecated [08.21.2019]
            %             p.addOptional('InnerDists', []);       % Deprecated [08.21.2019]
            %             p.addOptional('CoordPatches', []);     % Deprecated [08.21.2019]
            %             p.addOptional('MidpointPatches', []);  % Deprecated [08.21.2019]
            
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
            %% [NOTE] Deprecated [08.21.2019]
            img      = double(obj.Parent.getImage('gray'));
            msk      = obj.Parent.getImage('bw');
            medBg    = median(img(msk == 1));
            Pmat     = obj.getParameter('Pmats', segIdx);
            midpoint = obj.getMidPoint(segIdx);
            
        end
        
        function obj = generateEnvelopeBounds(obj, ver)
            %% Define Outer and Inner Envelope structures
            %% [NOTE] Deprecated [08.21.2019]
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
            %% [NOTE] Deprecated [08.21.2019]
            % Input:
            %   S: curve segment to generate envelope from
            %   dst: unit length vectors defining curve-envelope distance
            %   ENV_ITRS: number of curves between envelope and main segment
            %
            % Output:
            %   OuterEnvelope: segments between outer segment and main curve
            %   InnerEnvelope: segments between inner segment and main cunormalsrve
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
            
            genFull = @(S,dst) generateFullEnvelope(S, dst, obj.ENV_ITRS, 'hq');
            
            obj.OuterEnvelope = arrayfun(@(x) genFull(obj.(seg)(:,:,x), ...
                obj.OuterDists{x}), 1:obj.NumberOfSegments, 'UniformOutput', 0);
            obj.InnerEnvelope = arrayfun(@(x) genFull(obj.(seg)(:,:,x), ...
                obj.InnerDists{x}), 1:obj.NumberOfSegments, 'UniformOutput', 0);
            
            obj.updateEnvelopeStructure;
            
        end
    end
end

