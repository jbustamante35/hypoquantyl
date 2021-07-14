%% ContourJB: my customized class for generating contours
% Class description [you really need to document this] test

classdef ContourJB < handle
    properties (Access = public)
        Origin
        Host
        Parent
        Outline
        InterpSize
    end
    
    properties (Access = private)
        Image
        AnchorPoint
        AnchorIndex
        AltInit
        Dists
        Sums
    end
    
    methods (Access = public)
        %% Constructor and primary methods
        function obj = ContourJB(varargin)
            %% Constructor method for Seedling
            % Parse inputs to set class properties
            args = obj.parseConstructorInput(varargin);
            fn   = fieldnames(args);
            
            for k = fn'
                obj.(cell2mat(k)) = args.(cell2mat(k));
            end
            
        end
        
        function intrp = InterpOutline(obj, npts, ncrd)
            %% Interpolate outline to adjust number of coordinates
            switch nargin
                case 1
                    npts = obj.InterpSize;
                    ncrd = ':';
                case 2
                    ncrd = ':';
            end
            
            intrp = interpolateOutline(obj.Outline, npts);
            intrp = intrp(ncrd,:);
            
        end
        
        function nrm = NormalizeOutline(obj, init)
            %% Use alternative initial points
            if nargin < 2
                init = obj.AltInit;
            end
            
            %% Reindex coordinates to normalize start points
            intrp = obj.InterpOutline;
            
            [obj.AnchorPoint, obj.AnchorIndex] = ...
                findAnchorPoint(obj, intrp, obj.AltInit);
            
            nrm = obj.repositionPoints(intrp, obj.AnchorIndex, init);
            
        end
        
        function crds = Normal2Raw(obj)
            %% Convert NormalizedOutline to un-indexed InterpOutline
            crds = norm2raw(obj.NormalizeOutline, ...
                obj.AnchorPoint, obj.AnchorIndex);
            
        end
    end
    
    methods (Access = public)
        %% Accessible helper methods
        function obj = setImage(obj, frm, req, img)
            %% Set grayscale or bw image at given frame
            try
                obj.Image(frm).(req) = img;
            catch
                fprintf(2, 'Error setting %s image at frame %d\n', req, frm);
            end
        end
        
        function typ = getImage(varargin)
            %% Return image data for ContourJB at desired frame
            % User can specify which image from structure with 3rd parameter
            switch nargin
                case 1
                    % Full structure of image data at all frames
                    obj = varargin{1};
                    typ = obj.Image;
                    
                case 2
                    % All image data at frame
                    try
                        obj = varargin{1};
                        frm = varargin{2};
                        typ = obj.Image(frm);
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
                        typ = obj.Image(frm);
                    catch
                        fprintf(2, 'No image at frame %d \n', frm);
                    end
                    
                    % Get requested image type
                    try
                        dfm = obj.Image(frm);
                        typ = dfm.(req);
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
        
        function obj = setParent(obj, p)
            %% Designate origin of contour
            obj.Parent = p;
            obj.Host   = p.Parent;
            obj.Origin = p.Parent.Parent;
        end
        
        function org = getParent(obj)
            %% Returns origin of contour
            org = obj.Parent;
        end
        
        function apt = getAnchorPoint(obj)
            %% Return Anchor Point of this contour
            apt = obj.AnchorPoint;
        end
        
        function idx = getAnchorIndex(obj)
            %% Return Anchor Point index
            idx = obj.AnchorIndex;
        end
        
        function obj = setInterpSize(obj, npts)
            %% Set number of coordinates to interpolate to
            if nargin < 2
                npts = obj.InterpSize;
            end
            
            obj.InterpSize = npts;
        end
        
    end
    
    methods (Access = private)
        %% Private helper methods
        function args = parseConstructorInput(varargin)
            %% Parse input parameters for Constructor method
            % Parent is Seedling object
            % Host is Genotype object
            % Origin is Experiment object
            p = inputParser;
            p.addOptional('Outline', []);
            p.addOptional('Dists', []);
            p.addOptional('Sums', []);
            p.addOptional('InterpSize', 800);
            p.addOptional('AnchorPoint', []);
            p.addOptional('Parent', []);
            p.addOptional('Origin', []);
            p.addOptional('Host', []);
            p.addOptional('Image', struct('gray', [], 'bw', []));
            p.addOptional('AltInit', 'default');
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
        function [apt, idx] = findAnchorPoint(obj, crds, init)
            %% findAnchorPoint: find anchor point coordinate
            % The definition of the anchor point is determined by the algorithm
            % selected.
            %
            % The first is typically for CarrotSweeper, where the
            % anchor point is defined as lowest and central column of the
            % corresponding image. This is the default algorithm if the alg
            % parameter is empty.
            %
            % The second algorithm is for HypoQuantyl, where the anchor point is
            % defined as the lower-left coordinate of the image. This is the
            % standardaized starting location for training hypocotyl images. The
            % alg parameter should be set to 1 or true to use this.
            %
            
            if strcmpi(init , 'default')
                %% Use CarrotSweeper's anchor point
                low = min(crds(:,1));
                rng = round(crds(crds(:,1) == low, :), 4);
                
                % Get median of column range
                if mod(size(rng,1), 2)
                    mtc = median(rng, 1);
                else
                    % Remove last row if even number of values
                    nrng = rng(1:end-1, :);
                    mtc  = median(nrng, 1);
                end
                
                % Get index of Anchor Point
                idx = find(ismember(round(crds, 4), round(mtc, 4), 'rows'));
                if ~isempty(idx > 1)
                    % Check if more than 1 index and choose larger index
                    idx = max(idx);
                elseif isnan(mtc)
                    % Check if no index found, if range is only a single value
                    %idx = find(crds == rng);
                    idx = find(ismember(round(crds), round(rng), 'rows'));
                end
                
            else
                %% Use HypoQuantyl's anchor point
                % Get the initial starting point for contours and shift indexing
                % of coordinates for CircuitJB objects used in my training set.
                %
                % UPDATE [06.02.2021]
                % This will now identify the base of the contour and set the
                % starting point to the left-most point of the base.
                LOWRANGE = 2;
                b        = labelContour(crds, LOWRANGE);
                bidxs    = find(b);
                idx      = bidxs(end);
            end
            
            %% Pull out the anchor point from the coordinates
            apt = crds(idx, :);
            
        end
        
        function shft = repositionPoints(obj, crds, idx, init)
            %% Shift contour points around AnchorPoint coordinate
            
            if strcmpi(init, 'default')
                %% Re-index and Re-Center around AnchorPoint
                subt = crds - crds(idx,:);
                shft = circshift(subt, -idx+1);
            else
                %% Only Re-index saround AnchorPoint coordinate
                shft = circshift(crds, -idx+1);
            end
        end
        
    end
end
