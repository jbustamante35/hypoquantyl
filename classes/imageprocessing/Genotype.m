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
        SegDefaults
        SDLBUFFER    = [0 , 0 , 0 , 0] % Seedling Bounding Box Buffer
        HYPBUFFER    = [0 , 0 , 0 , 0] % Hypocotyl Anchor Points Buffer
        BOPEN        = 400             % Filter out specks from bw images
        CONTOURSIZE  = 200             % Number of points to normalize Seedling contours
        MASKSIZE     = [1500 , 100000] % Cut-off area for objects in image
        %         PDPROPERTIES = {'Area', 'BoundingBox', 'PixelList', 'Centroid', 'WeightedCentroid', 'Orientation'};
        PDPROPERTIES = {'Area', 'BoundingBox', 'PixelList', 'WeightedCentroid', 'Orientation'};
    end

    %% ------------------------- Primary Methods ---------------------------- %%
    methods (Access = public)
        %% Constructor and main methods
        function obj = Genotype(varargin)
            %% Constructor method for Genotype
            if ~isempty(varargin)
                % Parse inputs to set properties
                vargs = varargin;
            else
                % Set default properties for empty object
                vargs = {};
            end

            prps   = properties(class(obj));
            deflts = {...
                'TotalImages', 0 ; ...
                'NumberOfSeedlings', 0};
            obj    = classInputParser(obj, prps, deflts, vargs);
        end

        function rawSdls = FindSeedlings(obj, rng, sdlsz, hypln, v)
            %% Function to extract Seedling objects from a range of frames
            % This function searches the large grayscale image for what is
            % expected to be Seedling objects. The threshold size of the
            % Seedling is set by the MASKSIZE property.
            if nargin < 2; rng   = 1 : obj.TotalImages;                       end % Range of images
            if nargin < 3; sdlsz = obj.Parent.getProperty('SEEDLINGSIZE');    end % Seedling area cutoff
            if nargin < 4; hypln = obj.Parent.getProperty('HYPOCOTYLLENGTH'); end % Hypocotyl cutoff length
            if nargin < 5; v     = 1;                                         end % Verbosity

            if v
                t = tic;
                [~ , sprA , sprB] = jprintf(' ', 0, 0, 80);
                gnm               = obj.GenotypeName;
                [~ , gidx]        = obj.Parent.search4Genotype(gnm);
                ngen              = obj.Parent.NumberOfGenotypes;
                fprintf('\n%s\nExtracting Seedlings from %s [Genotype %02d of %02d]\n%s\n', ...
                    sprA, gnm, gidx, ngen, sprB);
            end

            if numel(rng) > 1
                if rng(end) > obj.TotalImages || isequal(rng, 0)
                    rng = 1 : obj.TotalImages;
                end
            end

            % Find raw seedlings from each frame in range
            sdls = cell(1, numel(rng));
            frm  = rng(1); % Set to any frame [09.17.2021]
            gnm  = obj.GenotypeName;
            for r = rng
                tr      = tic;
                %                 msk     = obj.getImage(r);
                msk     = obj.getImage(r, 'bw');
                sdls{r} = extractSeedlings(obj, msk, frm, sdlsz, hypln);
                frm     = frm + 1;

                if v
                    nsdls = numel(sdls{r});
                    tsdls = sum(cellfun(@numel, sdls));
                    tt    = round(toc(t), 3);
                    zz    = cellfun(@str2num, strsplit(num2str(tt), '.'));
                    fprintf('| %s | Frame %03d | %03d Seedlings | Total %03d | +%.03f sec | %02d.%03d sec |\n', ...
                        gnm, r, nsdls, tsdls, toc(tr), zz);
                end
            end

            % Create new cell array of Seedlings with empty cells
            maxSdls = max(cellfun(@numel, sdls));
            rawSdls = cell(numel(sdls), maxSdls);

            % Fill cells with Seedlings
            for r = 1 : numel(sdls)
                rawSdls(r, 1:numel(sdls{r})) = sdls{r};
            end

            % Store all found seedlings in RawSeedlings property
            obj.RawSeedlings = rawSdls;

            if v
                fprintf('%s\nExtracted %d Seedlings from %s [%.02f sec]\n%s\n', ...
                    sprB, numel(rawSdls), gnm, toc(t), sprA);
            end
        end

        function SortSeedlings(obj, v, mth)
            %% Align Seedlings and filter out bad frames
            % Aligns each Seedling by their centroid coordinate and then filters
            % out empty time points [to obtain true lifetime]. This function
            % calls an assortment of helper functions that filters out empty
            % frames and aligns Seedling objects through subsequent frames.
            if nargin < 2; v   = 1;     end
            if nargin < 3; mth = 'new'; end

            rs   = obj.getRawSeedling;
            frms = size(rs,1);
            ns   = size(rs,2);
            if v
                t = tic;
                fprintf('Aligning %d seedlings from %d frames...', ns, frms);
            end

            sdls                  = obj.filterSeedlings(rs, ns, v, mth);
            obj.NumberOfSeedlings = numel(sdls);
            arrayfun(@(x) x.RemoveBadFrames, sdls, 'UniformOutput', 0);
            arrayfun(@(x) x.toggleStatus(1), sdls);

            if v; fprintf('Finished Aligning! [%.03f sec]\n\n', toc(t)); end
        end

        function PruneSeedlings(obj)
            %% Remove RawSeedlings to decrease size of data object
            obj.RawSeedlings = [];
        end

        function HideBadSeedlings(obj, nfrms, rev)
            %% Hide Seedlings with too few frames
            if nargin < 2; nfrms = obj.TotalImages; end
            if nargin < 3; rev   = 0;               end

            %
            sdls   = obj.Seedlings;
            isGood = logical(arrayfun(@(x) x.Lifetime == nfrms, sdls));

            %
            if isempty(obj.RawSeedlings)
                s    = arrayfun(@(x) x, sdls, 'UniformOutput', 0);
                snms = cellfun(@(x) x.SeedlingName, s, 'UniformOutput', 0);
                cellfun(@(x,y) x.setSeedlingName(y, 1), s, snms);
                arrayfun(@(x,y) x.toggleStatus(y), sdls, isGood);
                obj.RawSeedlings = sdls;
            end

            %
            gdls  = arrayfun(@(x) x, sdls(isGood), 'UniformOutput', 0);
            ngood = numel(gdls);
            sidxs = 1 : ngood;
            gnms  = arrayfun(@(x) sprintf('Seedling_{%d}', x), ...
                sidxs', 'UniformOutput', 0);
            cellfun(@(x,y) x.setSeedlingName(y), gdls, gnms);

            %
            if rev
                obj.Seedlings = obj.RawSeedlings;
            else
                obj.Seedlings = cat(1, gdls{:});
            end

            %
            obj.NumberOfSeedlings = numel(obj.Seedlings);
        end

        function hyps = FindHypocotylAllSeedlings(obj, v)
            %% Extract Hypocotyl from all Seedlings from this Genotype
            if nargin < 2; v = 0; end % Verbosity

            try
                if v
                    t = tic;
                    [~ , sprA , sprB] = jprintf(' ', 0, 0, 80);
                    gnm               = obj.GenotypeName;
                    ngen              = obj.Parent.NumberOfGenotypes;
                    [~ , gidx]        = obj.Parent.search4Genotype(gnm);
                    fprintf('\n%s\n%s [%02d of %02d] [%d Seedlings]\n%s\n', ...
                        sprA, gnm, gidx, ngen, obj.NumberOfSeedlings, sprB);
                end

                sdls = obj.Seedlings;
                hyps = arrayfun(@(x) x.FindHypocotylAllFrames(v), ...
                    sdls, 'UniformOutput', 0);
                hyps = arrayfun(@(x) x.SortPreHypocotyls, ...
                    sdls, 'UniformOutput', 0);

                if v
                    nhyps = numel(hyps);
                    fprintf('%s\nExtracted %d Hypocotyls from %s [%.02f sec]\n%s\n', ...
                        sprB, nhyps, gnm, toc(t), sprA);
                end

            catch e
                fprintf(2, 'Error extracting Hypocotyl from %s\n%s\n', ...
                    gnm, e.getReport);

                if v; fprintf('[%.02f sec] %s\n', toc(t)); end
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
                fout = [];
                return;
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

        function [img , obs] = getImage(obj, idx, req)
            %% Return requested image at index
            % This function draws from the ImageStore property that contains an
            % ImageDataStore to read an image into memory from it's path name.
            %
            % This gives a significant improvement over my original method of
            % reading from the path name and writing the data to memory. This
            % made the image processing pipeline very slow, and created
            % very large objects and data output [ .mat ] files.
            if nargin < 2; idx = 1 : obj.TotalImages; end
            if nargin < 3; req = 'gray';              end

            if strcmpi(idx, ':')
                idx = obj.getFrame('b') : obj.getFrame('d');
            end

            % Grayscale image at index [can be a range of images]
            [img , obs] = deal([]);
            try
                imgs = searchImageStore(obj.ImageStore, idx);
                switch req
                    case 'gray'
                        % Keep grayscale image(s) and force to be double
                        if iscell(imgs)
                            img = cellfun(@(i) double(i), ...
                                imgs, 'UniformOutput', 0);
                        else
                            img = double(imgs);
                        end
                    case 'bw'
                        % Segment to binary mask(s)
                        if isempty(obj.SegDefaults)
                            obj.SegDefaults = obj.setSegDefaults;
                        end

                        smth = obj.SegDefaults.SmoothFilter;
                        sz   = obj.SegDefaults.MinMaxObject;
                        sens = obj.SegDefaults.Sensitivity;
                        mth  = obj.SegDefaults.Method;

                        if iscell(imgs)
                            [img , obs] = cellfun(@(x) ...
                                segmentObjectsHQ(x, smth, sz, sens, mth), ...
                                imgs, 'UniformOutput', 0);
                        else
                            [img , obs] = segmentObjectsHQ( ...
                                imgs, smth, sz, sens, mth);
                        end
                end
            catch
                fprintf(2, 'Error requesting image [%d|%s]\n', idx, req);
                return;
            end
        end

        function obj = setAutoSeedlings(obj)
            %% Manually set a Hypocotyl child object at a given frame
            % This crops out this Seedling's image and resizes it to the
            % desired patch size for Hypocotyl objects (see SCALESIZE property).

            % Extract and process contour from image
            imgs  = cellfun(@(x) double(x), ...
                obj.getImage, 'UniformOutput', 0);
            tot   = numel(imgs);
            frms  = num2cell(1:tot)';

            % Segment objects using simple binarization
            pdps  = obj.PDPROPERTIES;

            % Might have problems at this line
            prps  = cellfun(@(i) ...
                segmentObjectsHQ(imcomplement(i), 1, pdps, [], 1), ...
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

        function setRawSeedlings(obj, frms, sidxs, sdls)
            %% Set RawSeedling property
            try
                if numel(frms) > 1 || numel(sidxs) > 1
                    for f = frms'
                        for idx = sidxs'
                            obj.RawSeedlings{f,idx} = sdls{f};
                        end
                    end
                else
                    obj.RawSeedlings{frms,sidxs} = sdls;
                end
            catch
                fprintf(2, 'Error setting RawSeedling at frame %d index %d\n', ...
                    frms, sidxs);
            end
        end

        function rs = getRawSeedling(obj, frm, rsidx)
            %% Return single unindexed seedlings at index
            if nargin < 2; frm   = 1 : size(obj.RawSeedlings, 1); end
            if nargin < 3; rsidx = 1 : size(obj.RawSeedlings, 2); end

            try
                if numel(frm) > 1 || numel(rsidx) > 1
                    rs = obj.RawSeedlings(frm, rsidx);
                else
                    rs = obj.RawSeedlings{frm, rsidx};
                end
            catch
                fprintf(2, 'No RawSeedling at frame %s index %s \n', ...
                    num2str([min(frm) , max(frm)]), ...
                    num2str([min(rsidx) , max(rsidx)]));
                rs = [];
            end
        end

        function sdl = getSeedling(obj, num, getGood)
            %% Returns indexed seedling at desired index
            try
                if nargin < 2; num     = ':'; end
                if nargin < 3; getGood = 1; end

                sdl = obj.Seedlings(num);

                % Get only good Seedlings
                if getGood
                    gud = logical(arrayfun(@(x) x.Status, sdl));
                    sdl = sdl(gud);
                end
            catch
                fprintf(2, 'No Seedling at index %d \n', num);
            end
        end

        function [s , i] = search4Seedling(obj, nm)
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

        function [ubox , lbox] = setHypocotylCropBox(obj, hidxs, frms, v)
            %% Compute CropBox for upper and lower regions of a Hypocotyl
            if nargin < 2; hidxs = 1 : obj.NumberOfSeedlings; end
            if nargin < 3; frms  = [];                        end
            if nargin < 4; v     = 0;                         end

            %
            if isempty(frms)
                frms = arrayfun(@(s) 1 : s.Lifetime, ...
                    obj.getSeedling(hidxs), 'UniformOutput', 0);
            end

            %
            S = obj.getSeedling(hidxs);
            S = arrayfun(@(s) s, S, 'UniformOutput', 0);

            if v
                fprintf('Setting Hypocotyl CropBox for %d Seedlings...\n', ...
                    numel(S));
            end

            try
                [ubox , lbox] = cellfun(@(s,f) s.setHypocotylCropBox(f), ...
                    S, frms, 'UniformOutput', 0);
                ubox = cat(1, ubox{:});
                lbox = cat(1, lbox{:});
            catch
                fprintf(2, 'Error setting CropBox\n');
                [ubox , lbox] = deal([0 , 0 , 0 , 0]);
            end
        end

        function setSegDefaults(obj, smth, sz, sens, mth)
            %% Set default segmentation parameters
            if nargin < 2
                smth = 0;
                sz   = obj.MASKSIZE;
                %                 sens = 0.5;
                sens = 'dark';
                mth  = 2;
            end

            obj.SegDefaults.SmoothFilter = smth;
            obj.SegDefaults.MinMaxObject = sz;
            obj.SegDefaults.Sensitivity  = sens;
            obj.SegDefaults.Method       = mth;
        end

        function showSeedlings(obj, fidx, frm, sidx, fkeep)
            %% Display seedling cropboxes on image
            if nargin < 2; fidx  = 1;                         end
            if nargin < 3; frm   = 1;                         end
            if nargin < 4; sidx  = 1 : obj.NumberOfSeedlings; end
            if nargin < 5; fkeep = 1;                         end

            img  = obj.getImage(frm, 'gray');
            sdls = obj.getSeedling(sidx);
            cbox = arrayfun(@(x) x.getCropBox(frm), sdls, 'UniformOutput', 0);

            figclr(fidx, fkeep);
            myimagesc(img);
            hold on;
            cellfun(@(x) rectangle('Position', x, 'EdgeColor', 'r'), cbox);
            [~ , gttl] = obj.makeName;
            ttl        = sprintf('%s [Frame %d]', gttl, frm);
            title(ttl, 'FontSize', 10);
            hold off;
        end

        function [fnm , ttl , dsp] = makeName(obj)
            %% makeName: create filename, figure title, and display output
            gnm  = obj.GenotypeName;
            gttl = fixtitle(gnm);
            nsdls = obj.NumberOfSeedlings;
            nfrms = obj.TotalImages;

            % For files names
            fnm = sprintf('%s_%s_%02dseedlings_%02dframes', ...
                tdate, gnm, nsdls, nfrms);

            % For figure titles
            ttl = sprintf('%s\n%d Seedlings | %d Frames', gttl, nsdls, nfrms);

            % For console output
            dsp = sprintf('%s | %d Seedlings | %d Frames', gnm, nsdls, nfrms);
        end

        function setProperty(obj, req, val)
            %% Returns a property of this Genotype object
            try
                obj.(req) = val;
            catch e
                fprintf(2, 'Property %s does not exist\n%s\n', ...
                    req, e.message);
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
        function sdls = extractSeedlings(obj, msk, frm, sdlsz, hypln, bopen)
            %% Segmentation and Extraction of Seedling objects from raw image
            % This function binarizes a grayscale image at the given frame and
            % extracts features of a specified minimum size. Output is in the
            % form of an [m x n] cell array containing RawSeedling objects that
            % represent the total number of objects (m) for total frames (n).
            %
            % Input:
            %   obj: this Genotype object
            %   img: grayscale image containing growing seedlings
            %   frm: time point for Seedling's lifetime (NOT frame)
            %   mskSz: min-max cutoff size for objects labelled as a Seedling
            %   hypln: distance at bottom of image to set cutoff for Hypocotyl
            %

            %%
            if nargin < 4; sdlsz = obj.Parent.getProperty('SEEDLINGSIZE');    end
            if nargin < 5; hypln = obj.Parent.getProperty('HYPOCOTYLLENGTH'); end
            if nargin < 6; bopen = obj.BOPEN;                                 end

            %% Compute cut-off to chop hypocotyl
            msk = obj.getImage(frm, 'bw');
            %             se  = strel('line', 15, 1);
            se = strel('disk', 3);
            msk = imdilate(msk, se);
            msk = bwareafilt(msk, sdlsz);
            dd  = bwconncomp(msk);
            prp = regionprops(dd, msk, obj.PDPROPERTIES);

            % Remove large objects detected as seedlings
            prp   = prp(arrayfun(@(x) x.Area >= sdlsz(1), prp));
            prp   = prp(arrayfun(@(x) x.Area <= sdlsz(2), prp));
            nsdls = numel(prp);

            % Buffer bounding boxes
            hoff = obj.HYPBUFFER; % Hypocotyl AnchorPoints
            soff = obj.SDLBUFFER; % Seedling BoundingBox
            for i = 1 : numel(prp)
                prp(i).BoundingBox = prp(i).BoundingBox + soff;
            end

            % Crop grayscale/bw/contour image of RawSeedling
            bws  = arrayfun(@(x) imcrop(msk, x.BoundingBox), ...
                prp, 'UniformOutput', 0);
            ctrs = cellfun(@(x) extractContour(x, obj.CONTOURSIZE), ...
                bws, 'UniformOutput', 0);

            % Create Seedling objects using data from bw mask and contour
            sdls = cell(1, nsdls);
            for sidx = 1 : nsdls
                nm  = sprintf('Raw_%d', sidx);
                sdl = Seedling('SeedlingName', nm);
                sdl.setPData(1, prp(sidx));
                sdl.setContour(1, ctrs{sidx});
                sdl.setParent(obj);
                ctrs{sidx}.setParent(sdl);
                sdl.increaseLifetime;
                sdl.setFrame(frm, 'b');
                sdl.setFrame(frm, 'd');
                sdl.setCoordinates(1, prp(sidx).WeightedCentroid);
                smsk = bws{sidx};
                smsk = bwareaopen(smsk, bopen); % Clean image of specks [09.17.2021]
                pts  = bwAnchorPoints(smsk, hypln, hoff);
                sdl.setAnchorPoints(1, pts);
                sdls{sidx} = sdl;

                obj.setRawSeedlings(frm, sidx, sdl);
            end
        end

        function sdls = filterSeedlings(obj, rs, nsdls, v, mth)
            %% Filter out bad Seedling objects and frames
            % This function iterates through the cell array of RawSeedlings to
            % add only good Seedling objects into this Genotype.
            %
            % Specifically, it compares the centroid coordinates of each
            % Seedling to align it with the Seedling with the closest centroid
            % coordinates in the next frame.
            if nargin < 4; v   = 0;     end % Verbosity
            if nargin < 5; mth = 'new'; end % Sort method

            switch mth
                case 'old'
                    % Store all coordinates in 3-dim matrix
                    rs       = empty2nan(rs, Seedling( ...
                        'SeedlingName', 'empty', 'Coordinates', [nan , nan]));
                    crdsCell = cellfun(@(x) ...
                        x.getCoordinates(1), rs, 'UniformOutput', 0);
                    crdsMtrx = zeros(size(crdsCell, 1), 2, size(crdsCell, 2));
                    for ns = 1 : size(crdsCell, 2)
                        crdsMtrx(:,:,ns) = cat(1, crdsCell{:,ns});
                    end

                    % Create empty Seedling array
                    mkSdl = @(x) Seedling('SeedlingName', ...
                        sprintf('Seedling_{%s}', num2str(x)));
                    sdls  = arrayfun(@(x) mkSdl(x), ...
                        1 : nsdls, 'UniformOutput', 0)';
                    sdls  = cat(1, sdls{:});

                    % Align coordinates to closest match at each frame.
                    crdsMtrx = permute(crdsMtrx, [3 , 2 , 1]);
                    sdlIdx   = alignCoordinates(crdsMtrx);

                    %% Add child Seedlings to this Genotype parent
                    for ns = 1 : nsdls
                        if v
                            tf = tic;
                            fprintf('\n[Seedling %02d of %02d] | ', ns, nsdls);
                        end

                        sdl   = sdls(ns);
                        idx   = sdlIdx(ns,:);
                        nfrms = numel(idx);
                        for nf = 1 : nfrms
                            t = rs{nf,ns};

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

                            if v; fprintf('%02d | ', nf); end
                        end

                        if v; fprintf('DONE! [%.03f sec]\n', toc(tf)); end
                    end

                case 'new'
                    %% Prep adjacency matrix from raw seedling coordinates
                    RS   = cat(1, rs{:});
                    CRDS = cell2mat(arrayfun(@(x) x.Coordinates, ...
                        RS, 'UniformOutput', 0));
                    DD   = pdist2(CRDS, CRDS);
                    dmsk = DD < 120; % Min distance from objects [default 150]
                    ddm  = DD .* dmsk;

                    % Make digraph and determine clusters
                    gr    = digraph(ddm);
                    nidxs = gr.conncomp; % Total seedlings groups
                    re    = cellfun(@isempty, rs);
                    lidx  = 1:numel(rs(~re));

                    hh   = arrayfun(@(x) find(~re(:,x)), 1 : size(rs,2), ...
                        'UniformOutput', 0);
                    ii   = cat(1, hh{:})';
                    jj   = arrayfun(@(x) cell2mat(arrayfun(@(y) x, ...
                        1 : numel(hh{x}), 'UniformOutput', 0)), ...
                        1 : numel(hh), 'UniformOutput', 0);
                    jj   = cat(2, jj{:});
                    clst = [lidx' , ii' , jj' , CRDS , nidxs'];

                    %% Detect collisions and remove both guilty parties
                    strt = cell2mat(arrayfun(@(x) x.Coordinates, ...
                        cat(1, rs{1,:}), 'UniformOutput', 0));
                    uq   = unique(clst(:,end));
                    rm   = [];
                    for e = 1 : numel(uq)
                        fidx  = find(clst(:,end) == uq(e));
                        tmpcm = clst(fidx, 4 : 5);
                        tmp   = intersect(tmpcm, strt, 'rows');

                        if size(tmp,1) > 1
                            rm             = [rm , uq(e)];
                            clst(fidx,end) = nan;
                        end
                    end

                    %% Make RawSeedling arrays from valid groups
                    sgrps = unique(clst(:,end));
                    sgrps(isnan(sgrps)) = [];

                    R = cell(1, numel(sgrps));
                    for r = 1 : numel(sgrps)
                        sidx = sgrps(r);
                        ww   = sortrows(clst(clst(:,end) == sidx, :),2);
                        tmp  = arrayfun(@(x,y) rs(x,y), ww(:,2), ww(:,3));
                        R{r} = cat(1, tmp{:})';
                    end

                    % Remove Seedlings with fewer images than total [02.18.2022]
                    % Don't deal with problem of seedlings colliding at any
                    % point and having different indices of images
                    nimgs = obj.TotalImages;
                    sfrms = cellfun(@numel, R);
                    R     = R(sfrms == nimgs);

                    % Create empty Seedling array
                    nsdls = numel(R);
                    mkSdl = @(x) Seedling('SeedlingName', ...
                        sprintf('Seedling_{%s}', num2str(x)));
                    sdls  = arrayfun(@(x) mkSdl(x), ...
                        1 : nsdls, 'UniformOutput', 0)';
                    sdls  = cat(1, sdls{:});

                    %% Add child Seedlings to this Genotype
                    for ns = 1 : nsdls
                        if v
                            tf = tic;
                            fprintf('\n[Seedling %02d of %02d] | ', ns, nsdls);
                        end

                        r     = R{ns};
                        sdl   = sdls(ns);
                        nfrms = numel(r);
                        for nf = 1 : nfrms
                            t = r(nf);

                            if sdl.getLifetime == 0
                                sdl.setFrame(t.getFrame('b'), 'b');
                            elseif sdl.getFrame('d') <= t.getFrame('b')
                                sdl.setFrame(t.getFrame('b'), 'd');
                            else
                                break;
                            end

                            % Add data to Seedling
                            sdl.increaseLifetime;
                            sdl.setCoordinates(sdl.getLifetime, t.getCoordinates(1));
                            sdl.setAnchorPoints(sdl.getLifetime, t.getAnchorPoints(1));
                            sdl.setContour(sdl.getLifetime, t.getContour(1));
                            sdl.setPData(sdl.getLifetime, t.getPData);
                            sdl.setParent(obj);

                            if v; fprintf('%02d | ', nf); end
                        end

                        if v; fprintf('DONE! [%.03f sec]', toc(tf)); end
                    end
            end

            if v; fprintf('\n'); end
            obj.Seedlings = sdls;
        end
    end
end
