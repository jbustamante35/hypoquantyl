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
        MANBUF          = 0;                   % Cropping buffer around image
        ARTBUF          = 0;                   % Artificial buffer around image
        IMGSCL          = 1;                   % Rescale size for for image
        LBOUND          = 5;                   % Lower bound of pixels to remove
        NUMBEROFANCHORS = 4                    % Number of sections
        Routes                                 % Coordinates of bottom-left-top-right sections
        AnchorPoints                           % Coordinates of corners
        AnchorIndex                            % Index of corners in contour
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

            %
            obj.Image = struct('gray', [], 'bw', [], 'mask', [], 'labels', []);
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
                crv        = Curve('Parent', obj);
                crv.setProperty('MANBUF', obj.MANBUF);
                crv.setProperty('ARTBUF', obj.ARTBUF);
                crv.setProperty('IMGSCL', obj.IMGSCL);
                obj.Curves = crv;
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

        function LabelAllPixels(obj, labelname, rgn, flp, buf, scl)
            %% Labels all pixels inside contour as 'Hypocotyl'
            % This is to test out a method of deep learning for semantic
            % segmentation See ref (Long, Shelhammer, Darrell, CVF 2015, 2015)
            % book and MATLAB tutorial at
            % https://www.mathworks.com/help/vision/examples/semantic-segmentation-using-deep-learning.html
            if nargin < 2; labelname = 1;       end
            if nargin < 3; rgn       = 'upper'; end
            if nargin < 4; flp       = [];      end
            if nargin < 5; buf       = 0;       end
            if nargin < 6; scl = 1;             end

            msk              = obj.getImage('bw', rgn, flp, buf, scl);
            lbl              = repmat("", size(msk));
            lbl(msk == 1)    = labelname;
            lbl(msk ~= 1)    = 'bg';
            obj.Image.labels = lbl;
        end

        function generateMasks(obj, buf)
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

            if nargin < 2; buf = 0;       end
            if nargin < 3; rgn = 'upper'; end
            if nargin < 4; flp = [];      end

            img = obj.getImage('gray', rgn, flp, buf);
            crd = obj.NormalOutline; % Use normalized coordinates
            msk = crds2mask(img, crd, buf);
            obj.setImage(1, 'mask', msk);
        end

        function [obj , ofix] = FixContour(obj, fidx, vsn, interp_fixer, seg_smooth, flp, mbuf, abuf, scl)
            %% Manually fix the contour
            if nargin < 2; fidx         = 1;          end
            if nargin < 3; vsn          = 'Raw';      end
            if nargin < 4; interp_fixer = 40;         end
            if nargin < 5; seg_smooth   = 10;         end
            if nargin < 6; flp          = [];         end
            if nargin < 7; mbuf         = obj.MANBUF; end % Cropping buffer
            if nargin < 8; abuf         = obj.ARTBUF; end % Artificial buffer
            if nargin < 9; scl          = obj.IMGSCL; end % Image scale

            img  = obj.getImage('gray', 'upper', flp, mbuf, abuf, scl);
            msk  = obj.getImage('bw',   'upper', flp, mbuf, abuf, scl);
            trc  = obj.getOutline(':', vsn, mbuf, scl);
            ofix = OutlineFixer('Object', obj, 'Image', img, 'Mask', msk, ...
                'Curve', trc, 'FigureIndex', fidx, ...
                'InterpFix', interp_fixer, 'SegSmooth', seg_smooth);
        end

        function DrawOutline(obj, rgn, flp, mbuf, abuf, scl, toPrime, fidx)
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
            if nargin < 2; rgn     = 'upper';    end
            if nargin < 3; flp     = [];         end
            if nargin < 6; mbuf    = obj.MANBUF; end % Cropping buffer
            if nargin < 7; abuf    = obj.ARTBUF; end % Artificial buffer
            if nargin < 8; scl     = obj.IMGSCL; end % Image scale
            if nargin < 7; toPrime = 0;          end
            if nargin < 8; fidx    = 1;          end

            try
                img = obj.getImage('gray', rgn, flp, mbuf, abuf, scl);
                str = sprintf('Outline\n%s', fixtitle(obj.Origin));

                if toPrime
                    %% Initialize outline with default segmentation
                    msk       = obj.getImage( ...
                        'bw', rgn, flp, mbuf, abuf, scl);
                    [~ , crd] = extractContour( ...
                        msk, toPrime, 'alt', 'Normalize');
                    obj.setRawOutline(crd);
                else
                    %% Manually trace outline
                    c   = drawPoints(img, [], 'y', str, [], fidx);
                    crd = c.Position;
                    obj.setRawOutline(crd);
                end
            catch e
                frm = obj.getFrame;
                fprintf(2, 'Error setting outline at frame %d \n%s\n', ...
                    frm, e.getReport);
            end
        end

        function DrawAnchors(obj, mth, rgn, flp, mbuf, abuf, scl, fidx)
            %% Draw RawPoints on this object's Image
            % If the buf parameter is set to true, then the image returned from
            % the parent Hypocotyl contains a buffered region around the image.
            %
            % If the flp parameter is set to true, then the FlipMe method is
            % called before prompting user to draw contour.
            if nargin < 2; mth  = 'man';      end
            if nargin < 3; rgn  = 'upper';    end
            if nargin < 4; flp  = [];         end
            if nargin < 5; mbuf = obj.MANBUF; end % Cropping buffer
            if nargin < 6; abuf = obj.ARTBUF; end % Artificial buffer
            if nargin < 7; scl  = obj.IMGSCL; end % Image scale
            if nargin < 8; fidx = 1;          end

            if isempty(obj.getOutline); obj.ConvertRawOutlines; end
            cntr = obj.getOutline(':', 'Full', mbuf, scl);
            switch mth
                case 'auto'
                    % Make artificial anchor points by dividing into N sections
                    slens = obj.getProperty('SEGLENGTH');
                    cinit = [0 , cumsum(slens(1:3))] + 1;
                    apts  = cntr(cinit,:);
                    obj.setRawPoints(apts);
                case 'man'
                    % Plot anchor points manually and store as RawPoints
                    try
                        img = obj.getImage('gray', rgn, flp, mbuf, abuf, scl);
                        str = sprintf('%d AnchorPoints\n%s\n', ...
                            obj.NUMBEROFANCHORS, fixtitle(obj.Origin));
                        p   = drawPoints(img, [], 'b', str, cntr, fidx);
                        obj.setRawPoints(p.Position);
                    catch e
                        fprintf(2, 'Error setting AnchorPoints\n%s', e.getReport);
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
            hyp.setCircuit(obj.getFrame, obj);
        end

        function trc = InterpOutline(obj, pts, vsn)
            %% Interpolate outline
            if nargin < 2; pts = obj.INTERPOLATIONSIZE; end
            if nargin < 3; vsn = 'Full';                end

            if isempty(obj.(sprintf('%sOutline', vsn)))
                trc = [];
            else
                trc = obj.getOutline(vsn);

                % Close contour if open
                if sum(trc(1,:) ~= trc(end,:)); trc = [trc ; trc(1,:)]; end
                trc = interpolateOutline(trc, pts);
            end
        end

        function [nrm , apt] = NormalOutline(obj, trc, init)
            %% Reindex coordinates to normalize start points to anchor point
            if nargin < 2; trc  = obj.InterpOutline; end
            if nargin < 3; init = 'alt';             end

            [apt , aidxs] = findAnchorPoint(obj, trc, init);
            nrm           = obj.repositionPoints(trc, aidxs, init);
        end

        function ConvertRawOutlines(obj, lb, typ, rgn, flp, mbuf, abuf, scl)
            %% Convert contours from RawOutline to InterpOutline
            if nargin < 2; lb   = obj.LBOUND; end % Lower bound of image to cut off
            if nargin < 3; typ  = 'gray';     end
            if nargin < 4; rgn  = 'upper';    end
            if nargin < 5; flp  = [];         end
            if nargin < 6; mbuf = obj.MANBUF; end % Cropping buffer
            if nargin < 7; abuf = obj.ARTBUF; end % Artificial buffer
            if nargin < 8; scl  = obj.IMGSCL; end % Image scale

            if iscell(obj.RawOutline)
                oL = obj.RawOutline{1};
            else
                oL = obj.RawOutline;
            end

            % Close contour if open
            if sum(oL(1,:) ~= oL(end,:)); oL = [oL ; oL(1,:)]; end

            % Interpolate then Exclude Lower Bound
            sz = obj.INTERPOLATIONSIZE;
            iL = interpolateOutline(oL, sz);
            iL = excludeLowerBound(obj, iL, lb, typ, rgn, flp, mbuf, abuf, scl);

            % Close contour if open, Interpolate Again
            if sum(iL(1,:) ~= iL(end,:)); iL = [iL ; iL(1,:)]; end
            iL = interpolateOutline(iL, sz);

            obj.FullOutline = iL;
        end

        function ConvertRawPoints(obj, lb, typ, rgn, flp, mbuf, abuf, scl)
            %% Snap floating RawPoints onto drawn AnchorPoints
            if nargin < 2; lb   = obj.LBOUND; end
            if nargin < 3; typ  = 'gray';     end
            if nargin < 4; rgn  = 'upper';    end
            if nargin < 5; flp  = [];         end
            if nargin < 6; mbuf = obj.MANBUF; end % Cropping buffer
            if nargin < 7; abuf = obj.ARTBUF; end % Artificial buffer
            if nargin < 8; scl  = obj.IMGSCL; end % Image scale

            % First interpolate manually-drawn outline
            if isempty(obj.FullOutline)
                obj.ConvertRawOutlines(lb, typ, rgn, flp, mbuf, abuf, scl);
            end

            cntr = obj.getOutline(':', 'Full', mbuf, scl);
            pts  = obj.RawPoints;

            % Open curve if closed, then snap to nearest point on curve
            if sum(cntr(1,:) == cntr(end,:)); cntr(end,:) = []; end
            [apts , aidx] = snap2curve(pts, cntr);

            % Force 1st Anchor Point to be 1st coordinate-
            obj.AnchorPoints = [cntr(1,:) ; apts(2:end,:)];
            obj.AnchorIndex  = [1         ; aidx(2:end)];
        end

        function ReconfigInterpOutline(obj, vsn, slens, npts)
            %% Convert outline to segmented by Anchor Points
            % This will change the coordinates from this object's InterpOutline
            % property to the InterpTrace of each of this object's Route array.
            % This ensures that there is a segment defining the base segment.
            if nargin < 2; vsn   = 'Full';                end
            if nargin < 3; slens = obj.SEGLENGTH;         end
            if nargin < 4; npts  = obj.INTERPOLATIONSIZE; end

            if size(obj.RawPoints,1) > 4
                % Redo outline manually and remove 5th anchor point
                obj.DrawOutline('upper');
                obj.ConvertRawOutlines;
                obj.RawPoints(end,:) = [];
                obj.ConvertRawPoints;
            end

            %
            cntr  = obj.getOutline(':', vsn);
            cinit = obj.getAnchorPoints(':', 1)';
            cends = [cinit(2:end) , npts] - 1;

            try
                rts = arrayfun(@(i,e,l) interpolateOutline(cntr(i:e,:), l), ...
                    cinit, cends, slens, 'UniformOutput', 0);

                % Close contour
                cntr = cat(1, rts{:});
                if sum(cntr(1,:) ~= cntr(end,:)); cntr = [cntr ; cntr(1,:)]; end

                obj.FullOutline = cntr;
            catch
                % Redo outline manually if error
                obj.DrawOutline('upper');
                obj.ConvertRawOutlines;
                obj.ConvertRawPoints;
                obj.ReconfigInterpOutline(vsn, slens, npts);
            end
        end

        function [cntr , rts] = Full2Clipped(obj, slens, npts)
            %% Full2Clipped: convert contour to clipped and segmented version
            if nargin < 2; slens = obj.SEGLENGTH;         end
            if nargin < 3; npts  = obj.INTERPOLATIONSIZE; end

            %% Remove duplicate corners except for the last point
            cntr  = obj.getOutline(':', 'Full');
            cinit = obj.getAnchorPoints(':', 1)';
            cends = [cinit(2:end) , npts] - 1;
            rts   = arrayfun(@(i,e,l) interpolateOutline(cntr(i:e,:), l), ...
                cinit, cends, slens, 'UniformOutput', 0);

            % Omit and stitch cotyledon segment [segment 2]
            rts{2} = interpolateOutline( ...
                [rts{2}(1,:) ; rts{2}(end,:)], slens(2));

            % Close contour
            cntr = cat(1, rts{:});
            if sum(cntr(1,:) ~= cntr(end,:)); cntr = [cntr ; cntr(1,:)]; end

            obj.ClipOutline = cntr;
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

        function img = getImage(obj, req, rgn, flp, mbuf, abuf, scl)
            %% getImage: return image from CircuitJB object
            if nargin < 2; req  = 'gray';     end
            if nargin < 3; rgn  = 'upper';    end
            if nargin < 4; flp  = [];         end
            if nargin < 5; mbuf = obj.MANBUF; end % Cropping buffer
            if nargin < 6; abuf = obj.ARTBUF; end % Artificial buffer
            if nargin < 7; scl  = obj.IMGSCL; end % Image scale

            if isempty(flp); flp = obj.checkFlipped; end
            frm = obj.getFrame;
            img = obj.Parent.getImage(frm, req, rgn, flp, ...
                mbuf, abuf, scl);
        end

        function setOutline(obj, crds, otyp)
            %% Set coordinates to an outline
            %  function setFullOutline(obj, crds)
            if nargin < 3; otyp = 'Full'; end
            try
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
            if nargin < 2; idx = ':'; end
            try
                crds = obj.getOutline('Raw', idx);
            catch e
                fprintf(2, 'Error returning RawOutline\n%s\n', e.getReport);
                crds = [];
            end
        end

        function [trc , goo , soo] = getOutline(obj, idx, otyp, mbuf, scl)
            %% Return Interpolated Outline
            if nargin < 2; idx  = ':';        end
            if nargin < 3; otyp = 'Full';     end
            if nargin < 4; mbuf = obj.MANBUF; end % Cropping buffer
            if nargin < 5; scl  = obj.IMGSCL; end % Image scale

            try
                % If idx input is outline type
                if ischar(idx) && ~strcmpi(idx, ':')
                    otyp = idx;
                    idx  = ':';
                end

                oL  = sprintf('%sOutline', otyp);
                trc = obj.(oL)(idx,:);

                % Modify if using a buffered image
                [goo , soo] = deal(0);
                if mbuf ~= obj.MANBUF || scl ~= obj.IMGSCL
                    [trc , goo , soo] = obj.contourRemap(trc, mbuf, scl);
                end
            catch
                fprintf(2, 'Error returning %sOutline\n', otyp);
                [trc , goo , soo] = deal([]);
                return;
            end
        end

        function [trc , goo , soo] = contourRemap(obj, trc, mbuf, scl)
            %% Remap coordinates after changing crop box
            if nargin < 3; mbuf = obj.MANBUF; end % Cropping buffer
            if nargin < 4; scl  = obj.IMGSCL; end % Image scale

            %
            hyp = obj.Parent;
            sdl = hyp.Parent;
            gen = sdl.Parent;

            % Original and adjusted images
            frm = obj.getFrame;
            gio = gen.getImage(frm, 'gray');
            sio = sdl.getImage(frm, 'gray', 0);
            sic = sdl.getImage(frm, 'gray', mbuf);
            hio = hyp.getImage(frm, 'gray', 'upper', [], 0, 0, 1);
            hic = hyp.getImage(frm, 'gray', 'upper', [], mbuf, 0, scl);

            % Adjust cropboxes
            soff = [-mbuf , -mbuf , mbuf*2 , mbuf]; % [left , top , 2*right , bottom]
            hoff = [0    , 0    , mbuf*2 , mbuf]; % [left , top , 2*right , bottom]
            gbo  = sdl.getPData(frm, 'BoundingBox');
            sbo  = hyp.getCropBox(frm, 'upper');

            % Return out-of-bounds pixels
            [gbc , goo] = bufferCropBox(gbo, soff, gio);
            [sbc , soo] = bufferCropBox(sbo, hoff, sic);

            % Hypocotyl -> Seedling -> Genotype -> Seedling -> Hypocotyl
            h2s = remapCoordinates(hio, sio, sbo, trc, 'h2s');
            s2g = remapCoordinates(sio, gio, gbo, h2s, 's2g');
            g2s = remapCoordinates(gio, sic, gbc, s2g, 'g2s');
            trc = remapCoordinates(sic, hic, sbc, g2s, 's2h');
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

        function apts = getAnchorPoints(obj, idx, getIdx)
            %% Return all or specific set of AnchorPoints
            if nargin < 2; idx    = ':'; end
            if nargin < 3; getIdx = 0;   end % Get indices instead
            try
                if getIdx
                    apts = obj.AnchorIndex(idx);
                else
                    apts = obj.AnchorPoints(idx,:);
                end
            catch
                fprintf(2, 'Error returning AnchorPoint %d\n', idx);
                apts = [];
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

        function [apt , idx] = findAnchorPoint(obj, crds, init)
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

        function crds = excludeLowerBound(obj, crds, lb, typ, rgn, flp, mbuf, abuf, scl)
            %% excludeLowerBound: exclude all points below lower bound
            if nargin < 3; lb   = obj.LBOUND; end
            if nargin < 4; typ  = 'gray';     end
            if nargin < 5; rgn  = 'upper';    end
            if nargin < 6; flp  = [];         end
            if nargin < 7; mbuf = obj.MANBUF; end % Cropping buffer
            if nargin < 8; abuf = obj.ARTBUF; end % Artificial buffer
            if nargin < 9; scl  = obj.IMGSCL; end % Image scale

            sz   = size(obj.getImage(typ, rgn, flp, mbuf, abuf, scl), 2);
            lb   = sz - lb;
            crds = crds(crds(:,2) <= lb,:);
        end
    end
end
