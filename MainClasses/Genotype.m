%% Genotype: class for storing a single image stack from an Experiment 
% This is largely a placeholder class for the real program

classdef Genotype < handle
    properties (Access = public)
    %% What data should this have?
        ExperimentName
        GenotypeName
        TotalImages
        Seedlings        
    end
    
    properties (Access = private)
    %% Private data to hold
        RawImages
        RawSeedlings
    end
    
    methods (Access = public)
    %% Constructor and main methods
        function obj = Genotype(experiment)
        %% Default constructor to initialize new program
            obj.ExperimentName = experiment;
            obj.GenotypeName   = '';
            obj.TotalImages    = 0;
            obj.RawImages      = cell(0);
        end

        function obj = StackLoader(obj)
        %% Load raw images from directory 
            [obj.RawImages, exptName] = getImageFiles;          
            obj.GenotypeName          = getDirName(exptName);
            obj.Seedlings             = cell(0);
            obj.TotalImages           = numel(obj.RawImages);
        end  
    
        function obj = AddSeedlingsFromRange(obj, rng)
        %% Function to extract Seedling objects from given set of frames
        % This function calls createMask on each image of this Genotype
        % 
        % Find raw seedlings from each frame in range
            frm      = 1;
            min_area = 6000;   % Minimum cut-off area for objects found in image 
            max_area = 100000; % Minimum cut-off area for objects found in image 
            for i = rng
                createMask(obj, obj.RawImages{i}, frm, min_area, max_area);
                frm = frm + 1;
            end

        end
        
        function obj = SortSeedlings(obj)
        %% Align each Seedling and Filter out empty time points [true lifetime]
        % Calls an assortment of helper functions that filter out empty frames
        % and align Seedling objects through frames
            filterSeedlings(obj, obj.RawSeedlings);
        end        
        
    end
    
    
    methods (Access = public)
    %% Various helper functions
        function im = getRawImage(obj, imNum)
            im = obj.RawImages{imNum};
        end
        
        function rawImages = getRawImages(obj)
            rawImages = obj.RawImages;
        end
        
        function rawSeedlings = getRawSeedlings(obj)
            rawSeedlings = obj.RawSeedlings;
        end                   
        
    end
    
    methods (Access = private)
    %% Helper methods
        function obj = createMask(obj, im, frm, minAr, maxAr)
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
        %   min_area: minimum cutoff size for objects labelled as a Seedling

            im_msk = imbinarize(im, 'adaptive', 'Sensitivity', 0.7, 'ForegroundPolarity', 'bright');
                    
            % Segmentation Method 2: inverted BW, filtering out small objects
            flt = bwareafilt(imcomplement(im_msk), [minAr maxAr]);
            dd  = bwconncomp(flt);
            p   = {'Area', 'BoundingBox', 'Image', 'WeightedCentroid', 'Orientation'};
            prp = regionprops(dd, im, p);

            % Get grayscale/binary/skeleton image and coordinates of a RawSeedling
            for i = 1:length(prp)
                gry                      = imcrop(im, prp(i).BoundingBox);
                skl                      = bwmorph(prp(i).Image, 'skel', inf);                
                obj.RawSeedlings{i, frm} = Seedling(obj.ExperimentName,        ...
                                                    obj.GenotypeName,          ...
                                                    sprintf('Raw_%d', i),      ...
                                                    gry,                       ...
                                                    double(prp(i).Image), ...
                                                    skl);
                obj.RawSeedlings{i, frm}.setCoordinates(1, prp(i).WeightedCentroid);
                obj.RawSeedlings{i, frm}.setFrame(frm, 'b');
            end
            
            % Create Hypocotyl objects from filtered objects            
        end
        
        function obj = filterSeedlings(obj, rawSeedlings)
        %% Filter out bad Seedling objects and frames
        % This function iterates through the inputted cell array to add only good Seedlings
        % Runs the algorithm for checking centroid coordinates of each Seedling to align correctly
            for i = 1:size(rawSeedlings, 1)
                obj.Seedlings{i, 1} = Seedling(obj.ExperimentName, ...
                                            obj.GenotypeName,   ...
                                            num2str(i));
            end
            
            for i = 1:numel(obj.Seedlings)
                for ii = 1:size(rawSeedlings, 2)
                    toCheck = rawSeedlings(:, ii);                    
                    alignSeedling(obj, obj.Seedlings{i}, toCheck, [i ii]);
%                     fprintf('Seedling %d, Frame %d \n', i, ii);
                end
            end
            
        end
        
        function obj = alignSeedling(obj, fs, rs, frms)
        %% Compare coordinates of Seedlings at frame and select closest match from previous frame
        % Input:
        %   fs: current single Seedling to sort
        %   rs: all RawSeedlings at single frame
        
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
                fprintf(2, 'No valid Seedlings at %s [%d, %d] \n', num2str(vFrm), frms(1), frms(2));
                return; 
            else
                vIdx = find(vFrm == 1); 
            end                

        % Set Data from 1st available RawSeedling if aligning 1st frame
            
            if fs.getLifetime == 0                
                fs.increaseLifetime(1);
                fs.setCoordinates(fs.getLifetime, rs{vIdx(1)}.getCoordinates(1));
                fs.setImageData(  fs.getLifetime, rs{vIdx(1)}.getImageData(1));
                fs.setFrame(rs{vIdx(1)}.getFrame('b'), 'b');
                
            % Mark RawSeedling as unavailable for next iterations
                rs{vIdx(1)}.setSeedlingName(UNAVAILABLE_MSG);
                
        % Search coordinates of available index and find closest match         
            else
                closer_idx = compareCoords(obj, fs.getCoordinates(fs.getLifetime), rs(vIdx));
                
                fs.increaseLifetime(1);
                fs.setCoordinates(fs.getLifetime, rs{closer_idx}.getCoordinates(1));
                fs.setImageData(  fs.getLifetime, rs{closer_idx}.getImageData(1));       
                fs.setFrame(rs{closer_idx}.getFrame('b'), 'd');
            
            % Mark RawSeedling as unavailable for next iterations
                rs{closer_idx}.setSeedlingName(UNAVAILABLE_MSG);
            end

        end
        
        function minDistIdx = compareCoords(obj, pf,  cf)
        %% Compare coordinates of previous frame with current frame
        % If coordinates are within set error percent, it is added to the
        % next frame of the Seedling. Otherwise the frame is skipped. 
        % pf: coordinates of previous frame for current Seedling
        % cf: frame of Seedlings currently comparing to pf
        % d : Euclidean distances between pf and cf
        % minDistIdx: Seedling index where input coordinate is closest 
        
            if length(cf) > 1
                d = cell(1, length(cf));
                
                for i = 1:length(cf)
                    d{i} = pdist([pf; cf{i}.getCoordinates(1)]);
                end
                                
                x = cat(1, d{:});
                m = x == min(x(:));                
                n = char(cf{m}.getSeedlingName);
                
            else                                
                n = char(cf{1}.getSeedlingName);                
            end
            
            % Return Seedling name to determine which data to extract 
            minDistIdx = str2double(n(end));                
        
        end
    end
end




