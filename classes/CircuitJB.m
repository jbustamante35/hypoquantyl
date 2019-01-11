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
        isFlipped
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
            % Generate InterpOutline and NormalOutline if not yet done
            if isempty(obj.NormalOutline)
                obj.ReconfigInterpOutline;
                obj.NormalizeOutline;
            end
            
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
            findIdx = @(x,y) find(sum(ismember(x,y), 2) == 2);
            mtch    = findIdx(oL, pts);
            
            % Split Outline into separate Trace between each AnchorPoints
            shp    = @(x) reshape(nonzeros(x), [nnz(x)/2 2]);
            traces = split2trace(oL, mtch, n);
            
            % Set data from this object's outline for all Routes
            % Copy first anchor point to last index
            newpts = [pts ; pts(1,:)];
            arrayfun(@(x) rts(x).setRawTrace(shp(traces(:,:,x))), ...
                1:n, 'UniformOutput', 0);
            arrayfun(@(x) rts(x).setAnchors(newpts(x,:), newpts(x+1,:)), ...
                1:n, 'UniformOutput', 0);
            arrayfun(@(x) rts(x).NormalizeTrace, 1:n, 'UniformOutput', 0);
            
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
        
        function obj = DrawOutline(obj, buf, flp)
            %% Draw RawOutline on this object's Image
            % The function crds2mask was changed (see generateMasks method for
            % this class) to include a buffering size parameter. When creating
            % the initial CircuitJB contour, just set this to 0 until I
            % understand it better.
            %
            % If the buf parameter is set to true, then the image returned from
            % the parent Hypocotyl contains a buffered region around the image.
            %
            % If the flp parameter is set to true, then the FlipMe method is
            % called before prompting user to draw contour.
            try
                % Trace outline and store as RawOutline
                img = obj.getImage(buf, flp);
                str = sprintf('Outline\n%s', fixtitle(obj.Origin));
                c   = drawPoints(img, 'y', str);
                crd = c.Position;
                obj.setRawOutline(crd);
                
                % Exclude this as it isn't used until creating probability masks
                % msk = crds2mask(img, crd, buff);
                % obj.setImage(frm, 'mask', msk);
            catch e
                fprintf(2, 'Error setting outline at frame %d \n%s\n', ...
                    frm, e.getReport);
            end
        end
        
        function obj = DrawAnchors(obj, buf, flp)
            %% Draw RawPoints on this object's Image
            % If the buf parameter is set to true, then the image returned from
            % the parent Hypocotyl contains a buffered region around the image.
            %
            % If the flp parameter is set to true, then the FlipMe method is
            % called before prompting user to draw contour.
            try
                % Plot anchor points and store as RawPoints
                img = obj.getImage(buf, flp);
                str = sprintf('%d AnchorPoints\n%s\n', ...
                    obj.NUMBEROFANCHORS, fixtitle(obj.Origin));
                p   = drawPoints(img, 'b', str);
                obj.setRawPoints(p.Position);
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
            iL = interpolateOutline(oL, sz);
            
            obj.InterpOutline = iL;
        end
        
        function obj = ConvertRawPoints(obj)
            %% Snap floating RawPoints onto drawn AnchorPoints
            % First interpolate manually-drawn outline
            if isempty(obj.InterpOutline)
                obj.ConvertRawOutlines;
            end
            
            iL   = obj.InterpOutline;
            pts  = obj.RawPoints;
            nPts = snap2curve(pts, iL);
            
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
        
        function frm = getFrame(obj)
            %% Return frame number of this object's parent Hypocotyl
            % The frame number is the last number in curly brackets from the
            % name of this CircuitJB object.
            % (e.g 'sorted_blue_4-16BL_mdr1_Seedling_{2}_Hypocotyl_{2}_Frm{69}')
            nm  = obj.Origin;
            aa  = strfind(nm, '{');
            bb  = strfind(nm, '}');
            frm = str2double(nm(aa(end) + 1 : bb(end) - 1));
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
            % Frame number is automatically deterimend since it is the final
            % bit of data in the name (Origin property). If I need frame number
            % anywhere else then I'll make it a method.
            obj = varargin{1};
            
            switch nargin
                case 1
                    % Full structure of image data
                    dat = obj.Image;
                    
                case 2
                    % Returns requested image type
                    try
                        req = varargin{2};
                        
                        frm = obj.getFrame;
                        flp = obj.checkFlipped;
                        
                        if flp
                            dat = flip(obj.Parent.getImage(frm, req), 2);
                        else
                            dat = obj.Parent.getImage(frm, req);
                        end
                        
                    catch
                        fprintf(2, 'No image at frame %d \n', frm);
                    end
                    
                case 3
                    % Returns buffered image with the option to use the flipped
                    % version of the image
                    try
                        buf = varargin{2};                        
                        flp = varargin{3};
                        
                        frm = obj.getFrame;
                        dat = obj.Parent.getImage(frm, buf, flp);
                        
                    catch
                        fprintf(2, 'No image at frame %d \n', frm);
                    end
                    
                otherwise
                    fprintf(2, 'Error requesting data.\n');
                    return;
            end
        end
        
        function obj = setRawOutline(obj, oL)
            %% Set coordinates for RawOutline at specific frame
            try
                obj.RawOutline = oL;
            catch e
                fprintf(2, 'Error setting RawOutline\n%s\n', e.getReport);
            end
        end
        
        function oL = getRawOutline(obj)
            %% Return RawOutline at specific frame
            try
                oL = obj.RawOutline;
            catch e
                fprintf(2, 'Error returning RawOutline\n%s\n', e.getReport);
                oL = [];
            end
        end
        
        function iL = getOutline(obj)
            %% Return Interpolated Outline at specific frame
            try
                iL = obj.InterpOutline;
            catch e
                fprintf(2, 'Error returning InterpOutline\n%s\n', e.getReport);
            end
        end
        
        function nL = getNormalOutline(obj)
            %% Return Normalized Outline at specific frame
            try
                nL = obj.NormalOutline;
            catch e
                fprintf(2, 'Error returning NormalOutline\n%s\n', e.getReport);
            end
        end
        
        function obj = setRawPoints(obj, pts)
            %% Set coordinates pts to AnchorPoint at specific frame
            try
                obj.RawPoints = pts;
            catch e
                fprintf(2, 'Error setting RawPoints\n%s\n', e.getReport);
            end
        end
        
        function pts = getRawPoints(obj)
            %% Return RawPoints at specific frame
            try
                pts = obj.RawPoints;
            catch e
                fprintf(2, 'Error returning RawPoints\n%s\n', e.getReport);
            end
        end
        
        function pts = getAnchorPoints(varargin)
            %% Return all or specific set of AnchorPoints
            try
                obj = varargin{1};
                if nargin == 1
                    pts = obj.AnchorPoints;
                else
                    idx = varargin{2};
                    pts = obj.AnchorPoints(idx, :);
                end
            catch e
                fprintf(2, 'Error returning AnchorPoints\n%s\n', e.getReport);
                pts = [];
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
            %% Return Curve object [DEPRECATED]
            % This is a deprecated method. Just take the Curves property.
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
        
        function chk = checkFlipped(obj)
            %% Returns TRUE if this object is the flipped version
            chk           = contains(obj.Origin, 'flip');
            obj.isFlipped = chk;
        end
        
        function prp = getProperty(obj, req)
            %% Returns requested property if it exists
            try
                prp = obj.(req);
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
            p.addOptional('isFlipped', false);
            
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

