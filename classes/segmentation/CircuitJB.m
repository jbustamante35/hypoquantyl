%% Circuit: class for holding contours with defined anchor points
% Descriptions

classdef CircuitJB < handle & matlab.mixin.Copyable
    properties (Access = public)
        Origin
        Parent
        HypocotylName
        ExperimentName
        GenotypeName
        FullOutline
        Curves
        isTrained
        isFlipped
    end
    
    properties (Access = private)
        INTERPOLATIONSIZE = 210 % [gives 1 points per pixel]
        Image
        RawPoints
        RawOutline
        ClipOutline
        SEGLENGTH       = [53 , 52 , 53 , 51]; % Lengths of sections
        NUMBEROFANCHORS = 4                    % Number of sections
        Routes                                 % Coordinates of bottom-left-top-right sections
        AnchorPoints                           % Coordinates of corners
    end
    
    %%
    methods (Access = public)
        %% Constructor and primary methods
        function obj = CircuitJB(varargin)
            %% Constructor method for CircuitJB
            if ~isempty(varargin)
                % Parse inputs to set properties
                vargs = varargin;
            else
                % Set default properties for empty object
                vargs = {};
            end
            
            prps   = properties(class(obj));
            deflts = {...
                'isTrained', false ; ...
                'isFlipped', false};
            obj    = classInputParser(obj, prps, deflts, vargs);
            
            obj.Image  = struct('gray', [], 'bw', [], 'mask', [], 'labels', []);
        end
        
        function CreateCurves(obj, overwrite)
            %% Full Outline generates Curve objects around CircuitJB object
            % Generate InterpOutline and NormalOutline if not yet done
            % Set overwrite to 'skip' to skip curves that are already created
            if nargin < 2; overwrite = 'skip'; end
            
            switch overwrite
                case 'redo'
                    % Redo pipeline even if already done
                    chkEmpty   = true;
                    obj.Curves = [];
                    
                case 'skip'
                    % Run pipeline only if data is empty
                    chkEmpty = isempty(obj.Curves);
            end
            
            if chkEmpty                
                obj.Curves = Curve('Parent', obj);
            else
                fprintf('\nSkipping %s\n', obj.Origin);
            end
        end
        
        function CreateRoutes(obj)
            %% Interpolated Outline and Anchor Points create Route objects
            %             rts = obj.Routes;
            pts = obj.AnchorPoints;
            oL  = obj.getOutline;
            n   = obj.NUMBEROFANCHORS;
            rts = arrayfun(@(x) Route, 1 : n, 'UniformOutput', 0);
            
            % Get indices of Outline matching each Anchor Point
            findIdx = @(x,y) find(sum(ismember(x,y), 2) == 2);
            mtch    = findIdx(oL, pts);
            
            % Split Outline into separate Trace between each AnchorPoints
            traces = split2trace(oL, mtch, n);
            
            % Set data from this object's outline for all Routes
            % Copy first anchor point to last index
            newpts = [pts ; pts(1,:)];
            pn     = arrayfun(@(x) x, 1 : n, 'UniformOutput', 0);
            cellfun(@(r,p) r.setOrigin(sprintf('Route_%d', p)), ...
                rts, pn, 'UniformOutput', 0);
            cellfun(@(r,t) r.setRawTrace(t), rts, traces, 'UniformOutput', 0);
            cellfun(@(r,p) r.setAnchors(newpts(p,:), newpts(p+1,:)), ...
                rts, pn, 'UniformOutput', 0);
            cellfun(@(r) r.NormalizeTrace, rts, 'UniformOutput', 0);
            obj.Routes = cat(1, rts{:});
        end
        
        function rts = getRoute(obj, n)
            %% Return Route
            if nargin < 2; n = ':'; end
            rts = obj.Routes(n);
        end
        
        function DeleteRoutes(obj)
            %% Delete the Route child objects
            % Because I don't use them and their dum
            obj.Routes        = [];
            obj.NormalOutline = [];
        end
        
        function LabelAllPixels(obj, labelname)
            %% Labels all pixels inside contour as 'Hypocotyl'
            % This is to test out a method of deep learning for semantic
            % segmentation See ref (Long, Shelhammer, Darrell, CVF 2015, 2015)
            % book and MATLAB tutorial at
            % https://www.mathworks.com/help/vision/examples/semantic-segmentation-using-deep-learning.html
            lbl = repmat("", size(obj.Image.bw));
            lbl(obj.Image.bw == 1) = labelname;
            lbl(obj.Image.bw ~= 1) = 'bg';
            obj.Image.labels       = lbl;
        end
        
        function generateMasks(obj, buff)
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
            
            img = obj.getImage('gray');
            crd = obj.NormalOutline; % Use normalized coordinates
            msk = crds2mask(img, crd, buff);
            obj.setImage(1, 'mask', msk);
        end
        
        function [obj , ofix] = FixContour(obj, fidx, interp_fixer, seg_smooth)
            %% Manually fix the contour
            switch nargin
                case 1
                    fidx         = 1;
                    interp_fixer = 40;
                    seg_smooth   = 10;
                case 2
                    interp_fixer = 40;
                    seg_smooth   = 10;
                case 3
                    seg_smooth = 10;
            end
            
            img  = obj.getImage;
            trc  = obj.getOutline;
            ofix = OutlineFixer('Object', obj, 'Image', img, ...
                'Curve', trc, 'FigureIndex', fidx, ...
                'InterpFix', interp_fixer, 'SegSmooth', seg_smooth);
        end
        
        function DrawOutline(obj, buf)
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
                img = obj.getImage('gray', buf);
                str = sprintf('Outline\n%s', fixtitle(obj.Origin));
                c   = drawPoints(img, 'y', str);
                crd = c.Position;
                obj.setRawOutline(crd);
            catch e
                frm = obj.getFrame;
                fprintf(2, 'Error setting outline at frame %d \n%s\n', ...
                    frm, e.getReport);
            end
        end
        
        function DrawAnchors(obj, buf, mth)
            %% Draw RawPoints on this object's Image
            % If the buf parameter is set to true, then the image returned from
            % the parent Hypocotyl contains a buffered region around the image.
            %
            % If the flp parameter is set to true, then the FlipMe method is
            % called before prompting user to draw contour.
            if nargin < 3
                mth = 'man';
            end
            
            switch mth
                case 'auto'
                    % Make artificial anchor points by dividing into 7 sections
                    if isempty(obj.getOutline)
                        obj.ConvertRawOutlines;
                    end
                    
                    segSz  = obj.INTERPOLATIONSIZE;
                    ancPts = obj.NUMBEROFANCHORS - 1;
                    endPts = obj.RawOutline(end,:);
                    cntr   = obj.getOutline;
                    pIdx   = [1 : ceil(segSz / ancPts) : segSz , 1];
                    apts   = [cntr(pIdx,:) ; endPts];
                    obj.setRawPoints(apts);
                    
                case 'man'
                    % Plot anchor points manually and store as RawPoints
                    try
                        img = obj.getImage('gray', buf);
                        str = sprintf('%d AnchorPoints\n%s\n', ...
                            obj.NUMBEROFANCHORS, fixtitle(obj.Origin));
                        p   = drawPoints(img, 'b', str);
                        obj.setRawPoints(p.Position);
                    catch e
                        fprintf(2, 'Error setting anchor points at frame %d\n%s', ...
                            frm, e.getReport);
                    end
                    
                otherwise
                    fprintf('No AnchorPoint method selected (%s)\n', mth);
            end
            
        end
        
        function DerefParents(obj)
            %% Remove reference to Parent property
            obj.Parent = [];
        end
        
        function ResetReference(obj, exp)
            %% Searches inputted Experiment object to find parent Hypocotyl
            % Iteratively parse though Genotype -> Seedling -> Hypocotyl
            idxA = regexpi(obj.Origin, '{');
            idxB = regexpi(obj.Origin, '}');
            sIdx = obj.Origin(idxA(1) + 1 : idxB(1) - 1);
            
            % Find Genotype
            gen = exp.search4Genotype(obj.GenotypeName);
            sdl = gen.getSeedling(str2double(sIdx));
            hyp = sdl.MyHypocotyl;
            
            obj.setParent(hyp);
            if obj.isFlipped
                toFlp = 'flp';
            else
                toFlp = 'org';
            end
            
            hyp.setCircuit(obj.getFrame, obj, toFlp);
            
        end
        
        function trc = InterpOutline(obj, pts, vsn)
            %% Interpolate outline
            switch  nargin
                case 1
                    pts = obj.INTERPOLATIONSIZE;
                    vsn = 'Full';
                case 2
                    vsn = 'Full';
            end
            
            trc = obj.getOutline(vsn);
            trc = interpolateOutline(trc, pts);
        end
        
        function [nrm , apt] = NormalOutline(obj, trc, init)
            %% Reindex coordinates to normalize start points to anchor point
            switch nargin
                case 1
                    trc  = obj.InterpOutline;
                    init = 'alt';
                case 2
                    init = 'alt';
            end
            
            [apt, aidxs] = findAnchorPoint(obj, trc, init);
            nrm          = obj.repositionPoints(trc, aidxs, init);
            
        end
        
        function ConvertRawOutlines(obj)
            %% Convert contours from RawOutline to InterpOutline
            if iscell(obj.RawOutline)
                oL = obj.RawOutline{1};
            else
                oL = obj.RawOutline;
            end
            
            % Wrap contour back to first coordinate
            oL = [oL ; oL(1,:)];
            sz = obj.INTERPOLATIONSIZE;
            iL = interpolateOutline(oL, sz);
            
            obj.InterpOutline = iL;
        end
        
        function ConvertRawPoints(obj)
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
        
        function ReconfigInterpOutline(obj)
            %% Convert interpolated outline to Route's interpolated traces
            % This will change the coordinates from this object's InterpOutline
            % property to the InterpTrace of each of this object's Route array.
            % This ensures that there is a segment defining the base segment.
            obj.FullOutline = obj.InterpOutline;
        end
        
        function trainCircuit(obj, trainStatus)
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
    
    %% -------------------------- Helper Methods ---------------------------- %%
    methods (Access = public)
        %% Various helper methods
        function setOrigin(obj, org)
            %% Set parent of this CircuitJB
            obj.Origin = org;
        end
        
        function org = getOrigin(obj)
            %% Return parent of this CircuitJB
            org = obj.Origin;
        end
        
        function setParent(obj, p)
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
        
        function setImage(obj, frm, req, img)
            %% Set grayscale or bw image at given frame [frm, req, img]
            try
                obj.Image(frm).(req) = img;
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
                    %% Grayscale image
                    frm = obj.getFrame;
                    flp = obj.checkFlipped;
                    if flp
                        dat = flip(obj.Parent.getImage(frm), 2);
                    else
                        dat = obj.Parent.getImage(frm);
                    end
                    
                case 2
                    %% Returns requested image type
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
                        % Check if image is hard-set inside object
                        dat = obj.Image.(req);
                    end
                    
                case 3
                    %% Returns buffered image [not implemented]
                    % version of the image
                    try
                        req = varargin{2};
                        buf = varargin{3};
                        flp = obj.checkFlipped;
                        
                        frm = obj.getFrame;
                        dat = obj.Parent.getImage(frm, req, flp, buf);
                    catch
                        fprintf(2, 'No image at frame %d \n', frm);
                        dat = [];
                    end
                    
                otherwise
                    fprintf(2, 'Error requesting data.\n');
                    return;
            end
        end
        
        function setOutline(obj, crds, otyp)
            %% Set coordinates to an outline
            %  function setFullOutline(obj, crds)
            try
                if nargin < 3
                    otyp = 'Full';
                end
                
                oline       = sprintf('%sOutline', otyp);
                obj.(oline) = crds;
            catch
                fprintf(2, 'Error setting %sOutline\n', otyp);
            end
        end
        
        function setRawOutline(obj, crds)
            %% Set coordinates for RawOutline at specific frame
            try
                obj.setOutline(crds, 'Raw');
            catch e
                fprintf(2, 'Error setting RawOutline\n%s\n', e.getReport);
            end
        end
        
        function crds = getRawOutline(obj, idx)
            %% Return RawOutline at specific frame
            try
                if nargin < 2
                    idx = ':';
                end
                crds = obj.getOutline('Raw', idx);
            catch e
                fprintf(2, 'Error returning RawOutline\n%s\n', e.getReport);
                crds = [];
            end
        end
        
        function trc = getOutline(obj, idx, otyp)
            %% Return Interpolated Outline
            try
                switch nargin
                    case 1
                        idx  = ':';
                        otyp = 'Full';
                    case 2
                        otyp = 'Full';
                end
                
                % If idx input is outline type
                if ischar(idx) && ~strcmpi(idx, ':')
                    otyp = idx;
                    idx  = ':';
                end
                
                oL  = sprintf('%sOutline', otyp);
                trc = obj.(oL)(idx,:);
            catch
                fprintf(2, 'Error returning %sOutline\n', otyp);
                trc = [];
                return;
            end
        end
        
        function setRawPoints(obj, pts)
            %% Set coordinates pts to AnchorPoint
            try
                obj.RawPoints = pts;
            catch e
                fprintf(2, 'Error setting RawPoints\n%s\n', e.getReport);
            end
        end
        
        function pts = getRawPoints(obj, idx)
            %% Return RawPoints
            if nargin < 2; idx = ':'; end
            
            try
                pts = obj.RawPoints(idx,:);
            catch e
                fprintf(2, 'Error returning RawPoints\n%s\n', e.getReport);
            end
        end
        
        function pts = getAnchorPoints(obj, idx)
            %% Return all or specific set of AnchorPoints
            if nargin < 2; idx = ':'; end
            try
                pts = obj.AnchorPoints(idx,:);
            catch
                fprintf(2, 'Error returning AnchorPoint %d\n', idx);
                pts = [];
            end
        end
        
        function chk = checkFlipped(obj)
            %% Returns TRUE if this object is the flipped version
            chk           = contains(obj.Origin, 'flip');
            obj.isFlipped = chk;
        end
        
        function setProperty(obj, req, val)
            %% Set requested property if it exists [for private properties]
            try
                obj.(req) = val;
            catch e
                fprintf(2, 'Property %s not found\n%s\n', req, e.getReport);
            end
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
    
    %% ------------------------- Private Methods --------------------------- %%
    methods (Access = private)
        %% Private helper methods
        function P = concatParameters(obj)
            %% Concatenate parameters for Routes into [m x p] array
            % m is the number of Route objects
            % p is the number of parameters
            % Output:
            %   P: parameters for each Route in [m x p] array
            R = arrayfun(@(x) x.getPpar, obj.Routes, 'UniformOutput', 0);
            P = cat(1, R{:});
        end
        
        function [apt, idx] = findAnchorPoint(obj, crds, init)
            %% findAnchorPoint: find anchor point coordinate
            % The definition of the anchor point is determined by the algorithm
            % selected.
            %
            % The first is typically for CarrotSweeper, where the
            % anchor point is defined as lowest and central column of the
            % corresponding image. This is the default algorithm if the alg
            % parameter is empty.
            %
            % The second algorithm is for HypoQuantyl, where the anchor point is
            % defined as the lower-left coordinate of the image. This is the
            % standardaized starting location for training hypocotyl images. The
            % alg parameter should be set to 1 or true to use this.
            %
            if strcmpi(init , 'default')
                %% Use CarrotSweeper's anchor point
                low = min(crds(:,1));
                rng = round(crds(crds(:,1) == low, :), 4);
                
                % Get median of column range
                if mod(size(rng,1), 2)
                    mtc = median(rng, 1);
                else
                    % Remove last row if even number of values
                    nrng = rng(1:end-1, :);
                    mtc  = median(nrng, 1);
                end
                
                % Get index of Anchor Point
                idx = find(ismember(round(crds, 4), round(mtc, 4), 'rows'));
                if ~isempty(idx > 1)
                    % Check if more than 1 index and choose larger index
                    idx = max(idx);
                elseif isnan(mtc)
                    % Check if no index found, if range is only a single value
                    %idx = find(crds == rng);
                    idx = find(ismember(round(crds), round(rng), 'rows'));
                end
            else
                %% Use HypoQuantyl's anchor point
                % Get the initial starting point for contours and shift indexing
                % of coordinates for CircuitJB objects used in my training set.
                %
                % UPDATE [06.02.2021]
                % This will now identify the base of the contour and set the
                % starting point to the left-most point of the base.
                LOWRANGE = 2;
                b        = labelContour(crds, LOWRANGE);
                bidxs    = find(b);
                idx      = bidxs(end);
            end
            
            %% Pull out the anchor point from the coordinates
            apt = crds(idx, :);
        end
        
        function shft = repositionPoints(obj, crds, idx, init)
            %% Shift contour points around AnchorPoint coordinate
            if strcmpi(init, 'default')
                %% Re-index and Re-Center around AnchorPoint
                subt = crds - crds(idx,:);
                shft = circshift(subt, -idx+1);
            else
                %% Only Re-index saround AnchorPoint coordinate
                shft = circshift(crds, -idx+1);
            end
        end
    end
end
