%% ContourJB: my customized class for generating contours of  [NO LONGER USED]
% Class description

classdef ContourJB < handle
    properties (Access = public)
        Outline
        Dists
        Sums
        InterpOutline
        NormalizedOutline
    end
    
    properties (Access = private)
        AnchorPoint
        AnchorIndex
        Origin
        Image
        gray
        bw
    end
    
    methods (Access = public)
        %% Constructor and primary methods
        function obj = ContourJB(varargin)
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
            
            obj.Image = struct('gray', obj.gray, ...
                'bw',   obj.bw);
            
        end
        
        function obj = ReindexCoordinates(obj)
            %% Reindex coordinates to normalize start points
            [obj.AnchorPoint, obj.AnchorIndex] = findAnchorPoint(obj, obj.InterpOutline);
            obj.NormalizedOutline   = repositionPoints(obj, obj.InterpOutline, obj.AnchorIndex);
        end
        
        function crds = Normal2Raw(obj)
            %% Convert NormalizedOutline to un-indexed InterpOutline
            crds = norm2raw(obj.NormalizedOutline, obj.AnchorPoint, obj.AnchorIndex);
            
        end
    end
    
    methods (Access = public)
        %% Accessible helper methods                
        function obj = setImage(obj, frm, req, im)
            %% Set grayscale or bw image at given frame
            try
                obj.Image(frm).(req) = im;
            catch
                fprintf(2, 'Error setting %s image at frame %d\n', req, frm);
            end                            
        end
        
        function dat = getImage(varargin)
            %% Return image data for ContourJB at desired frame
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
        
        function obj = setOrigin(obj, org)
            %% Designate origin of contour
            obj.Origin = org;
        end
        
        function org = getOrigin(obj)
            %% Returns origin of contour
            org = obj.Origin;
        end
        
        function apt = getAnchorPoint(obj)
            %% Return Anchor Point of this contour
            apt = obj.AnchorPoint;
        end
        
        function idx = getAnchorIndex(obj)
            %% Return Anchor Point index
            idx = obj.AnchorIndex;
        end
        
    end
    
    methods (Access = private)
        %% Private helper methods
        function args = parseConstructorInput(varargin)
            %% Parse input parameters for Constructor method
            p = inputParser;
            p.addOptional('Outline', []);
            p.addOptional('Dists', []);
            p.addOptional('Sums', []);
            p.addOptional('InterpOutline', []);
            p.addOptional('NormalizedOutline', []);
            p.addOptional('AnchorPoint', []);
            p.addOptional('Origin', '');
            p.addOptional('Image', []);
            p.addOptional('gray', []);
            p.addOptional('bw', []);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
        function [apt, idx] = findAnchorPoint(obj, crds)
            %% Find coordinate at anchor point
            % Anchor point is defined as lowest and central location of a
            
            % Find lowest row point and range of columns at lowest row point
            low = max(crds(:,1));
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
            
            apt = crds(idx, :);
        end
        
        function shft = repositionPoints(obj, crds, idx)
            %% Re-index coordinates from Anchor Point and Re-center around AnchorPoint
            subt = crds - crds(idx,:);
            shft = circshift(subt, -idx+1);
        end
        
    end
end
