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
        MidPoint
        MeanPoint
        InterpTrace
        Pmat
        Ppar
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
            
            % Normalize using Midpoint Method to set various parameters
            [obj.NormalTrace, obj.Pmat, obj.MidPoint] = midpointNorm(obj.InterpTrace);
            obj.Ppar = [computePpar(obj.Pmat(2), obj.Pmat(1)) obj.MidPoint];
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
        
        function mid = getMidPoint(varargin)
            %% Return midpoint of curve at given frame
            try
                obj = varargin{1};
                switch nargin
                    case 1
                        mid = obj.MidPoint;
                    case 2
                        frm = varargin{2};
                        mid = obj.MidPoint(frm,:);
                    otherwise
                        fprintf(2, 'No frame specified\n');
                end
            catch
                fprintf(2, 'Error returning midpoint\n');
            end
        end
        
        % Pmat should only be set with NormalizeTrace method
        %         function obj = setPmat(obj, Pm)
        %             %% Set conversion matrix
        %             if isequal(sum(size(obj.Pmat)), sum(size(Pm)))
        %                 obj.Pmat = Pm;
        %             else
        %                 fprintf(2, 'Pmat must be size [%d %d]\n', size(obj.Pmat));
        %             end
        %         end
        
        function Pm = getPmat(obj)
            %% Return conversion matrix Pmat
            Pm = obj.Pmat;
        end
        
        % Ppar should only be set with NormalizeTrace method
        %         function obj = setPpar(obj, Pp)
        %             %% Set parameters matrix
        %             if isequal(sum(size(obj.Ppar)), sum(size(Pp)))
        %                 obj.Ppar = Pp;
        %             else
        %                 fprintf(2, 'Pmat must be size [%d %d]\n', size(obj.Ppar));
        %             end
        %         end
        
        function Pp = getPpar(obj)
            %% Return parameters Ppar
            Pp = obj.Ppar;
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
            p.addOptional('Pmat', zeros(3,3));
            p.addOptional('Ppar', zeros(1,3));
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
    end
    
end

