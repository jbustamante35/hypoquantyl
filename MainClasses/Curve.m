%% Cuve: class for holding sections of contours of specified length for a CircuitJB object
% Descriptions

classdef Curve < handle
    properties (Access = public)
        Parent
        Trace
        NumberOfSegments
        RawSegments
        NormalSegments
        EnvelopeSegments
        MidPoints
        EndPoints
        ImagePatches
    end
    
    properties (Access = private)
        SEGMENTSIZE  = 300;
        SEGMENTSTEPS = 30;
        ENVELOPESIZE = 20;
        Pmats
        Ppars
        LeftEnvelope
        RightEnvelope
    end
    
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
        
        function obj = SegmentOutline(varargin)
            %% Split CircuitJB outline into number of segments defined by SEGMENTSIZE parameter
            % This function will generate all individual curves around the contour. Output will be
            % N curves of length SEGMENTSIZE, where N is the number of possible curves around an
            % outline of the CircuitJB object's InterpOutline.
            
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
                        msg = sprintf(['Input must be (segment_size, steps_per_segment)\n', ...
                            'Segmenting with default parameters (%d, %d)\n'], len, stp);
                        fprintf(2, msg);
                        
                end
                
                obj = loadRawSegmentData(obj, obj.Trace, len, stp);
                
            catch
                fprintf(2, 'Error splitting outline into multiple segments\n');
            end
            
        end
        
        function obj = NormalizeSegments(obj)
            %% Convert RawSegments using Midpoint Normalization Method (see midpointNorm())
            if isempty(obj.RawSegments)
                obj.SegmentOutline;
            elseif isempty(obj.Trace)
                obj.Trace = obj.Parent.FullOutline;
                obj.SegmentOutline;
            end
            
            obj.NormalSegments = zeros(size(obj.RawSegments));
            for c = 1 : size(obj.RawSegments,4)
                for s = 1 : size(obj.RawSegments,3)
                    [obj.NormalSegments(:,:,s,c), obj.Pmats(:,:,s,c), obj.MidPoints(:,:,s,c)] = ...
                        midpointNorm(obj.RawSegments(:,:,s,c));
                end
            end
            
        end
        
        function obj = Normal2Envelope(obj, idx)
            %% Convert NormalSegments to coordinates within envelope (see envelopeMethod())
            obj = augmentEnvelope(obj, obj.NormalSegments, obj.ENVELOPESIZE);
            
            %             obj.EnvelopeSegments = arrayfun(@(x) envelopeMethod(x, obj.ENVELOPESIZE), ...
            %                 obj.NormalSegments, 'UniformOutput', 0);
            
        end
        
    end
    
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
                    % Arguments are Curve object, segment index, and start (0) or endpoint (1)
                    obj = varargin{1};
                    req = varargin{2};
                    pnt = varargin{3};
                    if any(pnt == 1:2)
                        pts = obj.EndPoints(pnt,:,req);
                    else
                        p = num2str(pnt);
                        r = num2str(req);
                        fprintf(2, 'Error requesting EndPoints (pnt%s,seg%s)\n', p, r);
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
                    prm = obj.(param);
                    
                case 3
                    obj = varargin{1};
                    param = varargin{2};
                    idx = varargin{3};
                    prm = obj.(param)(:,:,idx);
                    
                otherwise
                    fprintf(2, 'Input must be (param) or (param, idx)\n');
                    prm = [];
            end
        end
        
        function env = getEnvelopeSide(obj, req)
            %% Returns LeftEnvelope, RightEnvelope, or both
            if ischar(req)
                switch req
                    case 'L'
                        env = obj.LeftEnvelope;
                        
                    case 'R'
                        env = obj.RightEnvelope;
                        
                    case 'B'
                        env = {obj.LeftEnvelope, obj.RightEnvelope};
                        
                    otherwise
                        env = {obj.LeftEnvelope, obj.RightEnvelope};
                end
            else
                fprintf(2, 'Input must be ''L'', ''R'', or ''B''\n');
                env = [];
            end
        end
        
    end
    
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
            p.addOptional('ImagePatches', []);
            p.addOptional('MidPoints', []);
            p.addOptional('EndPoints', []);
            p.addOptional('Pmats', []);
            p.addOptional('Ppars', []);
            p.addOptional('LeftEnvelope', []);
            p.addOptional('RightEnvelope', []);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
        function obj = loadRawSegmentData(obj, trace, segment_length, step_size)
            %% Set data for RawSegments, EndPoints, and NumberOfSegments
            obj.RawSegments = split2Segments(trace, segment_length, step_size);
            obj.EndPoints   = [obj.RawSegments(1,:,:) ; obj.RawSegments(end,:,:)];
            obj.NumberOfSegments = size(obj.RawSegments,3);
            
        end
        
        function obj = augmentEnvelope(obj, seg, sz)
            %% Set left and right sides of envelope around each Normal Segment
            % This function sets the extremes of the envelope for each segment
            %             offset_function   = @(s,e,o) o * (s - e) / norm(s - e); % start, end, offset distance
            %             offset_distance   = arrayfun(@(x) offset_function(seg(1,:,x), seg(end,:,x), sz), 1:size(seg,3), 'UniformOutput', 0);
            %             offset_distance   = cat(3,  offset_distance{:});
            %             obj.LeftEnvelope  = [seg(:,1), (seg(:,2) - offset_distance)];
            %             obj.RightEnvelope = [seg(:,1), (seg(:,2) + offset_distance)];
            
            obj.LeftEnvelope  = [seg(:,1), (seg(:,2) - sz)];
            obj.RightEnvelope = [seg(:,1), (seg(:,2) + sz)];
        end
    end
    
end