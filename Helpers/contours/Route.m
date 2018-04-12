%% Circuit: class for holding sections of contours between anchor points for CircuitJB object
% Descriptions

classdef Route < handle
    properties (Access = public)
        Origin
        NormalTrace
        Anchors
    end
    
    properties (Access = private)
        RawTrace
        MeanPoint
        InterpTrace
        INTERPOLATIONSIZE = 300
    end
    
    methods (Access = public)
        %% Constructor and primary methods
        function obj = Route(varargin)
            %% Constructor method for a single Route
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
        
        function obj = InterpolateTrace(obj)
            %% Convert RawTrace to InterpTrace
            rT = obj.RawTrace;
            sz = obj.INTERPOLATIONSIZE;
            iT = zeros(sz, 2, numel(rT));
            
            for i = 1 : numel(rT)
                iT(:,:,i) = interpolateOutline(rT{i}, sz);
            end
            
            obj.InterpTrace = iT;
        end
        
        function obj = NormalizeTrace(obj)
            %% Convert InterpTrace to NormalTrace
            % Interpolate Trace if not yet done
            if isempty(obj.InterpTrace)
                obj.InterpolateTrace;
            end
            
            % Find mean of curve and subtract off the mean
            I             = obj.InterpTrace;
            mean_of_curve = mean(I);
            obj.MeanPoint = mean_of_curve;
            meanTrace     = I - mean_of_curve;
            
            % Set start AnchorPoint to 0 and end AnchorPoint to 1
            subtTrace                   = meanTrace - meanTrace(1,:);
            normTrace                   = subtTrace ./ subtTrace(end,:);
            normTrace(isnan(normTrace)) = 1;
            obj.NormalTrace             = normTrace;
            
            % Save new start and end point to revert back to InterpTrace
            obj.Anchors(3,:,:) = meanTrace(1,:);
            obj.Anchors(4,:,:) = subtTrace(end,:);
        end
        
    end
    
    methods (Access = public)
        %% Various helper methods
        function obj = setOrigin(obj, org)
            %% Set parent CircuitJB of this Route
            obj.Origin = org;
        end
        
        function org = getOrigin(obj)
            %% Return parent CircuitJB of this Route
            org = obj.Origin;
        end
        
        function obj = setRawTrace(obj, frm, trc)
            %% Set coordinates for RawOutline at specific frame
            try
                obj.RawTrace{frm} = trc;
            catch
                fprintf(2, 'Error setting RawTrace at frame %d \n', frm);
            end
        end
        
        function trc = getRawTrace(varargin)
            %% Return RawOutline at specific frame
            try
                obj = varargin{1};
                if nargin == 1
                    trc = cat(1, obj.RawTrace{:});
                else
                    frm = varargin{2};
                    trc = obj.RawTrace{frm};
                end
            catch
                fprintf(2, 'Error retrieving RawTrace at frame %d \n', varargin{2});
            end
        end
        
        function trc = getInterpTrace(varargin)
            %% Return InterpTrace at specific frame
            try
                obj = varargin{1};
                if nargin == 1
                    trc = obj.InterpTrace;
                else
                    frm = varargin{2};
                    trc = obj.InterpTrace(:,:,frm);
                end
            catch
                fprintf(2, 'Error retrieving RawTrace at frame %d \n', varargin{2});
            end
        end
        
        function trc = getTrace(varargin)
            %% Return Normalized Trace at specific frame
            try
                obj = varargin{1};
                if nargin == 1
                    trc = obj.NormalTrace;
                else
                    frm = varargin{2};
                    trc = obj.NormalTrace(:,:,frm);
                end
            catch
                fprintf(2, 'Error retrieving RawTrace at frame %d \n', varargin{2});
            end
        end
        
        function mn = getMean(varargin)
            %% Return mean point of curve at given frame
            try
                obj = varargin{1};
                switch nargin
                    case 1
                        mn = obj.MeanPoint;
                    case 2
                        frm = varargin{2};
                        mn  = obj.MeanPoint(frm,:);
                    otherwise
                        fprintf(2, 'No frame specified\n');
                end
            catch
                fprintf(2, 'Error returning mean coordinate\n');
            end
        end
        
        function obj = setAnchors(obj, frm, bgin, dest)
            %% Set beginning and ending AnchorPoints for this Route
            try
                obj.Anchors(1,:,frm) = bgin;
                obj.Anchors(2,:,frm) = dest;
            catch
                fprintf(2, 'No RawTrace at frame %d \n', frm);
            end
        end
        
        function pt = getAnchors(varargin)
            %% Return one or both Anchors for this Route
            try
                obj = varargin{1};
                switch nargin
                    case 1
                        % Both Anchors
                        pt = obj.Anchors;
                    case 2
                        % Starting and Ending Anchors at specific frame
                        frm = varargin{2};
                        pt  = obj.Anchors(:,:,frm);
                        
                    case 3
                        % Either Starting or Ending Anchor at specific frame
                        frm = varargin{2};
                        req = varargin{3};
                        switch req
                            case 'b'
                                % Starting Anchor
                                pt  = obj.Anchors(1,:,frm);
                            case 'd'
                                % Ending Anchor
                                pt  = obj.Anchors(2,:,frm);
                                
                            case 'b2'
                                % Mean subtracted Starting Anchor 
                                pt = obj.Anchors(3,:,frm);
                                
                            case 'd2'
                                % Mean subtracted, Zero-set Ending Anchor
                                pt = obj.Anchors(4,:,frm);
                                
                            otherwise
                                fprintf(2, 'No Anchor specified \n');
                                return;
                        end
                        
                    otherwise
                        fprintf(2, 'Error returning Anchors.\n');
                end
            catch
                fprintf(2, 'Error returning Anchors.\n');
            end
        end
        
    end
    
    methods (Access = private)
        %% Private helper methods
        function args = parseConstructorInput(varargin)
            %% Parse input parameters for Constructor method
            p = inputParser;
            p.addOptional('Origin', '');
            p.addOptional('RawTrace', cell(0));
            p.addOptional('InterpTrace', []);
            p.addOptional('NormalTrace', []);
            p.addOptional('MeanPoint', zeros(1,2));
            p.addOptional('Anchors', zeros(4, 2, 0));
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
    end
    
end

