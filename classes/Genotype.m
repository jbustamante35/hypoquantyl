%% Genotype: class for storing a single image stack from an Experiment
% This is largely a placeholder class for the real program

classdef Genotype < handle
    properties (Access = public)
        %% What data should this have?
        Parent
        ExperimentName
        ExperimentPath
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
        CONTOURSIZE  = 2000           % Number of points to normalize Seedling contours
        MASKSIZE     = [1000 100000]  % Cut-off area for objects in image
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
            end
            
        end
        
        %         function obj = StackLoader(obj, varargin)
        %             %% Load raw images from directory
        %             % Load images from directory
        %             if nargin == 0
        %                 [obj.Images, exptName] = getImageFiles;
        %                 obj.GenotypeName       = getDirName(exptName);
        %             else
        %                 fProps = varargin{1};
        %                 imgExt = varargin{2};
        %                 srtBy  = varargin{3};
        %                 vis    = varargin{4};
        %
        %                 [obj.Images, ~] = getImageFiles(fProps, imgExt, srtBy, vis);
        %             end
        %
        %             obj.TotalImages = numel(obj.Images);
        %         end
        
        function obj = FindSeedlings(obj, rng, hypln, v)
            %% Function to extract Seedling objects from a range of frames
            % This function searches the large grayscale image for what is 
            % expected to be Seedling objects. The threshold size of the 
            % Seedling is set by the MASKSIZE property.

            if v
                tic;
                fprintf('Extracting Seedlings from %s\n', obj.GenotypeName);
            end
            
            % Find raw seedlings from each frame in range
            frm = 1;      % Set first frame for first Seedling
            for r = rng
                extractSeedlings(obj, obj.getImage(r), ...
                	frm, obj.MASKSIZE, hypln);
                frm = frm + 1;

                if v
                    n = obj.getAllRawSeedlings;
                    fprintf('[%.02f sec] (%s) Extracted %d Seedlings from %d frames [+ %d]\n', ...
                    	toc, obj.GenotypeName, numel(n), r, size(n,1));
                end
            end
            
        end
        
        function obj = FindHypocotylAllSeedlings(obj, v)
            %% Extract Hypocotyl from all Seedlings from this Genotype

            
            try
            	if v
            	    fprintf('Extracting Hypocotyls from %s\n', ...
                    	obj.GenotypeName);
            	    tic;
            	end

                sdls = obj.Seedlings;
            	arrayfun(@(x) x.FindHypocotylAllFrames(v), ...
                	sdls, 'UniformOutput', 0);

            	if v
            	    fprintf('[%.02f sec] Extracted Hypocotyls from %s\n', ...
                    	toc, obj.GenotypeName);
            	end

            catch e
                fprintf(2, 'Error extracting Hypocotyl from %s\n%s\n', ...
                	obj.GenotypeName, e.getReport);

            	if v
            	    fprintf('[%.02f sec] %s\n', toc);
            	end
            end

        end

        function obj = SortSeedlings(obj)
            %% Align each Seedling by their centroid coordinate and then Filter 
            % out empty time points [to obtain true lifetime]. This function 
            % calls an assortment of helper functions that filters out empty 
            % frames and aligns Seedling objects through subsequent frames.
            filterSeedlings(obj, obj.RawSeedlings, size(obj.RawSeedlings, 1));
            obj.NumberOfSeedlings = numel(obj.Seedlings);
            arrayfun(@(x) x.RemoveBadFrames, obj.Seedlings, 'UniformOutput', 0);
        end

        function obj = PruneSeedlings(obj)
            %% Remove RawSeedlings to decrease data
            obj.RawSeedlings = [];
        end

        function DerefParents(obj)
            %% Remove reference to Parent property
            obj.Parent = [];
        end
    
        function obj = RefChild(obj)
            %% Set reference back to Children [ after use of DerefParents ]
            arrayfun(@(x) x.setParent(obj), obj.Seedlings, 'UniformOutput', 0); 
    
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
            obj.TotalImages = I.numpartitions;
        end
        
        function rawImages = getAllImages(obj)
            %% Return all raw images in a cell array
            %             rawImages = obj.Images;
            rawImages = obj.ImageStore.readall;
        end
        
        function rawSeedlings = getAllRawSeedlings(obj)
            %% Return all unindexed seedlings
            rawSeedlings = obj.RawSeedlings;
        end
        
        function im = getImage(varargin)
            %% Return requested image at index
            % This function draws from the ImageStore property that contains an
            % ImageDataStore to read an image into memory from it's path name. 
            % 
            % This gives a significant improvement over my original method of
            % reading from the path name and writing the data to memory. This
            % made the image processing pipeline very slow, and created 
            % very large objects and data output [ .mat ] files.
            obj = varargin{1};
            
            switch nargin
                case 1
                    % All grayscale images from this object
                    im = obj.ImageStore.readall;
                    
                case 2
                    % Grayscale image at index [can be a range of images]
                    idx = varargin{2};
                    try
                        im = searchImageStore(obj.ImageStore, idx);
                    catch
                        fprintf(2, 'No image(s) at index/range %s \n', idx);
                    end
                    
                case 3
                    % Requested image type at index or range
                    idx = varargin{2};
                    req = varargin{3};
                    
                    try
                        imgs = searchImageStore(obj.ImageStore, idx);
                        
                        switch req
                            case 'gray'
                                im = imgs;
                                
                            case 'bw'
                                if iscell(imgs)
                                    [~, im] = cellfun(@(x) ...
                                    	segmentObjectsHQ(x, obj.MASKSIZE),...
                                        imgs, 'UniformOutput', 0);
                                else
                                    [~, im] = ...
                                    	segmentObjectsHQ(imgs, obj.MASKSIZE);
                                end
                                
                            otherwise
                                fprintf(2, 'Error requesting %s image\n', req);
                        end
                    catch
                        fprintf(2, 'No image(s) at index/range %s \n', idx);
                        im = [];
                    end
                    
                otherwise
                    fprintf(2, 'Error returning images\n');
                    im = [];
            end
            
        end
        
        function obj = setParent(obj, p)
            %% Set Experiment parent 
            obj.Parent = p;
            obj.ExperimentName = p.ExperimentName;
            obj.ExperimentPath = p.ExperimentPath;
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
        
        function prp = getProperty(obj, req)
            %% Returns a property of this Genotype object
            try
                prp = obj.(req);
            catch e
                fprintf(2, 'Property %s does not exist\n%s\n', ...
                    req, e.message);
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
            p.addOptional('Parent', []);
            p.addOptional('ExperimentName', '');
            p.addOptional('ExperimentPath', '');
            p.addOptional('TotalImages', 0);
            p.addOptional('NumberOfSeedlings', 0);
            p.addOptional('Images', {});
            p.addOptional('RawSeedlings', {});
            p.addOptional('Seedlings', Seedling);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
        function obj = extractSeedlings(obj, im, frm, mskSz, hypln)
            %% Segmentation and Extraction of Seedling objects from raw image
            % This function binarizes a grayscale image at the given frame and
            % extracts features of a specified minimum size. Output is in the 
            % form of an [m x n] cell array containing RawSeedling objects that 
            % represent the total number of objects (m) for total frames (n).
            %
            % Input:
            %   obj: this Genotype object
            %   im: grayscale image containing growing seedlings
            %   frm: time point for Seedling's lifetime (NOT frame)
            %   mskSz: min-max cutoff size for objects labelled as a Seedling
            %   hypln: distance at bottom of image to set cutoff for Hypocotyl
            
            % Segmentation with Otsu method and the inverted BW image, then
            % filter out small objects [ defined by mskSz parameter ].
            [dd, msk] = segmentObjectsHQ(im, mskSz);
            prp       = regionprops(dd, im, obj.PDPROPERTIES);
            
            % Crop grayscale/bw/contour image of RawSeedling
            bws  = arrayfun(@(x) imcrop(msk, x.BoundingBox), ...
            	prp, 'UniformOutput', 0);
            ctrs = cellfun(@(x) extractContour(x, obj.CONTOURSIZE), ...
            	bws, 'UniformOutput', 0);
            
            % Create Seedling objects using data from bw mask and contour
            for s = 1 : numel(prp)
                nm  = sprintf('Raw_%d', s);
                sdl = Seedling(nm, 'PData', prp(s), 'Contour', ctrs{s});
                sdl.setParent(obj);
                ctrs{s}.setParent(sdl);
                sdl.increaseLifetime;
                sdl.setFrame(frm, 'b');
                sdl.setCoordinates(1, prp(s).WeightedCentroid);
                sdl.setAnchorPoints(1, ...
                	bwAnchorPoints(sdl.getImage(1, 'bw'), hypln));
                obj.RawSeedlings{s,frm} = sdl;
            end
        end
        
        function obj = filterSeedlings(obj, rs, nSeeds)
            %% Filter out bad Seedling objects and frames
            % This function iterates through the inputted cell array of 
            % RawSeedlings to add only good Seedling objects into this 
            % Genotype's Seedlings property.
            %
            % Specifically, it runs the algorithm for checking centroid 
            % coordinates of each Seedling to align each Seedling correctly, 
            % based on matching centroid coordinates. 
            
            % Store all coordinates in 3-dim matrix
            rs       = empty2nan(rs, ...
            	Seedling('empty', 'Coordinates', [nan nan]));

            crdsCell = cellfun(@(x) x.getCoordinates(1), ...
            	rs, 'UniformOutput', 0);
            
            crdsMtrx = zeros(size(crdsCell, 1), 2, size(crdsCell, 2));
            for i = 1 : size(crdsCell, 2)
                crdsMtrx(:,:,i) = cat(1, crdsCell{:,i});
            end
            
            %% Create empty Seedling array
            mkSdl = @(x) Seedling(sprintf('Seedling_{%s}', num2str(x)));
            sdls  = arrayfun(@(x) mkSdl(x), 1:nSeeds, 'UniformOutput', 0)';
            sdls  = cat(1, sdls{:});
            
            %% Align Seedling coordinates by closest matching RawSeedling at 
            % each frame. 
            % TODO: implement collision detection --> combine collided objects
            %   1) colliding objects both should combine coordinates
            %   2) last indexed object is cut because colliding objects problem
            sdlIdx = alignCoordinates(crdsMtrx, 1);
            
            %% Add child Seedlings to this Genotype parent
            for i = 1 : numel(sdls)
                sdl = sdls(i);
                idx = sdlIdx(i, :);
                for ii = 1 : length(idx)
                    t = rs{i,ii};
                    
                    if sdl.getLifetime == 0
                        sdl.setFrame(t.getFrame('b'), 'b');
                    elseif sdl.getFrame('d') <= t.getFrame('b')
                        sdl.setFrame(t.getFrame('b'), 'd');
                    else
                        break;
                    end
                    
                    sdl.increaseLifetime;
                    sdl.setCoordinates(sdl.getLifetime, t.getCoordinates(1));
                    sdl.setAnchorPoints(sdl.getLifetime, t.getAnchorPoints(1));
                    sdl.setContour(sdl.getLifetime, t.getContour(1));
                    sdl.setPData(sdl.getLifetime, t.getPData);
                    sdl.setParent(obj);
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


