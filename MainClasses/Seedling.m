%% Seedling: class containing an individual seedling from a Genotype image stack
% Class description

classdef Seedling < handle
    properties (Access = public)
    %% Seedling properties
        ExperimentName
        GenotypeName
        SeedlingName
        Frame = zeros(1,2);
        Lifetime
        Coordinates
        Data        
        PData
        Hypocotyl
    end
    
    properties (Access = private)
    %% Private data
        Midline
        HypIdx
        
    end
    
    methods (Access = public)
    %% Constructor and main functions
        function obj = Seedling(varargin)
        %% Constructor for instancing a Seedling object
            try
                switch nargin
                    case 0
                        disp('nothing entered');

                    case 1 
                        obj.ExperimentName = varargin{1};
                        Image_gray         = zeros(0,0);
                        Image_BW           = zeros(0,0);
                        Skeleton           = zeros(0,0);

                    case 2
                        obj.ExperimentName = varargin{1};
                        obj.GenotypeName   = varargin{2};
                        Image_gray         = zeros(0,0);
                        Image_BW           = zeros(0,0);
                        Skeleton           = zeros(0,0);

                    case 3
                        obj.ExperimentName = varargin{1};
                        obj.GenotypeName   = varargin{2};
                        obj.SeedlingName   = char(['Seedling_' varargin{3}]);
                        Image_gray         = zeros(0,0);
                        Image_BW           = zeros(0,0);
                        Skeleton           = zeros(0,0);

                    case 4   
                        obj.SeedlingName = char(['Seedling_' varargin{1}]);
                        Image_gray       = varargin{2};
                        Image_BW         = varargin{3};
                        Skeleton         = varargin{4};

                    case 5
                        obj.ExperimentName = varargin{1};
                        obj.SeedlingName   = char(['Seedling_' varargin{2}]);
                        Image_gray         = varargin{3};
                        Image_BW           = varargin{4};
                        Skeleton           = varargin{5};

                    case 6
                        obj.ExperimentName = varargin{1};
                        obj.GenotypeName   = varargin{2};
                        obj.SeedlingName   = char(['Seedling_' varargin{3}]);
                        Image_gray         = varargin{4};
                        Image_BW           = varargin{5};
                        Skeleton           = varargin{6};
                        
                    otherwise
                        fprintf(2, 'Too many arguments.');
                        return;
                end
            catch e
                fprintf(2, 'Error instancing Seedling');
                fprintf(2, e.Message);
            end
            
            obj.Data  = struct('Image_gray', Image_gray, ...
                               'Image_BW',   Image_BW,   ...
                               'Skeleton',   Skeleton);
            obj.Lifetime = 0;

        end
        
        function obj = FindHypocotyl(obj, frm, sz1, sz2, vis)
        %% Find Hypocotyl with defined sizes within Seedling object
        % This function crops the top [h x w] of a Seedling
        % This may need to be more dynamic to account for Seedlings growing add odd angles. 
        % I also need to set a detection algorithm to make sure Hypocotyl is in view. 
        % Basically this should know the general 'shape' of a Hypocotyl. [how do I do this?]
        %
        % Input:
        %   frm: frame in which to search for Hypocotyl
        %   sz1: [2 x 1] array defining the size of the search box to find a Hypocotyl 
        %   sz2: [2 x 1] array defining the fixed size each Hypocotyl should be
        
        % sz = [300 100] seems to be a decent size to test 
            rgn = [0 0 sz1];
            im  = structfun(@(x) imcrop(x, rgn), obj.getImageData(frm), 'UniformOutput', 0);                        
        
        % Search region from BW image for objects
            dd  = bwconncomp(im.Image_BW);
            prp = regionprops('table', dd, im.Image_BW, 'all');
            gr  = imcrop(im.Image_gray, prp.BoundingBox);
            bw  = prp.Image{1};
                        
        % Crop the object to size determined by sz2
            fim = imcrop(gr, [0 0 sz2]);            
            
        % Instance a Hypocotyl object and set images to each frame 
        % NOTE: needs to check for valid Hypocotyl in each frame
        %   [hypVisible, hypFrm] = check4Hypocotyl(fim);
        %   if ~hypVisible
        %       fprintf(2, 'No Hypocotyl found in Frame %d', frm);
        %   else 
        %       obj.Hypocotyl   = Hypocotyl(obj); % Instance Hypocotyl for Seedling
        %       obj.HypIdx(frm) = hypFrm;         % Start indexing frames containing valid Hypocotyl
        %   end
        
%             for i = 1:obj.getLifetime
                
        
        % Visualize objects in a figure
            if vis
                figure;
                subplot(231); imagesc(im.Image_gray), colormap gray, axis image;
                subplot(232); imagesc(im.Image_BW), colormap gray, axis image;
                subplot(233); imagesc(im.Skeleton), colormap gray, axis image;
                subplot(234); imagesc(gr), colormap gray, axis image;
                subplot(235); imagesc(bw), colormap gray, axis image;
                subplot(236); imagesc(fim), colormap gray, axis image;
            end
            
            
        end
                
    end
    
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
        
        function dt_out = getImageData(varargin)
        %% Return data for Seedling at desired frame
        % User can specify which image from structure with 3rd parameter            
            switch nargin
                case 1
                    fprintf(2, 'Error. Must specify frame');
                    return;
                    
                case 2                    
                    obj    = varargin{1};
                    dt_out = obj.Data(varargin{2});
                    
                case 3
                    obj = varargin{1};
                    dtf = obj.Data(varargin{2});
                    req = varargin{3};
                    try
                        switch req
                            case 'Image_gray'
                                dt_out = dtf.Image_gray;

                            case 'Image_BW'
                                dt_out = dtf.Image_BW;

                            case 'Skeleton'
                                dt_out = dtf.Skeleton;                           
                        end
                        
                    catch e
                        fprintf(2, 'Error requesting field, %d', e.Message);
                        dt_out = {};
                        return;
                    end
                    
                otherwise
                    fprintf(2, 'Error requesting data.');
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
            coords = obj.Coordinates(frm, :);
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
            if numel(obj.PData) == 0
                obj.PData = pd;
            else
                obj.PData(frm) = pd;
            end
        end
        
        function pd = getPData(obj, frm)
        %% Return extra properties data at given frame
            pd = obj.PData(frm);
        end
        
    end
    
    methods (Access = private)
    %% Private helper methods
        function hyp = check4Hypocotyl(obj, im)
        %% Search inputted image for valid Hypocotyl
            hyp = false;
            
            

        end
    
    end
    
end
