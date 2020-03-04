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
        BUFF_PCT = 20
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
                vargs = varargin;
            else
                % Set default properties for empty object
                vargs = {};
            end

            prps   = properties(class(obj));
            deflts = {...
                    'Lifetime', 0 ; ...
                    'Frame'   , [0 0]};
            obj    = classInputParser(obj, prps, deflts, vargs);
            
        end
        
        function img = FlipMe(obj, frm, req, buf)
            %% Store a flipped version of each Hypocotyl
            % Flipped version allows equal representation of all orientations of
            % contours because equality (lolz). If buf is set to true, use the
            % version with a buffered region around the image
            %
            % Input:
            %   obj: this Hypocotyl object
            %   frm: time point to extract image from
            %   buf: boolean to return buffered region around image
            
            if buf > 0
                img = flip(obj.getImage(frm, req, buf), 2);
            else
                img = flip(obj.getImage(frm, req), 2);
            end
            
        end
        
        function obj = DerefParents(obj)
            %% Remove reference to Parent property
            % This lets you save an array of Hypocotyl objects without having to
            % save the entire tree of objects and children.
            obj.Parent = [];
            obj.Host   = [];
            obj.Origin = [];
            
        end
        
        function obj = RefChild(obj)
            %% Set reference back to Children [ after use of DerefParents ]
            %arrayfun(@(x) x.setParent(obj), obj.CircuitJB, 'UniformOutput', 0);
            
        end
        
    end
    
    %% ------------------------- Primary Methods --------------------------- %%
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
            try
                switch req
                    case 'a'
                        frm = obj.Frame;
                        
                    case 'b'
                        frm = obj.Frame(1);
                        
                    case 'd'
                        frm = obj.Frame(2);
                        
                    otherwise
                        fprintf(2, 'Request must be ''b'' or ''d''\n');
                        frm = [];
                end
            catch
                fprintf(2, 'Request must be ''b'' or ''d''\n');
                frm = [];
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
                    %% Return grayscale images at all time points
                    try
                        frm = obj.getFrame('b') : obj.getFrame('d');
                        img = obj.Parent.getImage(frm);
                        bnd = obj.getCropBox(frm);
                        bnd = num2cell(bnd, 2)';
                        crp = cellfun(@(i,b) imcrop(i,b), ...
                            img, bnd, 'UniformOutput', 0);
                        dat = cellfun(@(x) imresize(x, sclsz), ...
                            crp, 'UniformOutput', 0);
                    catch
                        fprintf(2, 'Error returning %d images\n', numel(frm));
                        dat = [];
                    end
                    
                case 2
                    %% Return grayscale image(s) at specific time point(s)
                    try
                        frm = varargin{2};
                        
                        if numel(frm) > 1
                            img = obj.Parent.getImage(frm);
                            bnd = num2cell(...
                                obj.getCropBox(frm), 2)';
                            crp = cellfun(@(i,b) imcrop(i,b), ...
                                img, bnd, 'UniformOutput', 0);
                            dat = cellfun(@(x) imresize(x, sclsz), ...
                                crp, 'UniformOutput', 0);
                        else
                            img = obj.Parent.getImage(frm);
                            crp = imcrop(img, obj.getCropBox(frm));
                            dat = imresize(crp, sclsz);
                        end
                    catch
                        fprintf(2, 'Requested field must be either: [b|d]\n');
                        dat = [];
                    end
                    
                case 3
                    %% Return Specific image type
                    % Get requested data field [ 'gray' | 'bw' ]
                    try
                        frm = varargin{2};
                        req = varargin{3};
                        
                        if numel(frm) > 1
                            img = obj.Parent.getImage(frm, req);
                            bnd = num2cell(...
                                obj.getCropBox(frm), 2)';
                            crp = cellfun(@(i,b) imcrop(i,b), ...
                                img, bnd, 'UniformOutput', 0);
                            dat = cellfun(@(x) imresize(x, sclsz), ...
                                crp, 'UniformOutput', 0);
                        else
                            img = obj.Parent.getImage(frm, req);
                            crp = imcrop(img, obj.getCropBox(frm));
                            dat = imresize(crp, sclsz);
                        end
                        
                    catch
                        fprintf(2, 'Requested field must be either: [b|d]\n');
                        dat = [];
                    end
                    
                case 4
                    %% Return flipped image of specific image type and frame(s)
                    try
                        frm = varargin{2};
                        req = varargin{3};
                        flp = varargin{4};
                        
                        if flp
                            % Extract image from parent Seedling
                            dat = obj.FlipMe(frm, req, 0);
                        else
                            dat = obj.getImage(frm, req);
                        end
                        
                    catch
                        fprintf(2, 'Requested field must be either: [b|d]\n');
                        dat = [];
                    end
                    
                case 5
                    %% Return frame with cropped and buffered region around image
                    % Set flp to true to use flipped version of image
                    try
                        frm = varargin{2};
                        req = varargin{3};
                        flp = varargin{4};
                        buf = varargin{5};
                        
                        if flp
                            % Extract image from parent Seedling
                            img = obj.FlipMe(frm, req, 0);
                            msk = obj.FlipMe(frm, 'bw',   0);
                        else
                            img = obj.getImage(frm, req);
                            msk = obj.getImage(frm, 'bw');
                        end
                        
                        if buf > 0
                            % Buffered median background intensity and size
                            if buf > 1
                                buffpct = buf;
                            else
                                buffpct = obj.BUFF_PCT;
                            end
                            
                            bnd      = obj.getCropBox(frm);
                            medBg    = median(img(msk == 1));
                            [dat, ~] = ...
                                cropWithBuffer(img, bnd, buffpct, medBg);
                        else
                            dat = img;
                        end
                        
                    catch
                        fprintf(2, ...
                            'Requested field must be either: gray | bw\n');
                        dat = [];
                        return;
                    end
                    
                otherwise
                    %% Get hard-set image
                    dat = obj.Image;
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
                        obj.Circuit(frm,1) = crc;
                    catch
                        obj.Circuit(frm,1) = crc;
                    end
                case 'flp'
                    try
                        obj.Circuit(frm,2) = crc;
                    catch
                        obj.Circuit(frm,2) = crc;
                    end
                    
                otherwise
                    fprintf(2, 'Error setting %s Circuit\n', req);
            end
        end
        
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
                            c = obj.Circuit(frm, 2);
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
        
        function [untrained_frames , trained_frames] = getUntrainedFrames(obj)
            %% Returns array of frames that have not been trained
            % Note that this only checks for a CircuitJB object in the original
            % orientation and assumes that the flipped orientation will give
            % the same result.
            try
                frms_all = 1 : obj.Lifetime;
                
                orgs = cell2mat(arrayfun(@(x) ~isempty(obj.getCircuit(x, 'org')), ...
                    frms_all, 'UniformOutput', 0));
                
                trained_frames   = frms_all(orgs);
                untrained_frames = frms_all(~orgs);
            catch e
                fprintf(2, 'Error returning untrained frames\n%s', e.message);
                untrained_frames = [];
                trained_frames   = [];
            end
        end
        
    end
    
    %% ------------------------- Private Methods --------------------------- %%
    methods (Access = private)
        % Private helper methods

    end
    
end
