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
        Image
        CropBox
        Midline
        Coordinates
        Contour
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
            
            obj.Image = struct('gray', [], ...
                'bw', [], ...
                'ctr', ContourJB);
        end
        
        function [im, bw] = FlipMe(obj)
            %% Store a flipped version of each Hypocotyl
            % Flipped version allows equal representation of all orientations of contours (lolz)
            im = flip(obj.Image.gray, 2);
            bw = flip(obj.Image.bw, 2);
            
            obj.Contour(2) = obj.Contour;
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
            % User can specify which image from structure with 2nd parameter
            obj = varargin{1};                        
            
            switch nargin
                case 1
                    % Return grayscale images at all time points
                    frm = obj.getFrame('b') : obj.getFrame('d');                    
                    img = obj.Parent.getImage(frm);
                    dat = imcrop(img, obj.CropBox);
                    
                case 2
                    % Return grayscale image at specific time point
                    try
                        frm = obj.getFrame('b');
                        img = obj.Parent.getImage(frm);
                        dat = imcrop(img, obj.CropBox);
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
                        dat = imcrop(img, obj.CropBox);              
                    catch
                        fprintf(2, 'Requested field must be either: gray | bw\n');
                        dat = [];
                    end
                    
                otherwise
                    fprintf(2, 'Error requesting data.\n');
                    return;
            end
        end
        
        %         function dat = getImage(varargin)
        %             %% Return image for this Hypocotyl
        %             % User can specify which image from structure with 2nd parameter
        %             switch nargin
        %                 case 1
        %                     % Full structure of image data at all frames
        %                     obj = varargin{1};
        %                     dat = obj.Image;
        %
        %                 case 2
        %                     % Return Specific image type
        %                     % Get requested data field
        %                     try
        %                         obj = varargin{1};
        %                         req = varargin{2};
        %                         dfm = obj.Image;
        %                         dat = dfm.(req);
        %                     catch
        %                         fn  = fieldnames(dfm);
        %                         str = sprintf('%s, ', fn{:});
        %                         fprintf(2, 'Requested field must be either: %s\n', str);
        %                     end
        %
        %                 otherwise
        %                     fprintf(2, 'Error requesting data.\n');
        %                     return;
        %             end
        %         end
        
        function obj = setParent(obj, p)
            %% Set Seedling parent, Genotype host, Experiment origin for this object
            obj.Parent       = p;
            obj.SeedlingName = p.SeedlingName;
            
            obj.Host         = p.Parent;
            obj.GenotypeName = obj.Host.GenotypeName;
            
            obj.Origin         = obj.Host.Parent;
            obj.ExperimentName = obj.Origin.ExperimentName;
            obj.ExperimentPath = obj.Origin.ExperimentPath;
            
        end
        
        function obj = setCropBox(obj, bbox)
            %% Set vector for bounding box
            box_size = [1 4];
            if isequal(size(bbox), box_size)
                obj.CropBox = bbox;
            else
                fprintf(2, 'CropBox should be size %s\n', num2str(box_size));
            end
        end
        
        function bbox = getCropBox(obj)
            %% Return CropBox parameter defining bounding box to crop from Parent Seedling
            bbox = obj.CropBox;
        end
        
        function obj = setContour(obj, crc, req)
            %% Set manually-drawn CircuitJB object (original or flipped)
            crc.trainCircuit(true);
            switch req
                case 'org'
                    try
                        obj.Contour(1) = crc;
                    catch
                        obj.Contour    = crc;
                    end
                case 'flp'
                    obj.Contour(2) = crc;
                    
                otherwise
                    fprintf(2, 'Error setting %s Contour\n', req);
            end
        end
        %   sIdx: index of randomly-selected Seedlings
        function crc = getContour(obj, req)
            %% Return original or flipped version of CircuitJB object
            if ~isempty(obj.Contour)
                switch req
                    case 'org'
                        try
                            c = obj.Contour(1);
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
                            c = obj.Contour(2);
                            if c.isTrained
                                crc = c;
                            else
                                crc = [];
                            end
                        catch
                            crc = [];
                        end
                    otherwise
                        fprintf(2, 'Error returning %s contour\n', req);
                end
            else
                crc = [];
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
            p.addOptional('Image', struct());
            p.addOptional('CropBox', zeros(1,4));
            p.addOptional('Midline', []);
            p.addOptional('Contour', CircuitJB);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
    end
    
end