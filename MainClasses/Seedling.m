%% Seedling: class containing an individual seedling from a Genotype image stack
% Class description

classdef Seedling < handle
    properties (Access = public)
        %% Seedling properties
        ExperimentName
        ExperimentPath
        GenotypeName
        SeedlingName
        Frame = zeros(1,2);
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
        PDPROPERTIES = {'Area', 'BoundingBox', 'PixelList', 'WeightedCentroid', 'Orientation'};
        CONTOURSIZE = 500 % number of points to normalize Hypocotyl contours
        TESTS2RUN = [1 1 1 1 0 0]; % manifest to determine which quality checks to run
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
                obj.SeedlingName = '';
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
        
        function obj = FindHypocotyl(obj, frm, crpsz)
            %% Find Hypocotyl with defined sizes within Seedling object
            % This function crops the top [h x w] of a Seedling
            % This may need to be more dynamic to account for Seedlings growing add odd angles.
            % I also need to set a detection algorithm to make sure Hypocotyl is in view.
            % Basically this should know the general 'shape' of a Hypocotyl. [how do I do this?]
            %
            % Input:
            %   obj  : this Seedling object
            %   frm  : frame in which to search for Hypocotyl
            %   crpsz: [2 x 1] array defining the scaled size of each Hypocotyl
            %
            % Output:
            %   obj  : function sets AnchorPoints and PreHypocotyl
            
            try
                % Use this Seedling's AnchorPoints coordinates
                ap = obj.getAnchorPoints(frm);
                
                % Crop out and resize PreHypocotyl for use as training data
                % Store grayscale, bw, and contour in Hypocotyl object
                gry = cropFromAnchorPoints(obj.getImage(frm, 'gray'), ap, crpsz);
                msk = cropFromAnchorPoints(obj.getImage(frm, 'bw'),   ap, crpsz);
                ctr = extractContour(msk, obj.CONTOURSIZE);
                
                % Instance new Hypocotyl at frame
                sn = obj.getSeedlingName;
                aa = strfind(sn, '{');
                bb = strfind(sn, '}');
                nm = sprintf('PreHypocotyl_{%s}^{%d}', sn(aa+1:bb-1), frm);
                hyp = makeNewHypocotyl(obj, nm, frm, gry, msk, ctr);
                
                % Set this Seedlings AnchorPoints and PreHypocotyl
                obj.PreHypocotyl(frm) = hyp;
                
            catch
                fprintf('No data %s Frame %d \n', obj.getSeedlingName, frm);
            end
        end
        
    end
    
    %% ------------------------- Helper Methods ---------------------------- %%
    
    methods (Access = public)
        %% Various methods for this class
        function obj = setSeedlingName(obj, sn)
            %% Set name for Seedling
            obj.SeedlingName = string(sn);
        end
        
        function sn = getSeedlingName(obj)
            %% Return name for Seedling
            sn = obj.SeedlingName;
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
                    fprintf(2, 'Field must be: %s \nFrame must be <= %d\n', str, obj.getLifetime);
                end
            catch
                fprintf(2, 'Error setting %s data at frame %d\n', req, frm);
            end
        end
        
        function dat = getImage(varargin)
            %% Return data for Seedling at desired frame
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
        
        function obj = setCoordinates(obj, frm, coords)
            %% Set coordinates of a Seedling at a specific frame
            % This method allows setting the xy-coordinates of a Seedling at given time point
            % Coordinates come from the WeightedCentroid of the Seedling in a full image
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
            switch nargin
                case 1
                    % Full structure of data at all frames
                    obj = varargin{1};
                    pd  = obj.PData;
                    
                case 2
                    % All data at given frame
                    try
                        obj = varargin{1};
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
                        obj = varargin{1};
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
                        pd = dfm.(req);
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
                fprintf('GoodFrames index is empty. Run RemoveBadFrames to find index.\n');
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
                fprintf(2, 'No PreHypocotyl at index %s \n', frm);
            end
        end
        
        
    end
    
    %% ------------------------- Private Methods --------------------------- %%    
    methods (Access = private)
        %% Private helper methods
        function args = parseConstructorInput(varargin)
            %% Parse input parameters for Constructor method
            p = inputParser;
            p.addRequired('SeedlingName');
            p.addOptional('ExperimentName', '');
            p.addOptional('ExperimentPath', '');
            p.addOptional('GenotypeName', '');
            p.addOptional('Frame', zeros(1,2));
            p.addOptional('Lifetime', 0);
            p.addOptional('Coordinates', []);
            p.addOptional('Image', struct());
            p.addOptional('PData', struct());
            p.addOptional('Midline', []);
            p.addOptional('AnchorPoints', zeros(4,2,1));
            p.addOptional('GoodFrames', []);
            p.addOptional('PreHypocotyl', Hypocotyl);
            p.addOptional('Contour', CircuitJB);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
        function h = makeNewHypocotyl(obj, nm, frm, img, msk, ctr)
            %% Set data into new Hypocotyl
            % Input:
            %   nm: name for new Hypocotyl
            %   frm: birth frame to set
            %   img: grayscale image
            %   msk: bw image
            %   ctr: ContourJB object
            %
            % Output:
            %   h: new Hypocotyl object set with inputted data
            h = Hypocotyl(nm, ...
                'ExperimentName', obj.ExperimentName, ...
                'ExperimentPath', obj.ExperimentPath, ...
                'GenotypeName',   obj.GenotypeName, ...
                'SeedlingName',   obj.SeedlingName);
            
            h.setFrame('b', frm);
            h.setImage('gray', img);
            h.setImage('bw', msk);
            h.setImage('ctr', ctr);
        end
        
    end
    
end
