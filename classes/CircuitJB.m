%% Circuit: class for holding contours with defined anchor points
% Descriptions

classdef CircuitJB < handle
    properties (Access = public)
        Origin
        Parent
        HypocotylName
        ExperimentName
        GenotypeName
        AnchorPoints
        FullOutline
        NormalOutline
        Curves
        Routes
        isTrained
    end
    
    properties (Access = private)
        RawPoints
        RawOutline
        Image
        InterpOutline
        INTERPOLATIONSIZE = 2100
        NUMBEROFANCHORS   = 7
    end
    
    %%
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
            obj.Image  = struct('gray', [], 'bw', [], 'mask', [], 'labels', []);
            
        end
        
        function obj = NormalizeRoutes(obj)
            %% Run MidpointNormalization method on all of this object's Routes
            arrayfun(@(x) x.NormalizeTrace, obj.Routes, 'UniformOutput', 0);
        end
        
        function obj = CreateCurves(obj)
            %% Full Outline generates Curve objects around CircuitJB object
            obj.Curves = Curve('Parent', obj, 'Trace', obj.FullOutline);
            obj.Curves.RunFullPipeline('smooth');
            obj.Curves.Normal2Envelope('main');
            
        end
        
        function obj = CreateRoutes(obj)
            %% Interpolated Outline and Anchor Points create Route objects
            rts = obj.Routes;
            pts = obj.AnchorPoints;
            oL  = obj.getOutline;
            n   = obj.NUMBEROFANCHORS;
            
            % Get indices of Outline matching each Anchor Point
            fidx = @(x,y) find(sum(ismember(x,y), 2) == 2);
            mtch = arrayfun(@(x) fidx(oL(:,:,x),pts(:,:,x)), ...
                1:size(oL,3), 'UniformOutput', 0);
            mtch = cat(2, mtch{:});
            
            % Split Outline into separate Trace between each AnchorPoints
            shp    = @(x) reshape(nonzeros(x), [nnz(x)/2 2]);
            frms   = size(oL,3);
            traces = arrayfun(@(x) split2trace(oL(:,:,x), mtch(:,x), n), ...
                1:frms, 'UniformOutput', 0);
            
            % Set data for all Routes at each frame
            for i = 1 : numel(traces)
                trc = traces{i};
                
                % Copy first anchor point to last index
                newpts = [pts(:,:,i) ; pts(1,:,i)];
                arrayfun(@(x) rts(x).setRawTrace(i, shp(trc(:,:,x))), ...
                    1:n, 'UniformOutput', 0);
                arrayfun(@(x) rts(x).setAnchors(i, newpts(x,:), ...
                    newpts(x+1,:)), 1:n, 'UniformOutput', 0);
                arrayfun(@(x) rts(x).NormalizeTrace, 1:n, 'UniformOutput', 0);
            end
        end
        
        function obj = LabelAllPixels(obj, labelname)
            %% Labels all pixels inside contour as 'Hypocotyl'
            % This is to test out a method of deep learning for semantic
            % segmentation See ref (Long, Shelhammer, Darrell, CVF 2015, 2015)
            % book and MATLAB tutorial at
            % https://www.mathworks.com/help/vision/examples/semantic-segmentation-using-deep-learning.html
            lbl = repmat("", size(obj.Image.bw));
            lbl(obj.Image.bw == 1) = labelname;
            lbl(obj.Image.bw ~= 1) = 'bg';
            obj.Image.labels = lbl;
        end
        
        function obj = generateMasks(obj, buff)
            %% Create probability matrix from manually-drawn outline
            % This function generates a binary mask where the coordinates of
            % the manually-drawn outline are set to 1 and the rest of the image
            % is set to 0.
            %
            % The output size of the image is defined by the buff parameter,
            % because the probability matrix must fit all orientations of
            % hypocotyls in the dataset (think of hypocotyls in the extreme
            % left or right locations).
            %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % NOTE [ 10/31/2018 ]:
            % I created the cropWithBuffer.m function, which gives each cropped
            % Hypocotyl a buffered region around the object. I haven't tested
            % it yet, but I could probably generate probability image masks
            % without having to create the large buffered region that this
            % function creates.
            %
            % tl;dr: I might be able to remove the buff parameter from here
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            img = obj.getImage(1, 'gray');
            crd = obj.getNormalOutline; % Use normalized coordinates
            %             crd = obj.FullOutline;
            msk = crds2mask(img, crd, buff);
            obj.setImage(1, 'mask', msk);
        end
        
        function obj = DrawOutline(obj, frm)
            %% Draw RawOutline on this object's Image
            % The function crds2mask was changed (see generateMasks method for
            % this class) to include a buffering size parameter. When creating
            % the initial CircuitJB contour, just set this to 0 until I
            % understand it better.
            try
                % Trace outline and store as RawOutline
                img = obj.getImage(frm, 'gray');
                c   = drawPoints(img, 'y', 'Outline');
                crd = c.Position;
                obj.setRawOutline(frm, crd);
                obj.setImage(frm, 'bw', c.createMask);
                % Exclude this as it isn't used until creating probability masks
                %                 msk = crds2mask(img, crd, buff);
                %                 obj.setImage(frm, 'mask', msk);
            catch e
                fprintf(2, 'Error setting outline at frame %d \n%s\n', ...
                    frm, e.getReport);
            end
        end
        
        function obj = DrawAnchors(obj, frm)
            %% Draw RawPoints on this object's Image
            try
                % Plot anchor points and store as RawPoints
                img = obj.getImage(frm, 'gray');
                str = sprintf('%d AnchorPoints', obj.NUMBEROFANCHORS);
                p   = drawPoints(img, 'b', str);
                obj.setRawPoints(frm, p.Position);
            catch e
                fprintf(2, 'Error setting anchor points at frame %d\n%s', ...
                    frm, e.getReport);
            end
        end
        
        function obj = DerefParents(obj)
            %% Remove reference to Parent property
            obj.Parent = [];
        end
        
        function obj = ResetReference(obj, exp)
            %% Searches inputted Experiment object to find parent Hypocotyl
            % Iteratively parse though Genotype -> Seedling -> Hypocotyl
            idxA = regexpi(obj.Origin, '{');
            idxB = regexpi(obj.Origin, '}');
            sIdx = obj.Origin(idxA(1) + 1 : idxB(1) - 1);
            %             hIdx = obj.Origin(idxA(2) + 1 : idxB(2) - 1);
            %             frm  = obj.Origin(idxA(3) + 1 : idxB(3) - 1);
            
            gen = exp.search4Genotype(obj.GenotypeName);
            sdl = gen.getSeedling(str2double(sIdx));
            hyp = sdl.MyHypocotyl;
            
            obj.setParent(hyp);
            
        end
        
        function obj = NormalizeOutline(obj)
            %% Normalize InterpOutline to NormalOutline
            % Rescale outlines by base width to set common start and end point
            obj.NormalOutline = rescaleNormMethod(obj.InterpOutline, 15);
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
            %% Convert anchor points from floating RawPoints to snapped
            % AnchorPoints along the manually-drawn outline
            if isempty(obj.InterpOutline)
                obj.ConvertRawOutlines;
            end
            
            iL   = obj.InterpOutline;
            pts  = obj.RawPoints;
            nPts = zeros(size(pts));
            for i = 1 : size(pts,3)
                nPts(:,:,i) = snap2curve(pts(:,:,i), iL(:,:,i));
            end
            
            obj.AnchorPoints = nPts;
        end
        
        function obj = ReconfigInterpOutline(obj)
            %% Convert interpolated outline to Route's interpolated traces
            % This will change the coordinates from this object's InterpOutline
            % property to the InterpTrace of each of this object's Route array.
            % This ensures that there is a segment defining the base segment.
            trc = arrayfun(@(x) x.getInterpTrace, ...
                obj.Routes, 'UniformOutput', 0);
            obj.FullOutline = cat(1, trc{:});
        end
        
        function obj = trainCircuit(obj, trainStatus)
            %% Set this object as 'trained' or 'untrained'
            try
                if islogical(trainStatus)
                    obj.isTrained = trainStatus;
                else
                    fprintf(2, 'input should be logical\n');
                end
            catch
                obj.isTrained = true;
            end
        end
        
    end
    
    %%
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
        
        function obj = setParent(obj, p)
            %% Set this object's parent Hypocotyl object
            obj.Parent = p;
            obj.HypocotylName  = p.HypocotylName;
            obj.GenotypeName   = p.GenotypeName;
            obj.ExperimentName = p.ExperimentName;
            
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
                        fprintf(2, 'Requested fields must be: %s\n', str);
                    end
                    
                otherwise
                    fprintf(2, 'Error requesting data.\n');
                    return;
            end
        end
        
        %function dat = getImage(varargin)
        %    %% Return image data for ContourJB at desired frame [frm, req]
        %    % User can specify which image from structure with 3rd parameter
        %    switch nargin
        %        case 1
        %            % Full structure of image data at all frames
        %            obj = varargin{1};
        %            dat = obj.Image;
        %
        %        case 2
        %            % All image data at frame
        %            try
        %                obj = varargin{1};
        %                frm = varargin{2};
        %                dat = obj.Image(frm);
        %            catch
        %                fprintf(2, 'No image at frame %d \n', frm);
        %            end
        %
        %        case 3
        %            % Specific image type at frame
        %            % Check if frame exists
        %            try
        %                obj = varargin{1};
        %                frm = varargin{2};
        %                req = varargin{3};
        %                dat = obj.Image(frm);
        %            catch
        %                fprintf(2, 'No image at frame %d \n', frm);
        %            end
        %
        %            % Get requested data field
        %            try
        %                dfm = obj.Image(frm);
        %                dat = dfm.(req);
        %            catch
        %                fn  = fieldnames(dfm);
        %                str = sprintf('%s, ', fn{:});
        %                fprintf(2, 'Requested field must be either: %s\n', str);
        %            end
        %
        %        otherwise
        %            fprintf(2, 'Error requesting data.\n');
        %            return;
        %    end
        %end
        
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
                fprintf(2, 'No InterpOutline at frame %d \n', varargin{2});
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
                fprintf(2, 'No InterpOutline at frame %d \n', varargin{2});
            end
        end
        
        function nL = getNormalOutline(varargin)
            %% Return Normalized Outline at specific frame
            try
                obj = varargin{1};
                if nargin == 1
                    nL = obj.NormalOutline;
                else
                    frm = varargin{2};
                    nL = obj.NormalOutline(:,:,frm);
                end
            catch
                fprintf(2, 'No NormalOutline at frame %d \n', varargin{2});
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
        
        function rt = getCurve(varargin)
            %% Return a Route from desired frame
            try
                obj = varargin{1};
                switch nargin
                    case 2
                        rt = obj.Curves;
                        
                    case 3
                        idx = varargin{2};
                        req = varargin{3};
                        typ = sprintf('%sSegments', req);
                        crv = obj.Curves.(typ);
                        rt  = crv(:,:,idx);
                        
                    otherwise
                        fprintf(2, 'No Curve specified\n');
                end
            catch
                fprintf(2, 'Error return Curve %d \n', idx);
            end
        end
        
        function [X, Y] = rasterizeCurves(obj, req)
            %% Rasterize all segments of requested type
            % This method is used to prepare for Principal Components Analysis
            [X, Y] = obj.Curves.rasterizeSegments(req);
            
        end
        
        function [X, Y] = LinearizeRoutes(obj)
            %% Return all X and Y coordinates from all Routes
            [~, X, Y] = concatTraces(obj);
        end
        
        function P = getRouteParameters(obj)
            %% Return all theta, deltaX, deltaY parameters from all Routes
            P = concatParameters(obj);
        end
        
    end
    
    %%
    methods (Access = private)
        %% Private helper methods
        function args = parseConstructorInput(varargin)
            %% Parse input parameters for Constructor method
            p = inputParser;
            p.addOptional('Origin', '');
            p.addOptional('Parent', []);
            p.addOptional('RawOutline', {});
            p.addOptional('InterpOutline', []);
            p.addOptional('FullOutline', []);
            p.addOptional('NormalOutline', []);
            p.addOptional('RawPoints', []);
            p.addOptional('AnchorPoints', []);
            p.addOptional('Image', []);
            p.addOptional('Curves', []);
            p.addOptional('Routes', []);
            p.addOptional('isTrained', false);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
        function R = initializeRoutes(obj)
            %% Initialize Route objects for Constructor
            R = repmat(Route, 1, obj.NUMBEROFANCHORS);
            for i = 1 : obj.NUMBEROFANCHORS
                R(i) = Route('Origin', obj.Origin);
            end
        end
        
        function [C,X,Y] = concatTraces(obj)
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
        
        function P = concatParameters(obj)
            %% Concatenate parameters for Routes into [m x p] array
            % m is the number of Route objects
            % p is the number of parameters
            % Output:
            %   P: parameters for each Route in [m x p] array
            
            R = arrayfun(@(x) x.getPpar, obj.Routes, 'UniformOutput', 0);
            P = cat(1, R{:});
        end
        
    end
    
end

