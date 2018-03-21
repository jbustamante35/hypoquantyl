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
        Data
        PData
        MyHypocotyl
    end
    
    properties (Access = private)
        %% Private data
        Midline
        AnchorPoints
        HypIdx
        PreHypocotyl
        gray
        bw
        cntr
        PDPROPERTIES
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
            
            c = cell(1, numel(obj.PDPROPERTIES));
            obj.PData = cell2struct(c', obj.PDPROPERTIES);
            
            obj.Data = struct('gray', obj.gray, ...
                'bw',   obj.bw, ...
                'cntr', obj.cntr);
            
        end
        
        %         function obj = Seedling(varargin)
        %             %% Constructor for instancing a Seedling object
        %             try
        %                 switch nargin
        %                     case 0
        %                         disp('nothing entered');
        %
        %                     case 1
        %                         obj.ExperimentName = varargin{1};
        %                         Image_gray         = zeros(0,0);
        %                         Image_BW           = zeros(0,0);
        %                         Skeleton           = zeros(0,0);
        %
        %                     case 2
        %                         obj.ExperimentName = varargin{1};
        %                         obj.GenotypeName   = varargin{2};
        %                         Image_gray         = zeros(0,0);
        %                         Image_BW           = zeros(0,0);
        %                         Skeleton           = zeros(0,0);
        %
        %                     case 3
        %                         obj.ExperimentName = varargin{1};
        %                         obj.GenotypeName   = varargin{2};
        %                         obj.SeedlingName   = char(['Seedling_' varargin{3}]);
        %                         Image_gray         = zeros(0,0);
        %                         Image_BW           = zeros(0,0);
        %                         Skeleton           = zeros(0,0);
        %
        %                     case 4
        %                         obj.SeedlingName = char(['Seedling_' varargin{1}]);
        %                         Image_gray       = varargin{2};
        %                         Image_BW         = varargin{3};
        %                         Skeleton         = varargin{4};
        %
        %                     case 5
        %                         obj.ExperimentName = varargin{1};
        %                         obj.SeedlingName   = char(['Seedling_' varargin{2}]);
        %                         Image_gray         = varargin{3};
        %                         Image_BW           = varargin{4};
        %                         Skeleton           = varargin{5};
        %
        %                     case 6
        %                         obj.ExperimentName = varargin{1};
        %                         obj.GenotypeName   = varargin{2};
        %                         obj.SeedlingName   = char(['Seedling_' varargin{3}]);
        %                         Image_gray         = varargin{4};
        %                         Image_BW           = varargin{5};
        %                         Skeleton           = varargin{6};
        %
        %                     otherwise
        %                         fprintf(2, 'Too many arguments.');
        %                         return;
        %                 end
        %             catch e
        %                 fprintf(2, 'Error instancing Seedling');
        %                 fprintf(2, e.Message);
        %             end
        %
        %             obj.Data         = struct('Image_gray', Image_gray, ...
        %                 'Image_BW',   Image_BW,   ...
        %                 'Skeleton',   Skeleton);
        %             obj.Lifetime     = 0;
        %             obj.AnchorPoints = zeros(0, 0, 0);
        %
        %         end
        
        function obj = FindHypocotyl(obj, frm, hypln, crpsz)
            %% Find Hypocotyl with defined sizes within Seedling object
            % This function crops the top [h x w] of a Seedling
            % This may need to be more dynamic to account for Seedlings growing add odd angles.
            % I also need to set a detection algorithm to make sure Hypocotyl is in view.
            % Basically this should know the general 'shape' of a Hypocotyl. [how do I do this?]
            %
            % Input:
            %   obj  : this Seedling object
            %   frm  : frame in which to search for Hypocotyl
            %   hypln: length defining the search size for a Hypocotyl
            %   crpsz: [2 x 1] array defining the scaled size of each Hypocotyl
            %
            % Output:
            %   obj  : function sets AnchorPoints and PreHypocotyl
            
            % Store 4x2 matrix as this Seedling's AnchorPoints coordinates
            try
                dd     = bwconncomp(obj.getImageData(frm, 'bw'));
                p      = 'PixelList';
                props  = regionprops(dd, p);
                idx    = props.PixelList;
                
                if obj.AnchorPoints == 0
                    obj.AnchorPoints = getAnchorPoints(idx, hypln);
                else
                    obj.AnchorPoints(:, :, frm) = getAnchorPoints(idx, hypln);
                end
                
                % Crop out and resize PreHypocotyl for use as training data
                hGray = processHypocotyl(obj.getImageData(frm, 'gray'), ...
                    obj.getAnchorPointsAtFrame(frm), crpsz);
                
                hBW   = processHypocotyl(obj.getImageData(frm, 'bw'), ...
                    obj.getAnchorPointsAtFrame(frm), crpsz);
                
                if isempty(obj.PreHypocotyl)
                    obj.PreHypocotyl      = Hypocotyl(obj.ExperimentName, ...
                        obj.GenotypeName,   ...
                        obj.SeedlingName,   ...
                        'raw', hGray, hBW, 1);
                else
                    obj.PreHypocotyl(frm) = Hypocotyl(obj.ExperimentName, ...
                        obj.GenotypeName,   ...
                        obj.SeedlingName,   ...
                        'raw', hGray, hBW, frm);
                end
                
            catch
                fprintf('No image data found at %s Frame %d \n', obj.getSeedlingName, frm);
                obj.PreHypocotyl(frm) = Hypocotyl(obj.ExperimentName, ...
                    obj.GenotypeName,   ...
                    obj.SeedlingName,   ...
                    'raw', [], [], frm);
                return;
            end
        end
        
        
        % Instance a Hypocotyl object and set images to each frame
        % NOTE: needs to check for valid Hypocotyl in each frame
        %   [hypVisible, hypFrm] = check4Hypocotyl(fim);
        %   if ~hypVisible
        %       fprintf(2, 'No Hypocotyl found in Frame %d', frm);
        %   else
        %       obj.Hypocotyl   = Hypocotyl(obj); % Instance Hypocotyl for Seedling
        %       obj.HypIdx(frm) = hypFrm;         % Start indexing frames containing valid Hypocotyl
        %   end
        
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
        
        function obj = setImageData(obj, frm, dt)
            %% Set data for Seedling at desired frame
            obj.Data(frm) = dt;
        end
        
        function dat = getImageData(varargin)
            %% Return data for Seedling at desired frame
            % User can specify which image from structure with 3rd parameter
            switch nargin
                case 1
                    % Full structure of image data at all frames 
                    obj = varargin{1};
                    dat = obj.Data;
                    
                case 2
                    % All image data at frame                   
                    try
                        obj = varargin{1};
                        frm = varargin{2};
                        dat = obj.Data(frm);
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
                        dat = obj.Data(frm);
                    catch
                        fprintf(2, 'No image at frame %d \n', frm);
                    end
                    
                    % Get requested data field 
                    try
                        dfm = obj.Data(frm);
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
            if numel(obj.Coordinates) == 0
                obj.Coordinates = coords;
            else
                obj.Coordinates(frm, :) = coords;
            end
        end
        
        function coords = getCoordinates(obj, frm)
            %% Returns coordinates at specified frame
            % Make sure to check for nan (no coordinate found at frame
            try
                coords = obj.Coordinates(frm, :);
            catch
                fprintf('No coordinate found at frame %d \n', frm);
                coords = [nan nan];
            end
        end
        
        function obj = setFrame(obj, frm, bd)
            %% Set birth or death Frame number for Seedling
            switch bd
                case 'b'
                    obj.Frame = [frm obj.getFrame('d')];
                case 'd'
                    obj.Frame = [obj.getFrame('b') frm];
                otherwise
                    fprintf(2, 'Error setting Birth or Death Frame');
                    return;
            end
        end
        
        function frm = getFrame(obj, bd)
            %% Return birth or death Frame number for Seedling
            switch bd
                case 'b'
                    frm = obj.Frame(1);
                case 'd'
                    frm = obj.Frame(2);
                otherwise
                    fprintf(2, 'Error returning Birth or Death Frame');
                    return;
            end
        end
        
        function increaseLifetime(obj, inc)
            %% Increase Lifetime of Seedling by desired amount
            obj.Lifetime = obj.Lifetime + inc;
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
                    catch
                        fprintf(2, 'No data at frame %d \n', frm);
                    end
                    
                case 3
                    % Specific data property at given frame                                
                    % Check if frame exists
                    try
                        obj = varargin{1};
                        frm = varargin{2};
                        req = varargin{3};
                        pd  = obj.PData(frm);
                    catch
                        fprintf(2, 'No date at frame %d \n', frm);
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
        
        function pts = getAnchorPointsAtFrame(obj, frm)
            %% Returns 4x2 array of 4 anchor points representing Hypocotyl
            try
                pts = obj.AnchorPoints(:, :, frm);
            catch e
                fprintf(2, 'No AnchorPoints at index %s \n', frm);
                fprintf(2, '%s \n', e.getReport);
            end
        end
        
        function hyps = getAllPreHypocotyls(obj)
            %% Returns all PreHypocotyls
            hyps = obj.PreHypocotyl;
        end
        
        function hyp = getPreHypocotyl(obj, frm)
            %% Return PreHypocotyl at desired frame
            try
                hyp = obj.PreHypocotyl(frm);
            catch e
                fprintf(2, 'No PreHypocotyl at index %s \n', frm);
                fprintf(2, '%s \n', e.getReport);
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
            p.addOptional('Data', struct());
            p.addOptional('gray', []);
            p.addOptional('bw', []);
            p.addOptional('cntr', []);
            p.addOptional('PData', struct());
            p.addOptional('PDPROPERTIES', {});
            p.addOptional('Midline', []);
            p.addOptional('AnchorPoints', zeros(0, 0, 0));
            p.addOptional('HypIdx', []);
            p.addOptional('PreHypocotyl', Hypocotyl);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
    end
    
end
