%% Seedling: class containing an individual seedling from a Genotype image stack
% Class description

classdef Seedling < handle
    properties (Access = public)
        %% Seedling properties
        SeedlingName
        GenotypeName
        ExperimentName
        ExperimentPath
        Parent
        Host
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
        SCALESIZE    = [101 101]
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
                args = obj.parseConstructorInput(varargin);
                
                fn = fieldnames(args);
                for k = fn'
                    obj.(cell2mat(k)) = args.(cell2mat(k));
                end
                
            else
                % Set default properties for empty object
            end
            
            if ~isfield(obj.PData, obj.PDPROPERTIES{1})
                c = cell(1, numel(obj.PDPROPERTIES));
                obj.PData = cell2struct(c', obj.PDPROPERTIES);
            end
            
            obj.Image = struct('gray', [], ...
                'bw',   [], ...
                'ctr', ContourJB);
            
        end
        
        function obj = RemoveBadFrames(obj)
            %% Remove frames with empty data and maintain index of good frames
            % Run through multiple tests to determine good indices
            % This function removes poor frames and stores good frames in gdIdx
            % Current tests:
            %   1) Empty coordinates
            %   2) Empty PData
            %   3) Empty image and contour data
            %   4) Empty AnchorPoints
            %   5) Out of frame growth
            %   6) Collisions
            
            %% REMOVE THIS AFTER FINISHING METHOD
            obj.TESTS2RUN = [1 1 1 1 0 0];
            
            %% Get index of good frames, then remove bad frames
            obj.GoodFrames = runQualityChecks(obj, obj.TESTS2RUN);
            obj.Lifetime   = numel(obj.GoodFrames);
            obj.setFrame(min(obj.GoodFrames), 'b');
            obj.setFrame(max(obj.GoodFrames), 'd');
        end
        
        function obj = FindHypocotylAllFrames(obj)
	    %% Extract Hypocotyl at all frames using the extractHypocotyl
            % method for this Seedling's total Lifetime

            try
            	rng = 1 : obj.Lifetime;
            	arrayfun(@(x) obj.extractHypocotyl(x), ...
                	rng, 'UniformOutput', 0);
            catch e
            	fprintf(2, 'Error extracting Hypocotyl from %s\n%s', ...
                	obj.SeedlingName, e.getReport);
            end
        end
        
    end
    
    %% ------------------------- Helper Methods ---------------------------- %%
    
    methods (Access = public) %% Various methods for this class
        function obj = setSeedlingName(obj, sn)
            %% Set name for Seedling
            obj.SeedlingName = string(sn);
        end
        
        function sn = getSeedlingName(obj)
            %% Return name for Seedling
            sn = obj.SeedlingName;
        end
        
        function obj = setParent(obj, p)
            %% Set Genotype parent and Experiment host
            obj.Parent       = p;
            obj.GenotypeName = p.GenotypeName;
            
            obj.Host           = p.Parent;
            obj.ExperimentName = obj.Host.ExperimentName;
            obj.ExperimentPath = obj.Host.ExperimentPath;
        end
        
        function obj = extractHypocotyl(obj, frm)
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
            %
            % Input:
            %   obj  : this Seedling object
            %   frm  : frame in which to search for Hypocotyl
            %   sclsz: [2 x 1] array defining the scaled size of each Hypocotyl
            %
            % Output:
            %   obj  : function sets AnchorPoints and PreHypocotyl
            %
            
            try
                % Use this Seedling's AnchorPoints coordinates
                ap = obj.getAnchorPoints(frm);
                
                % Crop out and resize PreHypocotyl for use as training data
                % Store grayscale, bw, and contour in Hypocotyl object
                [msk, bbox] = cropFromAnchorPoints(obj.getImage(frm, 'bw'),...
                	ap, obj.SCALESIZE);
                ctr         = extractContour(imcomplement(msk), ...
                	obj.CONTOURSIZE);
                
                % Instance new Hypocotyl at frame
                sn  = obj.getSeedlingName;
                aa  = strfind(sn, '{');
                bb  = strfind(sn, '}');
                nm  = sprintf('PreHypocotyl_Sdl{%s}_Frm{%d}', ...
                	sn(aa+1:bb-1), frm);
                hyp = makeNewHypocotyl(obj, nm, frm, ctr, bbox);
                
                % Set this Seedlings AnchorPoints and PreHypocotyl
                if isempty(obj.PreHypocotyl)
                    obj.PreHypocotyl = hyp;
                else
                    obj.PreHypocotyl(frm) = hyp;
                end
                
            catch e
                fprintf('No data %s Frame %d \n%s\n', ...
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
                        bnd = obj.getPData(1, 'BoundingBox');
                        dat = imcrop(img, bnd);
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
                        if numel(rng) > 1
                            idx = rng(frm);
                        else
                            idx = obj.getFrame('b');
                        end
                        
                        req = varargin{3};
                        img = obj.Parent.getImage(idx, req);
                        bnd = obj.getPData(frm, 'BoundingBox');
                        dat = imcrop(img, bnd);
                    catch
                        fprintf(2, ...
                        	'No %s image at frame %d indexed at %d \n', ...
                                req, frm, idx);
                        dat = [];
                    end
            end
            
        end
        
        function obj = setCoordinates(obj, frm, coords)
            %% Set coordinates of a Seedling at a specific frame
            % This method allows setting the xy-coordinates of a Seedling at 
            % the given time point. Coordinates come from the WeightedCentroid 
            % of the Seedling in a full image.
            try
                obj.Coordinates(frm, :) = coords;
            catch
                fprintf('No coordinate found at frame %d \n', frm);
            end
        end
        
        function coords = getCoordinates(obj, frm)
            %% Returns coordinates at specified frame
            % Make sure to check for nan (no coordinate found at frame)
            try
                coords = obj.Coordinates(frm, :);
            catch
                fprintf('No coordinate found at frame %d \n', frm);
                %                 coords = [nan nan];
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
            try
                switch req
                    case 'b'
                        frm = obj.Frame(1);
                    case 'd'
                        frm = obj.Frame(2);
                    otherwise
                        fprintf(2, 'Error: input must be ''b'' or ''d''\n');
                        return;
                end
            catch
                frm = obj.Frame;
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
                obj.PData(frm) = pd;
            catch
                fprintf(2, 'No pdata at index %d \n', frm);
            end
        end
        
        function pd = getPData(varargin)
            %% Return extra properties data at given frame
            % User can specify which image from structure with 3rd parameter
            obj = varargin{1};
            switch nargin
                case 1
                    % Full structure of data at all frames
                    pd  = obj.PData;
                    
                case 2
                    % All data at given frame
                    try
                        frm = varargin{2};
                        pd  = obj.PData(frm);
                    catch e
                        fprintf(2, 'No pdata at frame %d \n', frm);
                        fprintf(2, '%s\n', e.getReport);
                    end
                    
                case 3
                    % Specific data property at given frame
                    % Check if frame exists
                    try
                        frm = varargin{2};
                        req = varargin{3};
                        pd  = obj.PData(frm);
                    catch e
                        fprintf(2, 'No pdata at frame %d \n', frm);
                        fprintf(2, '%s\n', e.getReport);
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
                    return;
            end
            
        end
        
        function pts = setAnchorPoints(obj, frm, pts)
            %% Returns 4x2 array of 4 anchor points representing Hypocotyl
            try
                obj.AnchorPoints(:, :, frm) = pts;
            catch
                fprintf(2, 'No AnchorPoints at index %s \n', frm);
            end
        end
        
        function pts = getAnchorPoints(obj, frm)
            %% Returns 4x2 array of 4 anchor points representing Hypocotyl
            try
                pts = obj.AnchorPoints(:, :, frm);
            catch
                fprintf(2, 'No data at index %s \n', frm);
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
            obj.Contour(frm) = crc;
        end
        
        function crc = getContour(obj, frm)
            %% Return CircuitJB object at given frame
            crc = obj.Contour(frm);
        end
        
        function hyps = getAllPreHypocotyls(obj)
            %% Returns all PreHypocotyls
            hyps = obj.PreHypocotyl;
        end
        
        function hyp = getPreHypocotyl(obj, frm)
            %% Return PreHypocotyl at desired frame
            try
                hyp = obj.PreHypocotyl(frm);
            catch
                fprintf(2, 'No PreHypocotyl at index %d \n', frm);
            end
        end
        
        function sclsz = getScaleSize(obj)
            sclsz = obj.SCALESIZE;
        end

    end
    
    %% ------------------------- Private Methods --------------------------- %%
    methods (Access = private)
        %% Private helper methods
        function args = parseConstructorInput(varargin)
            %% Parse input parameters for Constructor method
            % Parent is Genotype object
            % Host is Experiment object
            p = inputParser;
            p.addRequired('SeedlingName');
            p.addOptional('Parent', []);
            p.addOptional('GenotypeName', '');
            p.addOptional('Host', []);
            p.addOptional('ExperimentName', '');
            p.addOptional('ExperimentPath', '');
            p.addOptional('Frame', zeros(1,2));
            p.addOptional('Lifetime', 0);
            p.addOptional('Coordinates', []);
            p.addOptional('Image', struct());
            p.addOptional('PData', struct());
            p.addOptional('Midline', []);
            p.addOptional('AnchorPoints', zeros(4,2,1));
            p.addOptional('GoodFrames', []);
            p.addOptional('PreHypocotyl', []);
            p.addOptional('Contour', ContourJB);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
        function h = makeNewHypocotyl(obj, nm, frm, ctr, bbox)
            %% Set data into new Hypocotyl
            % Input:
            %   nm: name for new Hypocotyl
            %   frm: birth frame to set
            %   ctr: ContourJB object
            %   bbox: coordinates for bounding box to crop from parent image
            %
            % Output:
            %   h: new Hypocotyl object set with inputted data
            h = Hypocotyl(nm);
            h.setParent(obj);
            h.setFrame('b', frm);
            h.setContour(frm, ctr);
            h.setCropBox(bbox);
        end
        
    end
    
end
