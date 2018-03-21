%% Genotype: class for storing a single image stack from an Experiment
% This is largely a placeholder class for the real program

classdef Genotype < handle
    properties (Access = public)
        %% What data should this have?
        ExperimentName
        ExperimentPath
        GenotypeName
        TotalImages
        NumberOfSeedlings
    end
    
    properties (Access = private)
        %% Private data to hold
        RawImages
        RawSeedlings
        Seedlings
        CONTOURSIZE  = 800           % Number of points to normalize contours
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
                obj.GenotypeName = '';
            end
            
            
            
        end
        
        function obj = StackLoader(obj, varargin)
            %% Load raw images from directory
            % Load images from directory
            if nargin == 0
                [obj.RawImages, exptName] = getImageFiles;
                obj.GenotypeName          = getDirName(exptName);
            else
                fProps = varargin{1};
                imgExt = varargin{2};
                srtBy  = varargin{3};
                vis    = varargin{4};
                
                [obj.RawImages, ~] = getImageFiles(fProps, imgExt, srtBy, vis);
            end
            
            obj.TotalImages = numel(obj.RawImages);
        end
        
        function obj = AddSeedlingsFromRange(obj, rng)
            %% Function to extract Seedling objects from given set of frames
            % This function calls createMask on each image of this Genotype
            %
            % Find raw seedlings from each frame in range
            frm = 1;      % Set first frame for first Seedling
            for i = rng
                createMask(obj, obj.RawImages{i}, frm, obj.MASKSIZE);
                frm = frm + 1;
            end
            
        end
        
        function obj = SortSeedlings(obj)
            %% Align each Seedling and Filter out empty time points [obtain true lifetime]
            % Calls an assortment of helper functions that filter out empty frames
            % and align Seedling objects through frames
            filterSeedlings(obj, obj.RawSeedlings);
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
        
        function gn = getGenotypeName(obj)
            %% Return name of Genotype
            gn = obj.GenotypeName;
        end
        
        function rawImages = getAllRawImages(obj)
            %% Return all raw images
            rawImages = obj.RawImages;
        end
        
        function rawSeedlings = getAllRawSeedlings(obj)
            %% Return all unindexed seedlings
            rawSeedlings = obj.RawSeedlings;
        end
        
        function im = getRawImage(obj, imNum)
            %% Return single raw image
            try
                im = obj.RawImages{imNum};
            catch e
                fprintf(2, 'No RawImage at index %s \n', imNum);
                fprintf(2, '%s \n', e.getReport);
            end
        end
        
        function sd = getRawSeedling(obj, sdNum)
            %% Return single unindexed seedlings
            try
                sd = obj.RawSeedlings{sdNum};
            catch e
                fprintf(2, 'No RawSeedling at index %s \n', sdNum);
                fprintf(2, '%s \n', e.getReport);
            end
        end
        
        function s = getSeedling(obj, sIdx)
            %% Returns indexed seedling at desired index
            try
                s = obj.Seedlings(sIdx);
            catch e
                fprintf(2, 'No Seedling at index %d \n', sIdx);
                fprintf(2, '%s \n', e.getReport);
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
            p.addOptional('ExperimentName', '');
            p.addOptional('ExperimentPath', '');
            p.addOptional('TotalImages', 0);
            p.addOptional('NumberOfSeedlings', 0);
            p.addOptional('RawImages', {});
            p.addOptional('RawSeedlings', {});
            p.addOptional('Seedlings', Seedling);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
        function obj = createMask(obj, im, frm, mskSz)
            %% Segmentation and Extraction of Seedling objects from raw image
            % This function binarizes a grayscale image at the given frame and
            % extracts features of a specified minimum size. Output is in the form
            % of a [m x n] cell array containing RawSeedling objects that represent
            % the total number of objects (m) for total frames (n).
            %
            % Input:
            %   obj: this Genotype object
            %   im: grayscale image containing growing seedlings
            %   frm: time point in a stack of images
            %   mskSz: min-max cutoff size for objects labelled as a Seedling
            
            %% Old Method
            %             % Segmentation Method 2: inverted BW, filtering out small objects
            %             msk = imbinarize(im, 'adaptive', 'Sensitivity', 0.7, 'ForegroundPolarity', 'bright');
            %             flt = bwareafilt(imcomplement(msk), mskSz);
            %             dd  = bwconncomp(flt);
            %
            %             % Find objects in BW image
            %             p   = {'Area', 'BoundingBox', 'PixelList', 'Image', 'WeightedCentroid', 'Orientation'};
            %             prp = regionprops(dd, im, p);
            %
            %             % Get grayscale/binary/skeleton image and coordinates of a RawSeedling
            %             for i = 1:length(prp)
            %                 gray_im                  = imcrop(im, prp(i).BoundingBox);
            %                 skel_im                  = zeros(0,0);
            %                 obj.RawSeedlings{i, frm} = Seedling(obj.ExperimentName,   ...
            %                     obj.GenotypeName,     ...
            %                     sprintf('Raw_%d', i), ...
            %                     gray_im,              ...
            %                     double(prp(i).Image), ...
            %                     skel_im);
            %                 obj.RawSeedlings{i, frm}.setCoordinates(1, prp(i).WeightedCentroid);
            %                 obj.RawSeedlings{i, frm}.setPData(1, prp(i));
            %                 obj.RawSeedlings{i, frm}.setFrame(frm, 'b');
            %             end
            
            %% New Method
            % Segmentation Method 2: inverted BW, filtering out small objects
            [dd, msk] = segmentObjectsHQ(im, mskSz);
            
            % Find objects in BW image            
            prp = regionprops(dd, im, obj.PDPROPERTIES);
            
            % Crop grayscale/bw/contour image and coordinates of RawSeedling
            grays = arrayfun(@(x) imcrop(im, x.BoundingBox), prp, 'UniformOutput', 0);
            bws   = arrayfun(@(x) imcrop(msk, x.BoundingBox), prp, 'UniformOutput', 0);
            cntrs = cellfun(@(x) extractContour(x, obj.CONTOURSIZE), bws, 'UniformOutput', 0);
            
            % Create Seedling objects using data from mask
            for idx = 1 : numel(prp)
                nm = sprintf('Raw_%d', idx);
                obj.RawSeedlings{idx, frm} = Seedling(nm,   ...
                    'ExperimentName', obj.ExperimentName, ...
                    'ExperimentPath', obj.ExperimentPath, ...
                    'GenotypeName', obj.GenotypeName,     ...
                    'gray', grays{idx},                     ...
                    'bw', bws{idx},                         ...
                    'cntr', cntrs{idx});
                
                %% STOPPED HERE 03/18/2018 [error setting PData]
                obj.RawSeedlings{idx, frm}.setCoordinates(1, prp(idx).WeightedCentroid);
                obj.RawSeedlings{idx, frm}.setPData(1, prp(idx)); ries
                obj.RawSeedlings{idx, frm}.setFrame(frm, 'b');
            end
            
        end
        
        function obj = filterSeedlings(obj, rawSeedlings)
            %% Filter out bad Seedling objects and frames
            % This function iterates through the inputted cell array to add only good Seedlings
            % Runs the algorithm for checking centroid coordinates of each Seedling to align correctly
            
            % Create Seedling
            for i = 1 : size(rawSeedlings, 1)
                if numel(obj.Seedlings) == 0
                    obj.Seedlings   = Seedling(obj.ExperimentName, ...
                        obj.GenotypeName,   ...
                        num2str(i));
                else
                    obj.Seedlings(i) = Seedling(obj.ExperimentName, ...
                        obj.GenotypeName,   ...
                        num2str(i));
                end
            end
            
            
            for sdl = 1 : numel(obj.Seedlings)
                for frm = 1 : size(rawSeedlings, 2)
                    toCheck = rawSeedlings(:, frm);
                    alignSeedling(obj, obj.Seedlings(sdl), toCheck, [sdl ii]);
                end
            end
            
        end
        
        function obj = alignSeedling(obj, fs, rs, frms)
            %% Compare coordinates of Seedlings at frame and select closest match from previous frame
            % Input:
            %   fs  : current Seedling to sort
            %   rs  : cell array of all RawSeedlings at single frame
            %   frms: indeces for frame and raw seedling index
            
            % Check for available RawSeedlings to check at this frame
            vFrm(1:length(rs)) = true;
            UNAVAILABLE_MSG    = 'unavailable';
            
            for i = 1:length(vFrm)
                if isempty(rs{i})
                    vFrm(i) = false;
                    break;
                elseif strcmp(rs{i}.SeedlingName, UNAVAILABLE_MSG)
                    vFrm(i) = false;
                end
            end
            
            if sum(vFrm) <= 0
                %                 fprintf(2, 'No valid Seedlings at %s [%d, %d] \n', num2str(vFrm), frms(1), frms(2));
                return;
            else
                vIdx = find(vFrm == 1);
            end
            
            
            % Set Data from 1st available RawSeedling if aligning 1st frame
            if fs.getLifetime == 0
                fs.increaseLifetime(1);
                fs.setCoordinates(fs.getLifetime, rs{vIdx(1)}.getCoordinates(1));
                fs.setImageData(  fs.getLifetime, rs{vIdx(1)}.getImageData(1));
                fs.setPData(      fs.getLifetime, rs{vIdx(1)}.getPData(1));
                fs.setFrame(rs{vIdx(1)}.getFrame('b'), 'b');
                
                % Mark RawSeedling as unavailable for next iterations
                rs{vIdx(1)}.setSeedlingName(UNAVAILABLE_MSG);
                
                % Search coordinates of available index and find closest match
            else
                closer_idx = compareCoords(fs.getCoordinates(fs.getLifetime), rs(vIdx));
                
                fs.increaseLifetime(1);
                
                if ~isnan(closer_idx)
                    fs.setCoordinates(fs.getLifetime, rs{closer_idx}.getCoordinates(1));
                    fs.setImageData(  fs.getLifetime, rs{closer_idx}.getImageData(1));
                    fs.setPData(      fs.getLifetime, rs{vIdx(1)}.getPData(1));
                    fs.setFrame(rs{closer_idx}.getFrame('b'), 'd');
                    
                    % Mark RawSeedling as unavailable for next iterations
                    rs{closer_idx}.setSeedlingName(UNAVAILABLE_MSG);
                end
            end
            
        end
    end
end




