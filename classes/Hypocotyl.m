%% Hypocotyl: class for individual hypocotyls identified from parent Seedling
% Class description

classdef Hypocotyl < handle
    properties (Access = public)
        %% Hypocotyl properties
        Parent
        Host
        Origin
        ExperimentName
        ExperimentPath
        GenotypeName
        SeedlingName
        HypocotylName
        Frame
        Lifetime
    end
    
    properties (Access = private)
        %% Private data stored here
        Contour
        Circuit
        CropBox
        Midline
        Coordinates
    end
    
    methods (Access = public)
        %% Constructor and main methods
        function obj = Hypocotyl(varargin)
            %% Constructor method for Hypocotyl
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
            
        end
        
        function [im, bw] = FlipMe(obj)
            %% Store a flipped version of each Hypocotyl
            % Flipped version allows equal representation of all 
            % orientations of contours (lolz)
            im = flip(obj.Image.gray, 2);
            bw = flip(obj.Image.bw, 2);
            
            obj.Circuit(2) = obj.Circuit;
        end

        function obj = PruneSeedlings(obj)
            %% Remove RawSeedlings to decrease data
            obj.RawSeedlings = [];

        end

        function obj = DerefParents(obj)
            %% Remove reference to Parent property
            obj.Parent = [];
            obj.Host   = [];
            obj.Origin = [];

        end

        function obj = RefChild(obj)
            %% Set reference back to Children [ after use of DerefParents ]
            %arrayfun(@(x) x.setParent(obj), obj.CircuitJB, 'UniformOutput', 0);

        end
        
    end
    
    methods (Access = public)
        %% Various helper methods
        function obj = setHypocotylName(obj, n)
            %% Set name of Hypocotyl
            obj.HypocotylName = n;
        end
        
        function n = getHypocotylName(obj)
            %% Return name of Hypocotyl
            n = obj.HypocotylName;
        end
        
        function obj = setFrame(obj, req, frm)
            %% Set birth or death frames
            try
                switch req
                    case 'b'
                        obj.Frame(1) = frm;
                        
                    case 'd'
                        obj.Frame(2) = frm;
                        
                    otherwise
                        fprintf(2, 'Request must be ''b'' or ''d''\n');
                end
            catch
                fprintf(2, 'No data at frame %d\n', frm);
            end
            
        end
        
        function frm = getFrame(obj, req)
            %% Returns birth or death frame
            switch req
                case 'b'
                    frm = obj.Frame(1);
                    
                case 'd'
                    frm = obj.Frame(2);
                    
                otherwise
                    fprintf(2, 'Request must be ''b'' or ''d''\n');
                    return;
            end
        end
        
        function obj = setImage(obj, req, dat)
            %% Store data into Hypocotyl
            % Set data into requested field
            try
                if isfield(obj.Image, req)
                    obj.Image.(req) = dat;
                else
                    fn  = fieldnames(obj.Image);
                    str = sprintf('%s, ', fn{:});
                    fprintf(2, 'Requested field must be either: %s\n', str);
                end
            catch
                fprintf(2, 'Error setting %s data\n', req);
            end
        end
        
        function dat = getImage(varargin)
            %% Return image for this Hypocotyl
            % Image is obtained from the Parent Seedling, cropped, and resized
            % to this object's RESCALE property
            obj   = varargin{1};                        
            sclsz = obj.Parent.getScaleSize;
            
            switch nargin
                case 1
                    % Return grayscale images at all time points
                    % DON'T USE THIS YET
                    %frm = obj.getFrame('b') : obj.getFrame('d');                    
                    %img = obj.Parent.getImage(frm);
                    %crp = imcrop(img, obj.getCropBox(frm));
                    %dat = imresize(crp, sclsz);
                    dat = [];
                    
                case 2
                    % Return grayscale image at specific time point
                    try
                        frm = varargin{2};
                        img = obj.Parent.getImage(frm);
                        crp = imcrop(img, obj.getCropBox(frm));
                        dat = imresize(crp, sclsz);
                    catch
                        fprintf(2, 'Requested field must be either: %s\n', str);
                    end
                    
                case 3
                    % Return Specific image type
                    % Get requested data field
                    try
                        frm = varargin{2};
                        req = varargin{3};                                           
                        img = obj.Parent.getImage(frm, req);                        
                        crp = imcrop(img, obj.getCropBox(frm));              
                        dat = imresize(crp, sclsz);
                    catch
                        fprintf(2, ...
                        	'Requested field must be either: gray | bw\n');
                        dat = [];
                    end
                    
                otherwise
                    fprintf(2, 'Error requesting data.\n');
                    return;
            end
        end
        
        function obj = setParent(obj, p)
            %% Set Seedling parent | Genotype host| Experiment origin 
            obj.Parent       = p;
            obj.SeedlingName = p.SeedlingName;
            
            obj.Host         = p.Parent;
            obj.GenotypeName = obj.Host.GenotypeName;
            
            obj.Origin         = obj.Host.Parent;
            obj.ExperimentName = obj.Origin.ExperimentName;
            obj.ExperimentPath = obj.Origin.ExperimentPath;
            
        end
        
        function obj = setCropBox(obj, frm, bbox)
            %% Set vector for bounding box
            box_size = [1 4];
            if isequal(size(bbox), box_size)
                if isempty(obj.CropBox)
                    obj.CropBox(1, :) = bbox;
                else
                    obj.CropBox(frm, :) = bbox;
                end
            else
                fprintf(2, 'CropBox should be size %s\n', num2str(box_size));
            end
        end

        function bbox = getCropBox(obj, frm)
            %% Return CropBox parameter, or the [4 x 1] vector that defines the 
            % bounding box to crop from Parent Seedling
            bbox = obj.CropBox(frm, :);
        end
        
        function obj = setContour(obj, frm, ctr)
            %% Store ContourJB at frame
            if isempty(obj.Contour)
                obj.Contour = ctr;
            else
                obj.Contour(frm) = ctr;
            end
    	end

        function crc = getContour(varargin)
            %% Return all ContourJB objects or ContourJB at frame
            obj = varargin{1};

            switch nargin
                case 1
                    crc = obj.Contour;
                case 2
                    frm = varargin{2};
                    crc = obj.Contour(frm);
                otherwise
                    fprintf(2, 'Error returning ContourJB\n');
                    crc = [];
            end

        end

        function obj = setCircuit(obj, frm, crc, req)
            %% Set manually-drawn CircuitJB object (original or flipped)
            crc.trainCircuit(true);
            switch req
                case 'org'
                    try
                        obj.Circuit(1,1) = crc;
                    catch
                        obj.Circuit(frm,1)    = crc;
                    end
                case 'flp'
                    try
                        obj.Circuit(1,2) = crc;
                    catch
                        obj.Circuit(frm,2) = crc;
                    end
                    
                otherwise
                    fprintf(2, 'Error setting %s Circuit\n', req);
            end
        end
        %   sIdx: index of randomly-selected Seedlings

        function crc = getCircuit(obj, frm, req)
            %% Return original or flipped version of CircuitJB object
            if ~isempty(obj.Circuit)
                switch req
                    case 'org'
                        try
                            c = obj.Circuit(frm, 1);
                            if c.isTrained
                                crc = c;
                            else
                                crc = [];
                            end
                        catch
                            crc = [];
                        end
                    case 'flp'
                        try
                            c = obj.Circuit(2);
                            if c.isTrained
                                crc = c;
                            else
                                crc = [];
                            end
                        catch
                            crc = [];
                        end 
                    otherwise
                        fprintf(2, 'Error returning %s circuit\n', req);
                end
            else
                crc = [];
            end
        end

        function prp = getProperty(obj, req)
            %% Returns a property of this Hypocotyl object
            	try
                    prp = obj.(req);
                catch e
                    fprintf(2, 'Property %s does not exist\n%s', ...
                    	req, e.message);
                end
        end

    end
    
    methods (Access = private)
        % Private helper methods
        function args = parseConstructorInput(varargin)
            %% Parse input parameters for Constructor method
            % Parent is Seedling object
            % Host is Genotype object
            % Origin is Experiment object
            p = inputParser;
            p.addRequired('HypocotylName');
            p.addOptional('Parent', []);
            p.addOptional('Host', []);
            p.addOptional('Origin', []);
            p.addOptional('SeedlingName', '');
            p.addOptional('GenotypeName', '');
            p.addOptional('ExperimentName', '');
            p.addOptional('ExperimentPath', '');
            p.addOptional('Frame', zeros(1,2));
            p.addOptional('Lifetime', 0);
            p.addOptional('Coordinates', []);
            p.addOptional('CropBox', zeros(1,4));
            p.addOptional('Midline', []);
            p.addOptional('Contour', ContourJB);
            p.addOptional('Circuit', CircuitJB);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
    end
    
end
