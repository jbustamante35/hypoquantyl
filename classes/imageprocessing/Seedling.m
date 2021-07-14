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
        SCALESIZE    = [101 , 101]
        %         PDPROPERTIES = {'Area', 'BoundingBox', 'PixelList', 'Centroid', 'WeightedCentroid', 'Orientation'};
        PDPROPERTIES = {'Area', 'BoundingBox', 'PixelList', 'WeightedCentroid', 'Orientation'};
        CONTOURSIZE  = 500		% number of points to normalize Hypocotyl contours
        IMAGEBUFFER  = 40		% percentage of image size to extend image for creating Hypocotyl objects
        TESTS2RUN    = [1 1 1 1 0 0];	% manifest to determine which quality checks to run
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
            
            obj.Image = struct('gray', [], ...
                'bw',   [], ...
                'ctr', ContourJB);
            
        end
        
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
            good_frames    = runQualityChecks(obj, obj.TESTS2RUN);
            obj.Lifetime   = numel(good_frames);
            obj.setFrame(min(good_frames), 'b');
            obj.setFrame(max(good_frames), 'd');
            obj.GoodFrames = good_frames;
        end
        
        function hyp = FindHypocotylAllFrames(obj, v)
            %% Extract Hypocotyl at all frames using the extractHypocotyl
            % method for this Seedling's total Lifetime
            
            try
                if v
                    fprintf('Extracting Hypocotyls from %s\n', ...
                        obj.SeedlingName);
                    tic;
                end
                
                rng = 1 : obj.Lifetime;
                hyp = arrayfun(@(x) obj.extractHypocotyl(x, v), ...
                    rng, 'UniformOutput', 0);
                
                if v
                    fprintf('[%.02f sec] Extracted Hypocotyl from %s\n', ...
                        toc, obj.SeedlingName);
                end
                
            catch e
                fprintf(2, 'Error extracting Hypocotyl from %s\n%s', ...
                    obj.SeedlingName, e.getReport);
                
                if v
                    fprintf('[%.02f sec]\n', toc);
                end
            end
        end
        
        function obj = PruneHypocotyls(obj)
            %% Remove PreHypocotyls to decrease data
            obj.PreHypocotyl = [];
            %h = obj.getProperty('PreHypocotyl');
            %h = [];
            
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
            rng = [pre(1).getFrame('b') pre(end).getFrame('b')];
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
            arrayfun(@(x) x.setParent(obj), obj.PreHypocotyl, 'UniformOutput', 0);
            %arrayfun(@(x) x.setParent(obj), obj.Hypocotyls, 'UniformOutput', 0);
            
        end
        
    end
    
    %% ------------------------- Helper Methods ---------------------------- %%
    
    methods (Access = public) %% Various methods for this class
        function obj = setSeedlingName(obj, sn)
            %% Set name for Seedling
            %             obj.SeedlingName = string(sn);
            obj.SeedlingName = char(sn);
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
            % (update 9/29/18) I have no clue what I meant by the above note
            % (update 10/23/18) I still have no clue what this means
            % (update 05/28/21) I can't believe I haven't addressed this yet
            %
            % Input:
            %   obj  : this Seedling object
            %   frm  : frame to search for Hypocotyl
            %	vrb: verbosity
            %
            % Output:
            %   hyp  : Hypocotyl object
            %
            
            try
                % Use this Seedling's AnchorPoints coordinates
                apts = obj.getAnchorPoints(frm);
                
                % Crop out and resize PreHypocotyl for use as training data
                [~, tbox , ~ , lbox] = cropFromAnchorPoints( ...
                    obj.getImage(frm, 'bw'), apts, obj.SCALESIZE);
                
                % Instance new Hypocotyl at frame
                sn  = obj.getSeedlingName;
                aa  = strfind(sn, '{');
                bb  = strfind(sn, '}');
                nm  = sprintf('PreHypocotyl_Sdl{%s}_Frm{%d}', ...
                    sn(aa + 1 : bb - 1), frm);
                hyp = makeNewHypocotyl(obj, nm, frm, tbox, lbox);
                
                % Set this Seedlings AnchorPoints and PreHypocotyl
                if isempty(obj.PreHypocotyl)
                    obj.PreHypocotyl = hyp;
                else
                    obj.PreHypocotyl(frm) = hyp;
                end
                
                if vrb
                    fprintf('Extracted hypocotyl from %s frame %d\n', ...
                        obj.SeedlingName, frm);
                end
                
            catch e
                fprintf(2, 'No data %s Frame %d \n%s\n', ...
                    obj.getSeedlingName, frm, e.getReport);
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
        
        function dat = getImage(varargin)
            %% Return image data for Seedling at desired frame
            % User can specify which image from structure with 3rd parameter
            obj = varargin{1};
            rng = obj.getFrame('b') : obj.getFrame('d');
            
            switch nargin
                case 1
                    % All grayscale images at all frames
                    try
                        img = obj.Parent.getImage(rng);
                        bnd = obj.getPData(rng, 'BoundingBox');
                        bnd = num2cell(bnd,2)';
                        dat = cellfun(@(i,b) imcrop(i,b), ...
                            img, bnd, 'UniformOutput', 0);
                    catch
                        fprintf(2, 'Error returning Image\n');
                        dat = [];
                    end
                    
                case 2
                    % Grayscale image(s) at specific frame or range of frames
                    % Convert requested index to index in this object's lifetime
                    try
                        frm = varargin{2};
                        if numel(rng) > 1
                            idx = rng(frm);
                        else
                            idx = rng;
                        end
                        
                        img = obj.Parent.getImage(idx);
                        
                        if ~iscell(img)
                            bnd = obj.getPData(frm, 'BoundingBox');
                            dat = imcrop(img, bnd);
                        else
                            bnd = arrayfun(@(x) obj.getPData(x, ...
                                'BoundingBox'), idx, 'UniformOutput', 0);
                            dat = cellfun(@(i,b) imcrop(i,b), ...
                                img, bnd, 'UniformOutput', 0);
                        end
                        
                    catch
                        fprintf(2, 'No image at frame %d indexed at %d \n', ...
                            frm, idx);
                        dat = [];
                    end
                    
                case 3
                    % Grayscale or bw image(s) at single or range of frames
                    try
                        frm = varargin{2};
                        req = varargin{3};
                        if numel(rng) > 1
                            idx = rng(frm);
                        else
                            idx = obj.getFrame('b');
                        end
                        
                        if numel(idx) > 1
                            img = obj.Parent.getImage(idx, req);
                            bnd = num2cell(...
                                obj.getPData(frm, 'BoundingBox'), 2)';
                            dat = cellfun(@(i,b) imcrop(i,b), ...
                                img, bnd, 'UniformOutput', 0);
                        else
                            img = obj.Parent.getImage(idx, req);
                            bnd = obj.getPData(frm, 'BoundingBox');
                            dat = imcrop(img, bnd);
                        end
                    catch
                        fprintf(2, ...
                            'No %s image at frame %d indexed at %d \n', ...
                            char(req), frm, idx);
                        dat = [];
                    end
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
            try
                if nargin < 2
                    frm = ':';
                end
                
                coords = obj.Coordinates(frm, :);
            catch
                fprintf('No coordinate found at frame %d \n', frm);
                coords = [nan , nan];
            end
        end
        
        function obj = setFrame(obj, frm, req)
            %% Set birth or death Frame number for Seedling
            switch req
                case 'b'
                    obj.Frame(1) = frm;
                    
                case 'd'
                    obj.Frame(2) = frm;
                    
                otherwise
                    fprintf(2, 'Error: input must be ''b'' or ''d''\n');
                    return;
            end
        end
        
        function frm = getFrame(obj, req)
            %% Return birth or death Frame number for Seedling
            if nargin < 2
                req = 'a';
            end
            
            try
                switch req
                    case 'b'
                        frm = obj.Frame(1);
                    case 'd'
                        frm = obj.Frame(2);
                    case 'a'
                        frm = obj.Frame;
                    otherwise
                        fprintf(2, 'Error: input must be ''b'' or ''d''\n');
                        frm = [];
                        return;
                end
            catch
                fprintf(2, 'Error: input must be ''b'' or ''d''\n');
                frm = [];
                return;
            end
        end
        
        function increaseLifetime(varargin)
            %% Increase Lifetime of Seedling by desired amount
            narginchk(1,2);
            obj = varargin{1};
            switch nargin
                case 1
                    obj.Lifetime = obj.Lifetime + 1;
                    
                case 2
                    inc = varargin{2};
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
        
        function pd = getPData(varargin)
            %% Return extra properties data at given frame
            % User can specify which image from structure with 3rd parameter
            obj = varargin{1};
            switch nargin
                case 1
                    % Full structure of data at all frames
                    pd = obj.PData;
                    
                case 2
                    % All data at given frame
                    try
                        frm = varargin{2};
                        pd  = obj.PData(frm);
                    catch
                        fprintf(2, 'No pdata at frame %d \n', frm);
                        pd = [];
                    end
                    
                case 3
                    % Specific data property at given frame
                    % Check if frame exists
                    try
                        frm = varargin{2};
                        req = varargin{3};
                        pd  = obj.PData(frm);
                    catch
                        fprintf(2, 'No pdata at frame %d \n', frm);
                    end
                    
                    % Get requested data field
                    try
                        dfm = obj.PData(frm);
                        pd  = cat(1, obj.PData(frm).(req));
                    catch
                        fn  = fieldnames(dfm);
                        str = sprintf('%s, ', fn{:});
                        fprintf(2, 'Requested field must be: %s\n', str);
                    end
                    
                otherwise
                    fprintf(2, 'Error requesting data.\n');
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
            if nargin < 2
                frm = ':';
            end
            
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
            if isempty(obj.Contour)
                obj.Contour = ContourJB;
            end
            
            obj.Contour(frm) = crc;
        end
        
        function crc = getContour(obj, frm)
            %% Return CircuitJB object at given frame
            if nargin < 2
                frm = ':';
            end
            
            crc = obj.Contour(frm);
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
        
        function [tbox , lbox] = setHypocotylCropBox(obj, frms, v)
            %% Set CropBox for upper and lower region
            switch nargin
                case 1
                    frms = 1 : obj.getLifetime;
                    v    = 0;
                case 2
                    v = 0;
            end
            
            h    = obj.MyHypocotyl;
            apts = obj.getAnchorPoints(frms);
            imgs = obj.getImage(frms);
            
            try
                % Set for single or multiple frames
                if ~ismatrix(apts)
                    % Convert to cell arrays
                    imgs = {imgs};
                    apts = arrayfun(@(x) apts(:,:,x), ...
                        1 : size(apts,3), 'UniformOutput', 0);
                    [~ , tbox , ~ , lbox] = cellfun(@(img,apt) ...
                        cropFromAnchorPoints(img, apt, obj.SCALESIZE), ...
                        imgs, apts, 'UniformOutput', 0);
                    tbox = cat(1, tbox{:});
                    lbox = cat(1, lbox{:});
                else
                    [~ , tbox , ~ , lbox] = cropFromAnchorPoints( ...
                        imgs, apts, obj.SCALESIZE);
                end
                % Set CropBoxes
                h.setCropBox(frms, tbox, 'upper');
                h.setCropBox(frms, lbox, 'lower');
            catch
                fprintf(2, 'Error setting CropBox');
                [tbox , lbox] = deal([0 , 0 , 0 , 0]);
            end
        end
        
        function setHypocotylLength(obj, frms, hypln)
            %% Set cut-off length for upper hypocotyl region
            
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
                hyp.setCropBox(frm, pre(frm).getCropBox(':'));
                hyp.setContour(frm, pre(frm).getContour(':'));
            end
            
        end
        
    end
    
end
