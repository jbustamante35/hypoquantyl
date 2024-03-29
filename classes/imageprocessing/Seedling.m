%% Seedling: class containing an individual seedling from a Genotype image stack
% Class description

classdef Seedling < handle
    properties (Access = public)
        %% Seedling properties
        Parent
        Host
        ExperimentName
        ExperimentPath
        GenotypeName
        SeedlingName
        Frame
        Lifetime
        Coordinates
        MyHypocotyl
        Status
    end

    properties (Access = private)
        %% Private data
        Midline
        AnchorPoints
        GoodFrames
        PreHypocotyl
        Image
        PData
        Contour
        RawName
        SCALESIZE    = [101 , 101]
        %         PDPROPERTIES = {'Area', 'BoundingBox', 'PixelList', 'Centroid', 'WeightedCentroid', 'Orientation'};
        PDPROPERTIES = {'Area', 'BoundingBox', 'PixelList', 'WeightedCentroid', 'Orientation'};
        CONTOURSIZE  = 250 % number of points to normalize Hypocotyl contours
        SDLBUFFER    = [0 , 0 , 0 , 0] % Seedling Bounding Box Buffer
        HYPBUFFER    = [0 , 0 , 0 , 0] % Hypocotyl Anchor Points Buffer
        TESTS2RUN    = [0 , 0 , 0 , 0 , 0 , 0];	% manifest to determine which quality checks to run
    end

    %% ------------------------- Primary Methods --------------------------- %%
    methods (Access = public)
        %% Constructor and main functions
        function obj = Seedling(varargin)
            %% Constructor method for Seedling
            if ~isempty(varargin)
                % Parse inputs to set properties
                vargs = varargin;
            else
                % Set default properties for empty object
                vargs = {};
            end

            prps   = properties(class(obj));
            deflts = {...
                'Lifetime', 0 ; ...
                'Coordinates', [0 0] ; ...
                'Frame' , [0 0]};
            obj    = classInputParser(obj, prps, deflts, vargs);

            if ~isfield(obj.PData, obj.PDPROPERTIES{1})
                c = cell(1, numel(obj.PDPROPERTIES));
                obj.PData = cell2struct(c', obj.PDPROPERTIES);
            end

            obj.Image = struct('gray', [], 'bw',   [], 'ctr', ContourJB);
        end

        %         function FixSeedlingName(obj)
        %             hyp = obj.MyHypocotyl;
        %             obj.SeedlingName = hyp.SeedlingName;
        %         end

        function good_frames = RemoveBadFrames(obj)
            %% Remove frames with empty data and keep good frames
            % Run through multiple tests to determine good indices
            % This function removes poor frames and stores good frames in gdIdx
            % Current tests:
            %   1) Empty coordinates
            %   2) Empty PData
            %   3) Empty image and contour data
            %   4) Empty AnchorPoints
            %   5) Out of frame growth
            %   6) Collisions

            % Get index of good frames, then remove bad frames
            good_frames  = runQualityChecks(obj, obj.TESTS2RUN);
            obj.Lifetime = numel(good_frames);
            obj.setFrame(min(good_frames), 'b');
            obj.setFrame(max(good_frames), 'd');
            obj.GoodFrames = good_frames;
        end

        function hyp = FindHypocotylAllFrames(obj, v)
            %% Extract Hypocotyl at all frames using the extractHypocotyl
            % method for this Seedling's total Lifetime
            if nargin < 2; v = 0; end % Verbosity

            try
                if v; t = tic; fprintf('%s |', obj.SeedlingName); end

                rng = 1 : obj.Lifetime;
                hyp = arrayfun(@(x) obj.extractHypocotyl(x, v), ...
                    rng, 'UniformOutput', 0);

                if v; fprintf('| %d [%.02f sec]\n', numel(hyp), toc(t)); end

            catch e
                fprintf(2, 'Error extracting Hypocotyl from %s\n%s', ...
                    obj.SeedlingName, e.getReport);

                if v; fprintf('[%.02f sec]\n', toc); end
            end
        end

        function obj = PruneHypocotyls(obj)
            %% Remove PreHypocotyls to decrease data
            obj.PreHypocotyl = [];
        end

        function hyp = SortPreHypocotyls(obj)
            %% Compile PreHypocotyls into single Hypocotyl based on frame number
            % My original algorithm instances individual Hypocotyl objects for each
            % frame for each Seedling for each Genotype. This means creating
            % thousands of objects.
            %
            % I don't understand why I did it this way initially, but it's about
            % time I fixed it. Saving >1000 objects is incredibly wasteful and
            % is part of the reason my save files are enormous.

            % Initialize new Hypocotyl object
            pre = obj.getAllPreHypocotyls;
            rng = [pre(1).getFrame('b') , pre(end).getFrame('b')];
            sn  = obj.getSeedlingName;
            aa  = strfind(sn, '{');
            bb  = strfind(sn, '}');
            nm  = sprintf('Hypocotyl_{%s}', sn(aa + 1 : bb - 1));
            hyp = Hypocotyl('HypocotylName', nm, 'Frame', rng);
            hyp.setParent(obj);
            hyp.Lifetime = max(rng);

            % Compile data into new object
            hyp = compileHypocotyl(obj, hyp, pre);

            % Set this object's Hypocotyl property
            obj.MyHypocotyl = hyp;
        end

        function obj = DerefParents(obj)
            %% Remove reference to Parent property
            obj.Parent = [];
            obj.Host   = [];
        end

        function obj = RefChild(obj)
            %% Set reference back to Children [ after use of DerefParents ]
            arrayfun(@(x) x.setParent(obj), ...
                obj.PreHypocotyl, 'UniformOutput', 0);
        end
    end

    %% ------------------------- Helper Methods ---------------------------- %%
    methods (Access = public) %% Various methods for this class
        function obj = setSeedlingName(obj, sn, setRaw)
            %% Set name for Seedling
            if nargin < 3; setRaw = 0; end

            if ~setRaw
                obj.SeedlingName = char(sn);
            else
                obj.RawName = char(sn);
            end
        end

        function gi = getGenotypeIndex(obj)
            %% Return index of the Genotype
            [~ , gi] = obj.Host.search4Genotype(obj.GenotypeName);
        end

        function sn = getSeedlingName(obj)
            %% Return name for Seedling
            sn = obj.SeedlingName;
        end

        function si = getSeedlingIndex(obj)
            %% Return index of the Seedling
            sn = obj.getSeedlingName;
            aa = strfind(sn, '{');
            bb = strfind(sn, '}');
            si  = str2double(sn(aa+1:bb-1));
        end

        function showSeedling(obj, frm, fidx, fkeep, ttl)
            %% Display Seedling
            if nargin < 3; fidx  = 1;  end
            if nargin < 4; fkeep = 1;  end
            if nargin < 5; ttl   = []; end

            img           = obj.getImage(frm, 'gray');
            cntr          = obj.getContour(frm, 'Outline');
            pts           = obj.getAnchorPoints(frm);
            [ubox , lbox] = obj.MyHypocotyl.getCropBox(frm);

            if isempty(ttl)
                [~ , sttl] = obj.makeName;
                ttl        = sprintf('%s [Frame %d]', sttl, frm);
            end

            figclr(fidx, fkeep);
            myimagesc(img);
            hold on;
            plt(cntr, 'g.', 3);
            plt(pts, 'r.', 20);
            rectangle('Position', ubox, 'EdgeColor', 'b');
            rectangle('Position', lbox, 'EdgeColor', 'r');
            title(ttl, 'FontSize', 10);
            hold off;
        end

        function [fnm , ttl , dsp] = makeName(obj)
            %% makeName: create filename, figure title, and display output
            gnm  = obj.GenotypeName;
            gttl = fixtitle(gnm);
            sidx = obj.getSeedlingIndex;
            nfrm = obj.Lifetime;

            % For files names
            fnm = sprintf('%s_%s_seedling%02d_%02dframes', ...
                tdate, gnm, sidx, nfrm);

            % For figure titles
            ttl = sprintf('%s\nSeedling %d [%d Frames]', gttl, sidx, nfrm);

            % For console output
            dsp = sprintf('%s | Seedling %d | %d Frames', gnm, sidx, nfrm);
        end

        function obj = setParent(obj, gen)
            %% Set Genotype parent and Experiment host
            obj.Parent       = gen;
            obj.GenotypeName = gen.GenotypeName;

            obj.Host           = gen.Parent;
            obj.ExperimentName = obj.Host.ExperimentName;
            obj.ExperimentPath = obj.Host.ExperimentPath;
        end

        function hyp = extractHypocotyl(obj, frm, vrb)
            %% Extract Hypocotyl with defined sizes within Seedling object
            % This function crops the top [h x w] of a Seedling
            % TODO:
            % This may need to be more dynamic to account for Seedlings growing
            % at odd angles. I also need to set a detection algorithm to make
            % sure Hypocotyl is in view. Basically this should know the general
            % 'shape' of a Hypocotyl. [how do I do this?]
            %
            % (update 09.29.2018) I have no clue what I meant by the above note
            % (update 10.23.2018) I still have no clue what this means
            % (update 05.28.2021) I can't believe I haven't addressed this yet
            % (update 11.16.2021) That note is nonsense but the function works
            %
            % Input:
            %   obj  : this Seedling object
            %   frm  : frame to search for Hypocotyl
            %	vrb: verbosity
            %
            % Output:
            %   hyp  : Hypocotyl object
            %
            if nargin < 2; frm = 1; end % Verbosity
            if nargin < 3; vrb = 0; end % Verbosity

            try
                % Use this Seedling's AnchorPoints coordinates
                apts = obj.getAnchorPoints(frm);

                % Crop out and resize PreHypocotyl for use as training data
                [~, ubox , ~ , lbox] = cropFromAnchorPoints( ...
                    obj.getImage(frm, 'bw'), apts, obj.SCALESIZE);

                % Instance new Hypocotyl at frame
                sn  = obj.getSeedlingName;
                aa  = strfind(sn, '{');
                bb  = strfind(sn, '}');
                nm  = sprintf('PreHypocotyl_Sdl{%s}_Frm{%d}', ...
                    sn(aa + 1 : bb - 1), frm);
                hyp = makeNewHypocotyl(obj, nm, frm, ubox, lbox);

                % Set this Seedlings AnchorPoints and PreHypocotyl
                if isempty(obj.PreHypocotyl)
                    obj.PreHypocotyl = hyp;
                else
                    obj.PreHypocotyl(frm) = hyp;
                end

                if vrb
                    if ~sum(lbox); fprintf(2, '.'); else; fprintf('.'); end
                end

            catch
                fprintf(2, 'No data %s Frame %02d\n%s\n', ...
                    obj.getSeedlingName, frm);
            end
        end

        function obj = setImage(obj, frm, req, dat)
            %% Set type of data for Seedling at desired frame
            % Set data into requested field at specified frame
            try
                if isfield(obj.Image, req) && frm <= obj.getLifetime
                    obj.Image(frm).(req) = dat;
                elseif strcmpi(req, 'all') && frm <= obj.getLifetime
                    obj.Image(frm) = dat;
                else
                    fn  = fieldnames(obj.Image);
                    str = sprintf('%s, ', fn{:});
                    fprintf(2, 'Field must be: %s \nFrame must be <= %d\n', ...
                        str, obj.getLifetime);
                end
            catch
                fprintf(2, 'Error setting %s data at frame %d\n', req, frm);
            end
        end

        function [dat , oob , bnd] = getImage(obj, frm, req, mbuf)
            %% Return image data for Seedling at desired frame
            % User can specify which image from structure with 3rd parameter
            if nargin < 2; frm  = ':';    end
            if nargin < 3; req  = 'gray'; end
            if nargin < 4; mbuf = 0;      end

            if strcmpi(frm, ':')
                frm = obj.getFrame('b') : obj.getFrame('d');
            end

            try
                img = obj.Parent.getImage(frm, req);
                bnd = obj.getPData(frm, 'BoundingBox');

                if numel(frm) > 1
                    % Cell array
                    bnd = num2cell(bnd, 2)';
                    if mbuf
                        % Buffer bounding box
                        soff        = [-mbuf , -mbuf , mbuf*2 , mbuf];
                        [bnd , oob] = cellfun(@(b,i) bufferCropBox(b, soff, i), ...
                            bnd, img, 'UniformOutput', 0);
                    end
                    dat = cellfun(@(i,b) imcrop(i,b), ...
                        img, bnd, 'UniformOutput', 0);
                else
                    % Single image
                    if mbuf
                        % Buffer bounding box
                        soff        = [-mbuf , -mbuf , mbuf*2 , mbuf];
                        [bnd , oob] = bufferCropBox(bnd, soff, img);
                    end
                    dat = imcrop(img, bnd);
                end
            catch
                fprintf(2, 'Error returning image [%s|%s]\n', ...
                    num2str(frm), req);
                [dat , oob , bnd] = deal([]);
            end
        end

        function obj = setAutoHypocotyls(obj)
            %% Manually set a Hypocotyl child object at a given frame
            % This crops out this Seedling object's image and resizes it to the
            % desired patch size for Hypocotyl objects (see SCALESIZE property).

            % Extract and process contour from image
            imgs  = cellfun(@(x) double(imcomplement(x)), ...
                obj.getImage, 'UniformOutput', 0);
            frms = obj.getFrame;
            lt   = obj.getLifetime;

            % Set cropboxes for Hypocotyl objects
            sz   = cellfun(@(x) size(x), imgs, 'UniformOutput', 0);
            sz   = cat(1, sz{:});
            bbox = [zeros(numel(imgs), 2) , sz];

            % Set data for Hypocotyl object and Stem
            hyp = Hypocotyl('Parent', obj, 'Host', obj.Host, 'Frame', frms, ...
                'Lifetime', lt, 'HypocotylName', 'Hypocotyl_{1}', 'CropBox', bbox);
            hyp.ExperimentName = obj.ExperimentName;
            hyp.ExperimentPath = obj.ExperimentPath;
            hyp.GenotypeName   = obj.GenotypeName;
            hyp.SeedlingName   = obj.SeedlingName;
            obj.MyHypocotyl    = hyp;
        end

        function obj = setCoordinates(obj, frm, coords)
            %% Set coordinates of a Seedling at a specific frame
            % This method allows setting the xy-coordinates of a Seedling at
            % the given time point. Coordinates come from the WeightedCentroid
            % of the Seedling in a full image.
            try
                if iscell(frm)
                    % Set coordinates from a cell array of frames
                    cellfun(@(f,c) obj.setCoordinates(f,c), ...
                        frm, coords, 'UniformOutput', 0);
                else
                    % Set coordinates for a single frame
                    obj.Coordinates(frm, :) = coords;
                end
            catch
                fprintf('No coordinate found at frame %d \n', frm);
            end
        end

        function coords = getCoordinates(obj, frm)
            %% Returns coordinates at specified frame
            % Make sure to check for nan (no coordinate found at frame)
            if nargin < 2; frm = ':'; end

            try
                coords = obj.Coordinates(frm, :);
            catch
                fprintf('No coordinate found at frame %d \n', frm);
                coords = [nan , nan];
            end
        end

        function obj = setFrame(obj, frm, req)
            %% Set birth or death Frame number for Seedling
            switch req
                case 'b'; obj.Frame(1) = frm;
                case 'd'; obj.Frame(2) = frm;
                otherwise
                    fprintf(2, 'Error: input must be ''b'' or ''d''\n');
                    return;
            end
        end

        function frm = getFrame(obj, req)
            %% Return birth or death Frame number for Seedling
            if nargin < 2; req = 'a'; end

            switch req
                case 'b'; frm = obj.Frame(1);
                case 'd'; frm = obj.Frame(2);
                case 'a'; frm = obj.Frame;
                otherwise
                    fprintf(2, 'Error: input must be ''b'' or ''d''\n');
                    frm = [];
                    return;
            end
        end

        function toggleStatus(obj, st)
            %% Toggle or set Status to Show or Hide
            if nargin < 2; st = []; end

            if isempty(st)
                % Toggle from current
                if obj.Status
                    obj.Status = 0;
                else
                    obj.Status = 1;
                end
            else
                % Set to any status
                obj.Status = st;
            end
        end

        function FixAnchorPoints(obj, frm, hypln, bopen)
            %% FixAnchorPoints: fix AnchorPoints from poorly segmented frames
            % Re-do seedling segmentation to fix hypocotyl crop boxes
            % bw image --> re-do segment --> set AnchorPoints --> make CropBox
            if nargin < 2; frm   = 1 : obj.Lifetime;                        end
            if nargin < 4; bopen = obj.Parent.getProperty('BOPEN');         end
            if nargin < 3; hypln = obj.Host.getProperty('HYPOCOTYLLENGTH'); end

            bw = obj.getImage(frm, 'bw');

            if iscell(bw)
                bw  = cellfun(@(x) bwareaopen(x, bopen), ...
                    bw, 'UniformOutput', 0);
                pts = cellfun(@(x) bwAnchorPoints(x, hypln, obj.HYPBUFFER), ...
                    bw, 'UniformOutput', 0);
                pts = cat(3, pts{:});
            else
                bw  = bwareaopen(bw, bopen);
                pts = bwAnchorPoints(bw, hypln, obj.HYPBUFFER);
            end

            obj.setAnchorPoints(frm, pts);
        end

        function increaseLifetime(varargin)
            %% Increase Lifetime of Seedling by desired amount
            narginchk(1,2);
            obj = varargin{1};
            switch nargin
                case 1
                    obj.Lifetime = obj.Lifetime + 1;
                case 2
                    inc          = varargin{2};
                    obj.Lifetime = obj.Lifetime + inc;
                otherwise
                    fprintf(2, 'Error incrementing lifetime\n');
                    return;
            end
        end

        function lt = getLifetime(obj)
            %% Return Lifetime of Seedling
            lt = obj.Lifetime;
        end

        function obj = setPData(obj, frm, pd)
            %% Set extra properties data for Seedling at given frame
            % If first frame, then initialize struct with given fieldnames
            try
                if iscell(frm)
                    % Set PData for a cell array
                    cellfun(@(f,p) obj.setPData(f,p), ...
                        frm, pd, 'UniformOutput', 0);
                else
                    % Set PData for single frame
                    obj.PData(frm) = pd;
                end
            catch
                fprintf(2, 'No PData at index %d \n', frm);
            end
        end

        function [bbox , oob] = getCropBox(obj, frm, mbuf)
            %% Get crop box from a frame
            if nargin < 2; frm  = 1 : obj.Lifetime; end
            if nargin < 3; mbuf = 0;                end

            bbox = obj.getPData(frm, 'BoundingBox');
            if mbuf
                img          = obj.Parent.getImage(frm);
                soff         = [-mbuf , -mbuf , mbuf*2 , mbuf];
                [bbox , oob] = bufferCropBox(bbox, soff, img);
            end
        end

        function pd = getPData(obj, frm, req)
            %% Return property data at specific frame(s)
            % There must be a more eloquent way to code this, but hey it works
            if nargin < 2; frm = 1 : obj.Lifetime; end
            if nargin < 3; req = [];               end

            try
                if ischar(frm) && ~strcmpi(frm, ':')
                    % First argument is a field, return all frames
                    pd = arrayfun(@(x) x.(frm), obj.PData, 'UniformOutput', 0)';
                    pd = cat(1, pd{:});
                elseif ~isempty(req)
                    % Return specific field
                    if numel(frm) > 1 || strcmpi(frm, ':')
                        % Single field for multiple or all frames
                        pd = arrayfun(@(x) x.(req), ...
                            obj.PData(frm), 'UniformOutput', 0)';
                        pd = cat(1, pd{:});
                    else
                        % Single field at a frame
                        pd = obj.PData(frm).(req);
                    end
                else
                    % Full structure at one or more frames
                    pd = obj.PData(frm);
                end
            catch
                fprintf('Error returning frame %d for field %s\n', frm, req);
                pd = [];
                return;
            end
        end

        function obj = setAnchorPoints(obj, frm, pts)
            %% Returns 4x2 array of 4 anchor points representing Hypocotyl
            try
                obj.AnchorPoints(:, :, frm) = pts;
            catch
                fprintf(2, 'No AnchorPoints at index %s \n', frm);
            end
        end

        function pts = getAnchorPoints(obj, frm)
            %% Returns 4x2 array of 4 anchor points representing Hypocotyl
            if nargin < 2; frm = ':'; end

            try
                pts = obj.AnchorPoints(:, :, frm);
            catch
                fprintf(2, 'No data at index %d \n', frm);
                pts = [];
            end
        end

        function frms = getGoodFrames(obj)
            %% Return index of frames that pass all quality checks
            if ~isempty(obj.GoodFrames)
                frms = obj.GoodFrames;
            else
                fprintf('GoodFrames index is empty. Run RemoveBadFrames.\n');
            end
        end

        function obj = setContour(obj, frm, crc)
            %% Set manually-drawn CircuitJB object at given frame
            if isempty(obj.Contour); obj.Contour = ContourJB; end

            obj.Contour(frm) = crc;
        end

        function crc = getContour(obj, frm, req)
            %% Return CircuitJB object at given frame
            if nargin < 2; frm = ':'; end
            if nargin < 3; req = [];  end

            try
                crc = obj.Contour(frm);
                if ~isempty(req); crc = crc.(req); end
            catch
                fprintf(2, 'Property %s not found in ContourJB\n', req);
                crc = [];
            end
        end

        function hyps = getAllPreHypocotyls(obj)
            %% Returns all PreHypocotyls
            hyps = obj.PreHypocotyl;
        end

        function hyp = getPreHypocotyl(obj, frm)
            %% Return PreHypocotyl from frame
            try
                hyp = obj.PreHypocotyl(frm);
            catch
                fprintf(2, 'No PreHypocotyl at index %d \n', frm);
            end
        end

        function sclsz = getScaleSize(obj)
            %% Return image rescale dimensions
            sclsz = obj.SCALESIZE;
        end

        function [ubox , lbox] = setHypocotylCropBox(obj, frms)
            %% Set CropBox for upper and lower region
            if nargin < 2; frms = 1 : obj.getLifetime; end

            h    = obj.MyHypocotyl;
            apts = obj.getAnchorPoints(frms);
            imgs = obj.getImage(frms);
            try
                % Set for single or multiple frames
                if ~ismatrix(apts)
                    % Convert to cell arrays
                    %                     imgs = {imgs};
                    apts = arrayfun(@(x) apts(:,:,x), ...
                        1 : size(apts,3), 'UniformOutput', 0);
                    [~ , ubox , ~ , lbox] = cellfun(@(img,apt) ...
                        cropFromAnchorPoints(img, apt, obj.SCALESIZE), ...
                        imgs, apts, 'UniformOutput', 0);
                    ubox = cat(1, ubox{:});
                    lbox = cat(1, lbox{:});
                else
                    [~ , ubox , ~ , lbox] = cropFromAnchorPoints( ...
                        imgs, apts, obj.SCALESIZE);
                end

                % Set CropBoxes
                h.setCropBox(frms, ubox, 'upper');
                h.setCropBox(frms, lbox, 'lower');

                % Set PData

            catch
                fprintf(2, 'Error setting CropBox');
                [ubox , lbox] = deal([0 , 0 , 0 , 0]);
            end
        end

        function setHypocotylLength(obj, frms, hypln)
            %% Set cut-off length for upper hypocotyl region
        end

        function setProperty(obj, req, val)
            %% Returns a property of this Genotype object
            try
                obj.(req) = val;
            catch e
                fprintf(2, 'Property %s does not exist\n%s\n', ...
                    req, e.message);
            end
        end

        function prp = getProperty(obj, req)
            %% Returns a property of this Seedling object
            try
                prp = obj.(req);
            catch e
                fprintf(2, 'Property %s does not exist\n%s\n', ...
                    req, e.message);
            end
        end
    end

    %% ------------------------- Private Methods --------------------------- %%
    methods (Access = private)
        %% Private helper methods
        function h = makeNewHypocotyl(obj, nm, frm, tbox, lbox)
            %% Set data into new Hypocotyl
            % Input:
            %   nm: name for new Hypocotyl
            %   frm: Hypocotyl's birth frame
            %   tbox: coordinates to crop upper region from parent image
            %   lbox: coordinates to crop lower region from parent image
            %
            % Output:
            %   h: new Hypocotyl object

            h = Hypocotyl('HypocotylName', nm);
            h.setParent(obj);
            h.setFrame('b', frm);
            h.setCropBox(1, tbox, 'upper');
            h.setCropBox(1, lbox, 'lower');
        end

        function hyp = compileHypocotyl(obj, hyp, pre)
            %% Compile data from multiple PreHypocotyl objects
            % Input:
            %     obj: this Seedling object
            %     hyp: Hypocotyl object
            %     pre: multiple PreHypocotyl objects to draw data from
            %
            % Ouput:
            %     hyp: Hypocotyl object after cleaning up data

            %% [TODO] Change Hypocotyl methods to include Frame number
            for frm = 1 : numel(pre)
                hyp.setCropBox(frm, pre(frm).getCropBox(1, 'upper'), 'upper');
                hyp.setCropBox(frm, pre(frm).getCropBox(1, 'lower'), 'lower');
                %                 hyp.setCropBox(frm, pre(frm).getCropBox(':'));
                %                 hyp.setContour(frm, pre(frm).getContour(':'));
            end
        end
    end
end
