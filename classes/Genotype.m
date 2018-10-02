%% Genotype: class for storing a single image stack from an Experiment
% This is largely a placeholder class for the real program

classdef Genotype < handle
    properties (Access = public)
        %% What data should this have?
        Parent
        ParentName
        ParentPath
        GenotypeName
        TotalImages
        NumberOfSeedlings
    end
    
    properties (Access = private)
        %% Private data to hold
        Images
        ImageStore
        RawSeedlings
        Seedlings
        CONTOURSIZE  = 800           % Number of points to normalize Seedling contours
        MASKSIZE     = [3000 100000] % Cut-off area for objects in image
        PDPROPERTIES = {'Area', 'BoundingBox', 'PixelList', 'WeightedCentroid', 'Orientation'};
    end
    
    %% ------------------------- Primary Methods --------------------------- %%
    
    methods (Access = public)
        %% Constructor and main methods
        function obj = Genotype(varargin)
            %% Constructor method for Genotype
            if ~isempty(varargin)
                % Parse inputs to set properties
                args = obj.parseConstructorInput(varargin);
                
                fn = fieldnames(args);
                for k = fn'
                    obj.(cell2mat(k)) = args.(cell2mat(k));
                end
                
            else
                % Set default properties for empty object
                obj = Genotype(getDirName(pwd));
            end
            
        end
        
        function obj = StackLoader(obj, varargin)
            %% Load raw images from directory
            % Load images from directory
            if nargin == 0
                [obj.Images, exptName] = getImageFiles;
                obj.GenotypeName       = getDirName(exptName);
            else
                fProps = varargin{1};
                imgExt = varargin{2};
                srtBy  = varargin{3};
                vis    = varargin{4};
                
                [obj.Images, ~] = getImageFiles(fProps, imgExt, srtBy, vis);
            end
            
            obj.TotalImages = numel(obj.Images);
        end
        
        function obj = AddSeedlingsFromRange(obj, rng, hypln)
            %% Function to extract Seedling objects from given set of frames
            % This function calls createMask on each image of this Genotype
            % 
            
            % Find raw seedlings from each frame in range
            frm = 1;      % Set first frame for first Seedling
            for i = rng
                findSeedlings(obj, obj.Images{i}, frm, obj.MASKSIZE, hypln);
                frm = frm + 1;
            end
            
        end
        
        function obj = SortSeedlings(obj)
            %% Align each Seedling and Filter out empty time points [obtain true lifetime]
            % Calls an assortment of helper functions that filter out empty frames
            % and align Seedling objects through frames
            filterSeedlings(obj, obj.RawSeedlings, size(obj.RawSeedlings,1));
            obj.NumberOfSeedlings = numel(obj.Seedlings);
        end
        
    end
    
    %% ------------------------- Helper Methods ---------------------------- %%
    
    methods (Access = public)
        %% Various helper functions
        function obj = setGenotypeName(obj, gn)
            %% Set name of Genotype
            obj.GenotypeName = gn;
        end
        
        function obj = storeImages(obj, I)
            %% Set ImageDataStore object containing paths to images
            obj.ImageStore = I;
        end
        
        function gn = getGenotypeName(obj)
            %% Return name of Genotype
            gn = obj.GenotypeName;
        end
        
        function rawImages = getAllImages(obj)
            %% Return all raw images
            rawImages = obj.Images;
        end
        
        function rawSeedlings = getAllRawSeedlings(obj)
            %% Return all unindexed seedlings
            rawSeedlings = obj.RawSeedlings;
        end
        
        function im = getImage(obj, num)
            %% Return single raw image at index
            try
                im = obj.Images{num};
            catch
                fprintf(2, 'No image at index %s \n', num);
            end
        end
        
        function sd = getRawSeedling(obj, num)
            %% Return single unindexed seedlings at index
            try
                sd = obj.RawSeedlings{num};
            catch
                fprintf(2, 'No RawSeedling at index %s \n', num);
            end
        end
        
        function s = getSeedling(obj, num)
            %% Returns indexed seedling at desired index
            try
                s = obj.Seedlings(num);
            catch
                fprintf(2, 'No Seedling at index %d \n', num);
            end
        end
        
    end
    
    %% ------------------------- Private Methods --------------------------- %%
    
    methods (Access = private)
        %% Helper methods
        function args = parseConstructorInput(varargin)
            %% Parse input parameters for Constructor method
            p = inputParser;
            p.addRequired('GenotypeName');
            p.addOptional('Parent', Experiment);
            p.addOptional('ParentName', '');
            p.addOptional('ParentPath', '');
            p.addOptional('TotalImages', 0);
            p.addOptional('NumberOfSeedlings', 0);
            p.addOptional('Images', {});
            p.addOptional('RawSeedlings', {});
            p.addOptional('Seedlings', Seedling);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
        function obj = findSeedlings(obj, im, frm, mskSz, hypln)
            %% Segmentation and Extraction of Seedling objects from raw image
            % This function binarizes a grayscale image at the given frame and
            % extracts features of a specified minimum size. Output is in the form
            % of a [m x n] cell array containing RawSeedling objects that represent
            % the total number of objects (m) for total frames (n).
            %
            % Input:
            %   obj: this Genotype object
            %   im: grayscale image containing growing seedlings
            %   frm: time point for Seedling's lifetime (not frame in time lapse)
            %   mskSz: min-max cutoff size for objects labelled as a Seedling
            %   hypln: length defining the distance to set lowest AnchorPoint 
            
            % Segmentation Method 2: inverted BW, filtering out small objects
            [dd, msk] = segmentObjectsHQ(im, mskSz);
            prp       = regionprops(dd, im, obj.PDPROPERTIES);
            
            % Crop grayscale/bw/contour image of RawSeedling
            imgs = arrayfun(@(x) imcrop(im, x.BoundingBox), prp, 'UniformOutput', 0);
            bws  = arrayfun(@(x) imcrop(msk, x.BoundingBox), prp, 'UniformOutput', 0);
            ctrs = cellfun(@(x) extractContour(x, obj.CONTOURSIZE), bws, 'UniformOutput', 0);
            
            % Create Seedling objects using data from bw mask
            for s = 1 : numel(prp)
                nm  = sprintf('Raw_%d', s);
                sdl = Seedling(nm, ...
                    'ParentName', obj.ParentName, ...
                    'ParentPath', obj.ParentPath, ...
                    'GenotypeName',   obj.GenotypeName,   ...
                    'PData',          prp(s));
                
                sdl.increaseLifetime;
                sdl.setFrame(frm, 'b');
                sdl.setCoordinates(1, prp(s).WeightedCentroid);
                sdl.setImage(1, 'gray', imgs{s});
                sdl.setImage(1, 'bw', imcomplement(bws{s}));
                sdl.setImage(1, 'ctr', ctrs{s});                                
                sdl.setAnchorPoints(1, bwAnchorPoints(sdl.getImage(1, 'bw'), hypln));
                obj.RawSeedlings{s,frm} = sdl;
            end
        end
        
        function obj = filterSeedlings(obj, rs, nSeeds)
            %% Filter out bad Seedling objects and frames
            % This function iterates through the inputted cell array to add only good Seedlings
            % Runs the algorithm for checking centroid coordinates of each Seedling to align correctly
            
            % Store all coordinates in 3-dim matrix
            rs       = empty2nan(rs, Seedling('empty', 'Coordinates', [nan nan]));
            crdsCell = cellfun(@(x) x.getCoordinates(1), rs, 'UniformOutput', 0);
            
            crdsMtrx = zeros(size(crdsCell,1), 2, size(crdsCell,2));
            for i = 1 : size(crdsCell, 2)
                crdsMtrx(:,:,i) = cat(1, crdsCell{:,i});
            end
            
            % Create empty Seedling array
            mkSdl = @(x) Seedling(sprintf('Seedling_{%s}', num2str(x)), ...
                'ParentName', obj.ParentName, ...
                'ParentPath', obj.ParentPath, ...
                'GenotypeName',   obj.GenotypeName);
            
            sdls = arrayfun(@(x) mkSdl(x), 1:nSeeds, 'UniformOutput', 0)';
            sdls = cat(1, sdls{:});
            
            % Align Seedling coordinates by closest matching RawSeedling at each frame
            sdlIdx = alignCoordinates(crdsMtrx, 1);
            
            for i = 1 : numel(sdls)
                sdl = sdls(i);
                idx = sdlIdx(i, :);
                for ii = 1 : length(idx)
                    t = rs{i,ii};
                    
                    if sdl.getLifetime == 1
                        sdl.setFrame(t.getFrame('b'), 'b');
                    else
                        sdl.setFrame(t.getFrame('b'), 'd');                        
                    end
                    
                    sdl.increaseLifetime;
                    sdl.setCoordinates(sdl.getLifetime, t.getCoordinates(1));
                    sdl.setImage(sdl.getLifetime, 'all', t.getImage);
                    sdl.setAnchorPoints(sdl.getLifetime, t.getAnchorPoints(1));
                    sdl.setPData(sdl.getLifetime, t.getPData);
                end
            end
            
            obj.Seedlings = sdls;
        end               
        
        %         function obj = alignSeedling(obj, fs, rs)
        %             %% Compare coordinates of Seedlings at frame and select closest match from previous frame
        %             % Input:
        %             %   fs  : current Seedling to sort
        %             %   rs  : cell array of all RawSeedlings at single frame
        %
        %
        %             % Check for available RawSeedlings to check at this frame
        %             vFrm(1:length(rs)) = true;
        %             UNAVAILABLE_MSG    = 'unavailable';
        %
        %             for i = 1:length(vFrm)
        %                 if isempty(rs{i})
        %                     vFrm(i) = false;
        %                     break;
        %                 elseif strcmp(rs{i}.SeedlingName, UNAVAILABLE_MSG)
        %                     vFrm(i) = false;
        %                 end
        %             end
        %
        %             if sum(vFrm) <= 0
        %                 %                 fprintf(2, 'No valid Seedlings at %s [%d, %d] \n', num2str(vFrm), frms(1), frms(2));
        %                 return;
        %             else
        %                 vIdx = find(vFrm == 1);
        %             end
        %
        %
        %             % Set Data from 1st available RawSeedling if aligning 1st frame
        %             UNAVAILABLE_MSG = 'unavailable';
        %             if fs.getLifetime == 0
        %                 fs.increaseLifetime(1);
        %                 fs.setCoordinates(fs.getLifetime, rs{vIdx(1)}.getCoordinates(1));
        %                 fs.setImageData(  fs.getLifetime, rs{vIdx(1)}.getImage(1));
        %                 fs.setPData(      fs.getLifetime, rs{vIdx(1)}.getPData(1));
        %                 fs.setFrame(rs{vIdx(1)}.getFrame('b'), 'b');
        %
        %                 % Mark RawSeedling as unavailable for next iterations
        %                 rs{vIdx(1)}.setSeedlingName(UNAVAILABLE_MSG);
        %
        %                 % Search coordinates of available index and find closest match
        %             else
        %                 closer_idx = compareCoords(fs.getCoordinates(fs.getLifetime), rs(vIdx));
        %
        %                 fs.increaseLifetime(1);
        %
        %                 % Only set data if closest Seedling is found
        %                 if ~isnan(closer_idx)
        %                     fs.setCoordinates(fs.getLifetime, rs{closer_idx}.getCoordinates(1));
        %                     fs.setImageData(  fs.getLifetime, rs{closer_idx}.getImage(1));
        %                     fs.setPData(      fs.getLifetime, rs{vIdx(1)}.getPData(1));
        %                     fs.setFrame(rs{closer_idx}.getFrame('b'), 'd');
        %
        %                     % Mark RawSeedling as unavailable for next iterations
        %                     rs{closer_idx}.setSeedlingName(UNAVAILABLE_MSG);
        %                 end
        %             end
        %
        %         end
    end
end


