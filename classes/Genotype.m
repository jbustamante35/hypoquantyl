%% Genotype: class for storing a single image stack from an Experiment

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
        CONTOURSIZE  = 200            % Number of points to normalize Seedling contours
        MASKSIZE     = [10000 100000]  % Cut-off area for objects in image
        PDPROPERTIES = {'Area', 'BoundingBox', 'PixelList', 'Centroid', 'WeightedCentroid', 'Orientation'};
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
        
        function newSdls = FindSeedlings(obj, rng, hypln, v)
            %% Function to extract Seedling objects from a range of frames
            % This function searches the large grayscale image for what is
            % expected to be Seedling objects. The threshold size of the
            % Seedling is set by the MASKSIZE property.
            
            if v
                t = tic;
                fprintf('Extracting Seedlings from %s\n', obj.GenotypeName);
            end
            
            if rng(end) > obj.TotalImages || isequal(rng, 0)
                rng = 1 : obj.TotalImages;
            end
            
            % Find raw seedlings from each frame in range
            sdls = cell(1, numel(rng));
            frm  = 1; % Set first frame for first Seedling
            for r = rng
                img     = obj.getImage(r);
                sdls{r} = extractSeedlings(obj, img, ...
                    frm, obj.MASKSIZE, hypln);
                frm     = frm + 1;
                
                if v
                    %                     n = obj.getAllRawSeedlings;
                    nSdls = numel(sdls{r});
                    tSdls = sum(cellfun(@numel, sdls));
                    fprintf('[%.02f sec] (%s) Extracted %d Seedlings from %d of %d frames [%d total]\n', ...
                        toc(t), obj.GenotypeName, nSdls, r, rng(end), tSdls);
                end
            end
            
            % Create new cell array of Seedlings with empty cells
            maxSdls = max(cellfun(@numel, sdls));
            newSdls = cell(numel(sdls), maxSdls);
            
            % Fill cells with Seedlings
            for r = 1 : numel(sdls)
                newSdls(r, 1:numel(sdls{r})) = sdls{r};
            end
            
            % Store all found seedlings in RawSeedlings property
            obj.RawSeedlings = newSdls;
            
        end
        
        function sdls = SortSeedlings(obj)
            %% Align Seedlings and filter out bad frames
            % Aligns each Seedling by their centroid coordinate and then filters
            % out empty time points [to obtain true lifetime]. This function
            % calls an assortment of helper functions that filters out empty
            % frames and aligns Seedling objects through subsequent frames.
            sdls = obj.filterSeedlings( ...
                obj.RawSeedlings, size(obj.RawSeedlings,2));
            obj.NumberOfSeedlings = numel(sdls);
            arrayfun(@(x) x.RemoveBadFrames, sdls, 'UniformOutput', 0);
        end
        
        function obj = PruneSeedlings(obj)
            %% Remove RawSeedlings to decrease size of data object
            obj.RawSeedlings = [];
        end
        
        
        function hyps = FindHypocotylAllSeedlings(obj, v)
            %% Extract Hypocotyl from all Seedlings from this Genotype
            try
                if v
                    fprintf('Extracting Hypocotyls from %s\n', ...
                        obj.GenotypeName);
                    tic;
                end
                
                sdls = obj.Seedlings;
                hyps = arrayfun(@(x) x.FindHypocotylAllFrames(v), ...
                    sdls, 'UniformOutput', 0);
                hyps = arrayfun(@(x) x.SortPreHypocotyls, sdls, 'UniformOutput', 0);
                
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
        
        function DerefParents(obj)
            %% Remove reference to Parent property
            obj.Parent = [];
        end
        
        function RefChild(obj)
            %% Set reference back to Children [ after use of DerefParents ]
            arrayfun(@(x) x.setParent(obj), obj.Seedlings, 'UniformOutput', 0);
            
        end
        
        function fout = ChangeStorePaths(obj, p)
            %% Change base path of each ImageDataStore file
            % I'm an idiot and changed the directory to the base data, and it
            % messed up the entire dataset. This should allow flexibility in
            % the path to data.
            
            try
                % Set new experiment name and path
                obj.ExperimentPath = char(p);
                obj.ExperimentName = getDirName(p);
                
                % Iterate through ImageStore Files to change paths
                fin = obj.ImageStore.Files;
                enm = obj.ExperimentName;
                
                fout = cell(numel(fin), 1);
                for f = 1 : numel(fin)
                    fIdx    = strfind(fin{f}, enm) + length(enm);
                    fPath   = fin{f}(fIdx:end);
                    fout{f} = [p, fPath];
                    
                    % Set new path to file in ImageDataStore
                    obj.ImageStore.Files{f} = fout{f};
                end
                
            catch e
                fprintf(2, 'Error setting new path %s\n%s\n', p, e.message);
            end
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
            obj.ImageStore  = I;
            obj.TotalImages = I.numpartitions;
        end
        
        function imgs = getAllImages(obj)
            %% Return all raw images in a cell array
            imgs = obj.ImageStore.readall;
        end
        
        function rs = getAllRawSeedlings(obj)
            %% Return all unindexed seedlings
            rs = obj.RawSeedlings;
        end
        
        function img = getImage(varargin)
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
                    img = obj.ImageStore.readall;
                    
                case 2
                    % Grayscale image at index [can be a range of images]
                    idx = varargin{2};
                    try
                        img = searchImageStore(obj.ImageStore, idx);
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
                                img = imgs;
                                
                            case 'bw'
                                if iscell(imgs)
                                    [~, img] = cellfun(@(x) ...
                                        segmentObjectsHQ(x, obj.MASKSIZE, ...
                                        [], 2), imgs, 'UniformOutput', 0);
                                else
                                    [~, img] = ...
                                        segmentObjectsHQ( ...
                                        imgs, obj.MASKSIZE, [], 2);
                                end
                                
                            otherwise
                                fprintf(2, 'Error requesting %s image\n', req);
                                img = [];
                        end
                    catch
                        fprintf(2, 'No image(s) at index/range %s \n', idx);
                        img = [];
                    end
                    
                otherwise
                    fprintf(2, 'Error returning images\n');
                    img = [];
            end
            
        end
        
        function obj = setAutoSeedlings(obj)
            %% Manually set a Hypocotyl child object at a given frame
            % This crops out this Seedling's image and resizes it to the desired
            % patch size for Hypocotyl objects (see SCALESIZE property).
            
            % Extract and process contour from image
            imgs  = cellfun(@(x) double(x), ...
                obj.getImage, 'UniformOutput', 0);
            tot   = numel(imgs);
            frms  = num2cell(1:tot)';
            
            % Segment objects using simple binarization
            pdps  = obj.PDPROPERTIES;
            %             prps  = cellfun(@(i) segmentObjectsHQ(imcomplement(i), pdps, [], 1), ...
            %                 imgs, 'UniformOutput', 0);
            % Might have problems at this line
            prps  = cellfun(@(i) segmentObjectsHQ(imcomplement(i), pdps), ...
                imgs, 'UniformOutput', 0);
            crds  = cellfun(@(x) x.Centroid, prps, 'UniformOutput', 0);
            
            % Set data for Seedling object
            sdl = Seedling('Parent', obj);
            sdl.setParent(obj);
            sdl.setSeedlingName('Seedling_{1}');
            sdl.setFrame(1, 'b');
            sdl.setFrame(tot, 'd');
            sdl.increaseLifetime(tot);
            sdl.setPData(frms, prps);
            sdl.setCoordinates(frms, crds);
            
            obj.Seedlings         = sdl;
            obj.NumberOfSeedlings = numel(sdl);
            
        end
        
        function obj = setParent(obj, p)
            %% Set Experiment parent
            obj.Parent = p;
            obj.ExperimentName = p.ExperimentName;
            obj.ExperimentPath = p.ExperimentPath;
        end
        
        function setRawSeedlings(obj, sdls)
            %% Set RawSeedling property
            obj.RawSeedlings = sdls;
        end
        
        function sd = getRawSeedling(obj, num)
            %% Return single unindexed seedlings at index
            try
                sd = obj.RawSeedlings{num};
            catch
                fprintf(2, 'No RawSeedling at index %d \n', num);
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
        
        function [s, i] = search4Seedling(obj, nm)
            %% Return specific Seedling by SeedlingName and index
            sdls = obj.getSeedling(':');
            
            for i = 1 : numel(sdls)
                mtc = sdls(i).SeedlingName;
                if isequal(nm, mtc)
                    s = sdls(i);
                    return;
                end
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
        
        function sdls = extractSeedlings(obj, img, frm, mskSz, hypln)
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
            %             [dd, msk] = segmentObjectsHQ(imcomplement(img), mskSz);
            [dd, msk] = segmentObjectsHQ(img, mskSz);
            prp       = regionprops(dd, img, obj.PDPROPERTIES);
            numSdls   = numel(prp);
            
            % Crop grayscale/bw/contour image of RawSeedling
            bws  = arrayfun(@(x) imcrop(msk, x.BoundingBox), ...
                prp, 'UniformOutput', 0);
            ctrs = cellfun(@(x) extractContour(x, obj.CONTOURSIZE), ...
                bws, 'UniformOutput', 0);
            
            % Create Seedling objects using data from bw mask and contour
            sdls = cell(1, numSdls);
            for s = 1 : numSdls
                nm  = sprintf('Raw_%d', s);
                sdl = Seedling(nm, 'PData', prp(s), 'Contour', ctrs{s});
                sdl.setParent(obj);
                ctrs{s}.setParent(sdl);
                sdl.increaseLifetime;
                sdl.setFrame(frm, 'b');
                
                if ~all(isnan(prp(s).WeightedCentroid))
                    sdl.setCoordinates(1, prp(s).WeightedCentroid);
                else
                    sdl.setCoordinates(1, prp(s).Centroid);
                end
                
                sdl.setAnchorPoints(1, ...
                    bwAnchorPoints(sdl.getImage(1, 'bw'), hypln));
                sdls{s} = sdl;
                %                 obj.RawSeedlings{s,frm} = sdl;
            end
        end
        
        function sdls = filterSeedlings(obj, rs, nSeeds)
            %% Filter out bad Seedling objects and frames
            % This function iterates through the inputted cell array of
            % RawSeedlings to add only good Seedling objects into this
            % Genotype's Seedlings property.
            %
            % Specifically, it runs the algorithm for checking centroid
            % coordinates of each Seedling to align each Seedling correctly,
            % based on matching centroid coordinates.
            %
            
            % Store all coordinates in 3-dim matrix
            rs       = ...
                empty2nan(rs, Seedling('empty', 'Coordinates', [nan nan]));
            crdsCell = ...
                cellfun(@(x) x.getCoordinates(1), rs, 'UniformOutput', 0);
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
            crdsMtrx = permute(crdsMtrx, [3 2 1]);
            sdlIdx   = alignCoordinates(crdsMtrx, 1);
            
            %% Add child Seedlings to this Genotype parent
            for i = 1 : numel(sdls)
                sdl = sdls(i);
                idx = sdlIdx(i,:);
                for ii = 1 : length(idx)
                    t = rs{ii,i};
                    
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
        
    end
end


