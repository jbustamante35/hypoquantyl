%% Circuit: class for holding contours with defined anchor points
% Descriptions

classdef CircuitJB < handle
    properties (Access = public)
        Origin
        AnchorPoints
        InterpOutline
        Routes
    end
    
    properties (Access = private)
        RawPoints
        RawOutline
        Image
        INTERPOLATIONSIZE = 800
        NUMBEROFANCHORS   = 7
    end
    
    methods (Access = public)
        %% Constructor and primary methods
        function obj = CircuitJB(varargin)
            %% Constructor method for CircuitJB
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
            
            obj.Routes = initializeRoutes(obj);
            obj.Image  = struct('gray', [], ...
                'bw',   []);
            
        end
        
        function [X, Y] = LinearizeRoutes(obj)
            %% Return all X and Y coordinates from all Routes
            %             [~, rtsX, rtsY] = concatRoutes(obj);
            %             X = reshape(rtsX, numel(rtsX), 1);
            %             Y = reshape(rtsY, numel(rtsY), 1);
            [~, X, Y] = concatRoutes(obj);
        end
        
        function obj = CreateRoutes(obj)
            %% Use Interpolated Outline and Anchor Points to create Route objects
            rts = obj.Routes;
            pts = obj.AnchorPoints;
            oL  = obj.getOutline;
            n   = obj.NUMBEROFANCHORS;
            
            % Get indices of Outline matching each Anchor Point
            fidx = @(x,y) find(sum(ismember(x,y), 2) == 2);
            mtch = arrayfun(@(x) fidx(oL(:,:,x),pts(:,:,x)), 1:size(oL,3), 'UniformOutput', 0);
            mtch = cat(2, mtch{:});
            
            % Split Outline into separate Trace between each AnchorPoints
            shp    = @(x) reshape(nonzeros(x), [nnz(x)/2 2]);
            frms   = size(oL,3);
            traces = arrayfun(@(x) split2trace(oL(:,:,x), mtch(:,x), n), 1:frms, 'UniformOutput', 0);
            
            % Set data for all Routes at each frame
            for i = 1 : numel(traces)
                trc = traces{i};
                newpts = [pts(:,:,i) ; pts(1,:,i)]; % Copy first anchor point to last index
                arrayfun(@(x) rts(x).setRawTrace(i, shp(trc(:,:,x))), 1:n, 'UniformOutput', 0);
                arrayfun(@(x) rts(x).setAnchors(i, newpts(x,:), newpts(x+1,:)), 1:n, 'UniformOutput', 0);
                arrayfun(@(x) rts(x).NormalizeTrace, 1:n, 'UniformOutput', 0);
            end
        end
        
        function obj = DrawOutline(obj, frm)
            %% Draw RawOutline on this object's Image
            try
                % Trace outline and store as RawOutline
                img = obj.getImage(frm, 'gray');
                c   = drawPoints(img, 'y', 'Outline');
                obj.setRawOutline(frm, c.getPosition);
                obj.setImage(frm, 'bw', c.createMask);
            catch
                fprintf(2, 'Error setting outline at frame %d \n', frm);
            end
        end
        
        function obj = DrawAnchors(obj, frm)
            %% Draw RawPoints on this object's Image
            try
                % Plot anchor points and store as RawPoints
                img = obj.getImage(frm, 'gray');
                str = sprintf('%d AnchorPoints', obj.NUMBEROFANCHORS);
                p   = drawPoints(img, 'y', str);
                obj.setRawPoints(frm, p.getPosition);
            catch
                fprintf(2, 'Error setting anchor points at frame %d \n', frm);
            end
        end
        
        function obj = ConvertRawOutlines(obj)
            %% Convert contours from RawOutline to InterpOutline
            oL = obj.RawOutline;
            sz = obj.INTERPOLATIONSIZE;
            iL = zeros(sz, 2, numel(oL));
            
            for i = 1 : numel(oL)
                iL(:,:,i) = interpolateOutline(oL{i}, sz);
            end
            
            obj.InterpOutline = iL;
        end
        
        function obj = ConvertRawPoints(obj)
            %% Convert anchor points from RawPoints to snapped AnchorPoints along outline
            if isempty(obj.InterpOutline)
                obj.ConvertRawOutlines;
            end
            
            iL   = obj.InterpOutline;
            pts  = obj.RawPoints;
            npts = zeros(size(pts));
            for i = 1 : size(pts,3)
                npts(:,:,i) = snap2curve(pts(:,:,i), iL(:,:,i));
            end
            
            obj.AnchorPoints = npts;
        end
    end
    
    methods (Access = public)
        %% Various helper methods
        function obj = setOrigin(obj, org)
            %% Set parent of this CircuitJB
            obj.Origin = org;
        end
        
        function org = getOrigin(obj)
            %% Return parent of this CircuitJB
            org = obj.Origin;
        end
        
        function obj = setImage(obj, frm, req, im)
            %% Set grayscale or bw image at given frame [frm, req, im]
            try
                obj.Image(frm).(req) = im;
            catch
                fprintf(2, 'Error setting %s image at frame %d\n', req, frm);
            end
        end
        
        function dat = getImage(varargin)
            %% Return image data for ContourJB at desired frame [frm, req]
            % User can specify which image from structure with 3rd parameter
            switch nargin
                case 1
                    % Full structure of image data at all frames
                    obj = varargin{1};
                    dat = obj.Image;
                    
                case 2
                    % All image data at frame
                    try
                        obj = varargin{1};
                        frm = varargin{2};
                        dat = obj.Image(frm);
                    catch
                        fprintf(2, 'No image at frame %d \n', frm);
                    end
                    
                case 3
                    % Specific image type at frame
                    % Check if frame exists
                    try
                        obj = varargin{1};
                        frm = varargin{2};
                        req = varargin{3};
                        dat = obj.Image(frm);
                    catch
                        fprintf(2, 'No image at frame %d \n', frm);
                    end
                    
                    % Get requested data field
                    try
                        dfm = obj.Image(frm);
                        dat = dfm.(req);
                    catch
                        fn  = fieldnames(dfm);
                        str = sprintf('%s, ', fn{:});
                        fprintf(2, 'Requested field must be either: %s\n', str);
                    end
                    
                otherwise
                    fprintf(2, 'Error requesting data.\n');
                    return;
            end
        end
        
        function obj = setRawOutline(obj, frm, oL)
            %% Set coordinates for RawOutline at specific frame
            try
                obj.RawOutline{frm} = oL;
            catch
                fprintf(2, 'No RawOutline at frame %d \n', frm);
            end
        end
        
        function oL = getRawOutline(varargin)
            %% Return RawOutline at specific frame
            try
                obj = varargin{1};
                if nargin == 1
                    oL = obj.RawOutline;
                else
                    frm = varargin{2};
                    oL  = obj.RawOutline{frm};
                end
            catch
                fprintf(2, 'No RawOutline at frame %d \n', varargin{2});
            end
        end
        
        function iL = getOutline(varargin)
            %% Return Interpolated Outline at specific frame
            try
                obj = varargin{1};
                if nargin == 1
                    iL = obj.InterpOutline;
                else
                    frm = varargin{2};
                    iL = obj.InterpOutline(:,:,frm);
                end
            catch
                fprintf(2, 'No RawOutline at frame %d \n', varargin{2});
            end
        end
        
        function obj = setRawPoints(obj, frm, pts)
            %% Set coordinates pts to AnchorPoint at specific frame
            try
                obj.RawPoints(:,:,frm) = pts;
            catch
                fprintf(2, 'No AnchorPoints at frame %d \n', frm);
            end
        end
        
        function pts = getRawPoints(varargin)
            %% Return RawPoints at specific frame
            try
                obj = varargin{1};
                if nargin == 1
                    pts = obj.RawPoints;
                else
                    frm = varargin{2};
                    pts = obj.RawPoints(:,:,frm);
                end
            catch
                fprintf(2, 'No points at frame %d \n', varargin{2});
            end
        end
        
        function pts = getAnchorPoints(varargin)
            %% Return RawPoints at specific frame
            try
                obj = varargin{1};
                if nargin == 1
                    pts = obj.AnchorPoints;
                else
                    frm = varargin{2};
                    pts = obj.AnchorPoints(:,:,frm);
                end
            catch
                fprintf(2, 'No points at frame %d \n', varargin{2});
            end
        end
        
        function obj = setRoute(obj, idx, rt)
            %% Set Route rt to desired index
            try
                obj.Routes(idx) = rt;
            catch
                fprintf(2, 'No Route at frame %d index %d\n', idx);
            end
        end
        
        function rt = getRoute(varargin)
            %% Return a Route from desired frame
            try
                obj = varargin{1};
                switch nargin
                    case 1
                        rt = obj.Routes;
                        
                    case 2
                        idx = varargin{2};
                        rt  = obj.Routes(idx);
                        
                    otherwise
                        fprintf(2, 'No Route specified\n');
                end
            catch
                fprintf(2, 'Error return Route %d at frame %d\n', idx, frm);
            end
        end
    end
    
    methods (Access = private)
        %% Private helper methods
        function args = parseConstructorInput(varargin)
            %% Parse input parameters for Constructor method
            p = inputParser;
            p.addOptional('Origin', '');
            p.addOptional('RawOutline', {});
            p.addOptional('InterpOutline', []);
            p.addOptional('RawPoints', []);
            p.addOptional('AnchorPoints', []);
            p.addOptional('Image', []);
            p.addOptional('Routes', Route);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
        function R = initializeRoutes(obj)
            %% Initialize Route objects for Constructor
            for i = 1 : obj.NUMBEROFANCHORS
                R(i) = Route('Origin', obj.Origin);
            end
        end
        
        function [C,X,Y] = concatRoutes(obj)
            %% Concatenate Routes into [m x n x 2] array
            % m is the number of Route objects
            % n is the size of each Route object's NormalTrace
            % Output:
            %   C: x- and y-coordinates in [m x n x 2] array
            %   X: all x-coordinates in [n x 1 x m] array
            %   Y: all y-coordinates in [n x 1 x m] array
            
            getDim = @(x,y) x(:,y);
            R = obj.Routes;
            X = arrayfun(@(x) getDim(x.getTrace(1), 1), R, 'UniformOutput', 0);
            Y = arrayfun(@(x) getDim(x.getTrace(1), 2), R, 'UniformOutput', 0);
            
            X = cat(3, X{:});
            Y = cat(3, Y{:});
            C = cat(3, X, Y);
        end
        
    end
    
end

