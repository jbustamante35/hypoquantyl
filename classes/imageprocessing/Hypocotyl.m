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
        Stem
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
                    % Get image type [ 'gray' | 'bw'  || 'upper' | 'lower']
                    try
                        frm = varargin{2};
                        req = varargin{3};
                        if ismember(req, {'gray' , 'bw'})
                            %% Get grayscale or bw image
                            % Always get upper region
                            rgn = 'upper';
                        elseif ismember(req, {'upper' , 'lower'})
                            %% Get upper or lower region
                            % Always get grayscale image
                            rgn = req;
                            req = 'gray';
                        end
                        
                        %% Get image
                        if numel(frm) > 1
                            img = obj.Parent.getImage(frm, req);
                            bnd = num2cell(...
                                obj.getCropBox(frm, rgn), 2)';
                            crp = cellfun(@(i,b) imcrop(i,b), ...f
                                img, bnd, 'UniformOutput', 0);
                            dat = cellfun(@(x) imresize(x, sclsz), ...
                                crp, 'UniformOutput', 0);
                        else
                            img = obj.Parent.getImage(frm, req);
                            crp = imcrop(img, obj.getCropBox(frm, rgn));
                            dat = imresize(crp, sclsz);
                        end
                        
                    catch
                        fprintf(2, 'Request must be [gray|bw||upper|lower]\n');
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
                            'Requested field must be either [gray|bw]\n');
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
            % Seedling
            obj.Parent       = p;
            obj.SeedlingName = p.SeedlingName;
            
            % Genotype
            obj.Host         = p.Parent;
            obj.GenotypeName = obj.Host.GenotypeName;
            
            % Experiment
            obj.Origin         = obj.Host.Parent;
            obj.ExperimentName = obj.Origin.ExperimentName;
            obj.ExperimentPath = obj.Origin.ExperimentPath;
        end
        
        function setCropBox(obj, frms, bbox, rgn)
            %% Set vector for bounding box
            switch nargin
                case 3
                    rgn = 'upper';
            end
            
            switch rgn
                case 'upper'
                    r = 1;
                case 'lower'
                    r = 2;
                otherwise
                    fprintf(2, 'Region %s not recognized [upper|lower]\n', rgn);
                    return;
            end
            
            bdims = [1 , 4];
            if isequal(size(bbox(1,:)), bdims)
                if isempty(obj.CropBox)
                    obj.CropBox(1, :, r) = bbox;
                else
                    obj.CropBox(frms, :, r) = bbox;
                end
            else
                fprintf(2, 'CropBox should be size %s\n', num2str(bdims));
            end
        end
        
        function bbox = getCropBox(obj, frm, rgn)
            %% Return CropBox parameter
            % The CropBox is a [4 x 1] vector that defines the bounding box
            % to crop from Parent Seedling. This can be from either the upper or
            % lower region of the Seedling.
            
            % Defaults
            switch nargin
                case 1
                    frm = ':';
                    rgn = 'upper';
                case 2
                    rgn = 'upper';
            end
            
            % Region dimension
            switch rgn
                case 'upper'
                    r = 1;
                case 'lower'
                    r = 2;
                otherwise
                    fprintf(2, 'Region %s not recognized [upper|lower]\n', rgn);
                    bbox = [];
                    return;
            end
            
            bbox = obj.CropBox(frm, :, r);
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
        
        function cc = copyCircuit(obj, frm, req, ver)
            %% Copy counterpart of CircuitJB at same frame
            % Original or flipped direction
            switch req
                case 'org'
                    flp = 1;
                case 'flp'
                    flp = 2;
                otherwise
                    fprintf(2, 'Error setting %s direction\n', req);
            end
            
            % Whole or clipped contour
            switch ver
                case 'Full'
                    clp = 1;
                case 'Clip'
                    clp = 2;
                otherwise
                    fprintf(2, 'Error setting %s version\n', req);
            end
            
            % Make copy
            crc = obj.Circuit(frm, flp, clp);
            cc  = crc.copy;
        end
        
        function obj = setCircuit(obj, frm, crc, req, ver)
            %% Set manually-drawn CircuitJB object (original or flipped)
            switch nargin
                case 3
                    req = 'org';
                    ver = 'Full';
                case 4
                    ver = 'Full';
            end
            
            % Original or flipped direction
            switch req
                case 'org'
                    flp = 1;
                case 'flp'
                    flp = 2;
                otherwise
                    fprintf(2, 'Error setting %s direction\n', req);
            end
            
            % Whole or clipped contour
            switch ver
                case 'Full'
                    clp = 1;
                case 'Clip'
                    clp = 2;
                otherwise
                    fprintf(2, 'Error setting %s version\n', req);
            end
            
            % Forcibly set final Circuit
            try
                % Make copy of 'whole' version if 'clipped' not yet set
                cc = obj.Circuit(frm, flp, clp);
                if isempty(cc.Origin)
                    cc = obj.copyCircuit(frm, req, 'Full');
                    cc.setOutline(crc, 'Clip');
                end
                cc.trainCircuit(true);
            catch
                cc                         = obj.copyCircuit(frm, req, 'Full');
                obj.Circuit(frm, flp, clp) = cc;
                cc.setOutline(crc, 'Clip');
                crc.trainCircuit(true);
            end
        end
        
        function crc = getCircuit(obj, frm, req, ver)
            %% Return original or flipped version of CircuitJB object
            %             if nargin < 2; frm = 1 : size(obj.Circuit,1); end
            if nargin < 2; frm = 0;      end % First available CircuitJB
            if nargin < 3; req = 'org';  end
            if nargin < 4; ver = 'Full'; end
            
            crc = [];
            if ~isempty(obj.Circuit)
                % Find first available frame
                if ~frm
                    cc  = arrayfun(@(x) ~isempty(x.Origin), obj.Circuit(:,1,1));
                    cc  = find(cc);
                    frm = cc(1);
                end
                
                % Make sure frame is available
                if frm > size(obj.Circuit,1)
                    return;
                end
                
                % Get original or flipped version
                switch req
                    case 'org'
                        flp = 1;
                    case 'flp'
                        flp = 2;
                    otherwise
                        fprintf(2, 'Error returning %s circuit [org|flp]\n', ...
                            req);
                        return;
                end
                
                % Get whole contour or clipped version
                switch ver
                    case 'Full'
                        clp = 1;
                    case 'Clip'
                        clp = 2;
                    otherwise
                        fprintf(2, 'Error returning %s version [Full|Clip]\n', ...
                            ver);
                        return;
                end
                
                try
                    c = obj.Circuit(frm, flp, clp);
                    
                    % Add 3rd dimension if it doesn't exist
                    if ndims(obj.Circuit) < 3
                        obj.Circuit(1,1,2) = eval(class(obj.Circuit(1,1,1)));
                    end
                    
                    % Set isTrained status to false if not yet set
                    if isempty(c.isTrained)
                        c.trainCircuit(false);
                    end
                    
                    if isvalid(c) && c.isTrained
                        crc = c;
                    end
                catch
                    return;
                end
            else
                crc = [];
            end
        end
        
%         function fixLifetime(obj)
%             %% Fix Lifetime property to number of CircuitJB available
%             obj.Lifetime = size(obj.Circuit,1);
%         end
        
        function setProperty(obj, req, val)
            %% Set property to a value
            try
                obj.(req) = val;
            catch e
                fprintf(2, 'Can''t set %s to %s\n%s', ...
                    req, num2str(val), e.message);
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
                frms_all = ~cellfun(@isempty, arrayfun(@(x) x.isTrained, ...
                    obj.Circuit, 'UniformOutput', 0));
                
                trained_frames   = find(frms_all(:,1));
                untrained_frames = find(~frms_all(:,1));
            catch e
                fprintf(2, 'Error returning untrained frames\n%s', e.message);
                untrained_frames = [];
                trained_frames   = [];
            end
        end
        
        function ResetCropBox(obj, frms)
            %% Set lower region bounding box for frame
            if nargin < 2
                frms = 1 : obj.Lifetime;
            end
            
            s     = obj.Parent;
            imgs  = s.getImage(frms);
            apts  = s.getAnchorPoints(frms);
            scl   = s.getProperty('SCALESIZE');
            nfrms = numel(frms);
            if nfrms > 1
                [tm , tb , lm , lb] = deal(cell(nfrms, 1));
                for f = 1 : nfrms
                    [tm{f} , tb{f} , lm{f} , lb{f}] = ...
                        cropFromAnchorPoints(imgs{f}, apts(:,:,f), scl);
                end
                
                tb = cat(1, tb{:});
                lb = cat(1, lb{:});
            else
                [~ , tb , ~ , lb] = cropFromAnchorPoints(imgs, apts, scl);
            end
            
            % Reset upper and lower bounding boxes
            obj.setCropBox(frms, tb, 'upper');
            obj.setCropBox(frms, lb, 'lower');
        end
    end
    
    %% ------------------------- Private Methods --------------------------- %%
    methods (Access = private)
        % Private helper methods
    end
end
