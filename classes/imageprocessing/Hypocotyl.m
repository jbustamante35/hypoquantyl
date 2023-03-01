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

        function FixSeedlingIndex(obj)
            % Set correct index for when I messed up indexing
            sdl               = obj.Parent;
            obj.SeedlingName  = sdl.SeedlingName;
            sidx              = obj.getSeedlingIndex;
            obj.HypocotylName = sprintf('Hypocotyl_{%d}', sidx);
        end

        function FixGenotypeName(obj)
            % Set GenotypeName property for when it somehow clears
            sdl = obj.Parent;
            obj.GenotypeName = sdl.GenotypeName;
        end

        function img = FlipMe(obj, frm, req, rgn, mbuf, abuf, scl)
            %% Store a flipped version of each Hypocotyl
            % Flipped version allows equal representation of all orientations of
            % contours because equality. If buf > 0, first buffer the region
            % around the image and then flip it.
            %
            % Input:
            %   obj: this Hypocotyl object
            %   frm: time point to extract image from
            %   buf: boolean to return buffered region around image
            if nargin < 2; frm  = obj.getFrame('b') : obj.getFrame('d'); end
            if nargin < 3; req  = 'gray';                                end
            if nargin < 4; rgn  = 'upper';                               end
            if nargin < 5; mbuf = 0;                                     end
            if nargin < 6; abuf = 0;                                     end
            if nargin < 7; scl  = 1;                                     end

            flp = 1;
            img = obj.getImage(frm, req, rgn, flp, mbuf, abuf, scl);
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

        function [dat , fmsk , oob] = getImage(obj, frm, req, rgn, flp, mbuf, abuf, scl)
            %% Return image for this Hypocotyl
            % Input:
            %   obj: this Curve object
            %   frm: frame from time course [default ':']
            %   req: image type [gray | bw]
            %   rgn: region [upper | lower]
            %   flp: force fliped direction [0 | 1 | []]
            %   mbuf: cropped buffering [default 0]
            %   abuf: artificial buffering [default 0]
            %   scl: scaling from original size (101 x 101) [default 1]
            if nargin < 2; frm  = ':';     end
            if nargin < 3; req  = 'gray';  end
            if nargin < 4; rgn  = 'upper'; end
            if nargin < 5; flp  = 0;       end
            if nargin < 6; mbuf = 0;       end
            if nargin < 7; abuf = 0;       end
            if nargin < 8; scl  = 1;       end

            if isempty(frm); [dat , fmsk] = deal([]); return; end
            if strcmpi(frm, ':')
                frm = obj.getFrame('b') : obj.getFrame('d');
            end
            if size(frm,1) > size(frm,2); frm = frm'; end

            % Get full image
            sclsz   = (obj.Parent.getScaleSize * scl) - (scl - 1);
            fimg    = obj.Parent.getImage(frm, req, mbuf);
            man_bnd = [0 , 0 , mbuf * 2 , 0];

            % Buffer with median background intensity
            if abuf
                if abuf >= 1
                    % Buffer by pixels
                    buffval = abuf;
                else
                    % Buffer by percentage
                    scl     = obj.Parent.getProperty('SCALESIZE');
                    isz     = scl(1);
                    buffval = round(abuf * isz);
                end

                % Get masks first
                fmsk = obj.Parent.getImage(frm, 'bw');
                if iscell(fmsk)
                    % Cell array
                    bnd = num2cell(obj.getCropBox(frm, rgn) + man_bnd, 2)';
                    if strcmpi(req, 'bw')
                        medBg = arrayfun(@(x) 0, ...
                            1 : numel(fmsk), 'UniformOutput', 0);
                    else
                        medBg = cellfun(@(i,m) median(i(m == 0)), ...
                            fimg, fmsk, 'UniformOutput', 0);
                    end

                    % Buffer them
                    crp = cellfun(@(i,b,m) cropWithBuffer(i,b,buffval,m), ...
                        fimg, bnd, medBg, 'UniformOutput', 0);
                    dat = cellfun(@(x) imresize(x, sclsz), ...
                        crp, 'UniformOutput', 0);

                    % Flip them
                    if ~isempty(flp)
                        if flp
                            dat = cellfun(@(x) flip(x,2), ...
                                dat, 'UniformOutput', 0);
                        end
                    end
                else
                    % Single image
                    bnd         = obj.getCropBox(frm, rgn);
                    [bnd , oob] = bufferCropBox(bnd, man_bnd, fimg);
                    if strcmpi(req, 'bw')
                        medBg = 0;
                    else
                        medBg = median(fimg(fmsk == 0));
                    end

                    % Buffer it
                    crp = cropWithBuffer(fimg, bnd, buffval, medBg);
                    dat = imresize(crp, sclsz);

                    % Flip it
                    if flp; dat = flip(dat, 2); end
                end
            else
                % Don't buffer
                if iscell(fimg)
                    % Crop them
                    bnd = num2cell(...
                        obj.getCropBox(frm, rgn) + man_bnd, 2)';
                    crp = cellfun(@(i,b) imcrop(i,b), ...
                        fimg, bnd, 'UniformOutput', 0);
                    dat = cellfun(@(x) imresize(x, sclsz), ...
                        crp, 'UniformOutput', 0);

                    % Flip them
                    if flp
                        dat = cellfun(@(x) flip(x, 2), dat, 'UniformOutput', 0);
                    end
                else
                    % Crop it
                    bnd         = obj.getCropBox(frm, rgn);
                    [bnd , oob] = bufferCropBox(bnd, man_bnd, fimg);

                    crp = imcrop(fimg, bnd);
                    dat = imresize(crp, sclsz);

                    % Flip it
                    if flp; dat = flip(dat, 2); end
                end
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

        function [fnm , ttl , itr] = makeName(obj)
            %% makeTitle: make a simple title for this object
            gnm  = obj.GenotypeName;
            gttl = fixtitle(gnm);
            sidx = obj.Parent.getSeedlingIndex;
            nfrm = obj.Lifetime;

            % For files names
            fnm = sprintf('%s_%s_seedling%02d_%02dframes', ...
                tdate, gnm, sidx, nfrm);

            % For figure titles
            ttl = sprintf('%s\nSeedling %d [%d Frames]', gttl, sidx, nfrm);

            % For console output
            itr = sprintf('%s | Seedling %d | %d Frames', gnm, sidx, nfrm);
        end

        function gi = getGenotypeIndex(obj)
            %% Return index of the Genotype
            [~ , gi] = obj.Origin.search4Genotype(obj.GenotypeName);
        end

        function si = getSeedlingIndex(obj)
            %% Return index of the Seedling
            sn = obj.SeedlingName;
            aa = strfind(sn, '{');
            bb = strfind(sn, '}');
            si  = str2double(sn(aa+1:bb-1));
        end

        function setCropBox(obj, frms, bbox, rgn)
            %% Set vector for bounding box
            if nargin < 3; rgn = 'upper'; end

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

        function bbox = getCropBox(obj, frm, rgn, buf)
            %% Return CropBox parameter
            % The CropBox is a [4 x 1] vector that defines the bounding box
            % to crop from Parent Seedling. This can be from either the upper or
            % lower region of the Seedling.

            % Defaults
            if nargin < 2; frm = ':'; end
            if nargin < 3; rgn = 1;   end
            if nargin < 4; buf = 0;   end

            % Region dimension
            switch rgn
                case 1
                    r = 1 : 2;
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

            % Buffer bounding box
            if buf
                img          = obj.getImage(frm, 'gray', rgn, [], buf);
                soff         = [-buf , -buf , buf*2 , buf];
                [bbox , oob] = bufferCropBox(bbox, soff, img);
            end
        end

        function FixCropBox(obj, hyplen)
            %% Fix CropBox [e.g. if frame has [0 , 0 , NaN , NaN]
            if nargin < 2; hyplen = obj.Origin.getProperty('HYPOCOTYLLENGTH'); end

            % Find CropBoxes with NaN
            cbox       = obj.getCropBox;
            [rows , ~] = find(isnan(cbox));
            nan_frms   = unique(rows);

            % Fix AnchorPoints in parent Seedling, then set new CropBox
            sdl = obj.Parent;
            if isempty(nan_frms)
                % No frames with NaN
                return;
            elseif numel(nan_frms) > 1
                % Work on multiple frames
                simg = sdl.getImage(nan_frms);
                apts = cellfun(@(x) bwAnchorPoints(x, hyplen), ...
                    simg, 'UniformOutput', 0);
                apts = cat(3, apts{:});
                sdl.setAnchorPoints(nan_frms, apts);
                sdl.setHypocotylCropBox(nan_frms);
            else
                % Work on 1 frame
                simg = sdl.getImage(nan_frms);
                apts = bwAnchorPoints(simg, hyplen);
                sdl.setAnchorPoints(nan_frms, apts);
                sdl.setHypocotylCropBox(nan_frms);
            end
        end

        function setContour(obj, frm, ctr, rgn)
            %% Store ContourJB at frame
            if nargin < 4; rgn = 'upper'; end

            % Set upper or lower region
            switch rgn
                case 'upper'
                    r = 1;
                case 'lower'
                    r = 2;
                otherwise
                    fprintf(2, 'Region %s should be [upper|lower]\n', rgn);
                    return;
            end

            if isempty(obj.Contour)
                obj.Contour = ctr;
            else
                if size(obj.Contour,1) < size(obj.Contour,2)
                    obj.Contour = obj.Contour';
                end

                obj.Contour(frm,r) = ctr;
            end
        end

        function crc = getContour(obj, frm, rgn)
            %% Return all ContourJB objects or ContourJB at frame
            if nargin < 2; frm = obj.getFrame('b') : obj.getFrame('d'); end
            if nargin < 3; rgn = 'upper';                               end

            if isempty(obj.Contour)
                fprintf(2, 'No contours found. Initialize Contour with ')
            end

            % Get upper or lower region
            switch rgn
                case 'upper'
                    r = 1;
                case 'lower'
                    r = 2;
                otherwise
                    fprintf(2, 'Region %s should be [upper|lower]\n', rgn);
                    crc = [];
                    return;
            end

            crc = obj.Contour(frm, r);
        end

        function cc = copyCircuit(obj, frm)
            %% Copy counterpart of CircuitJB at same frame
            % Make copy
            crc = obj.Circuit(frm);
            cc  = crc.copy;
        end

        function obj = setCircuit(obj, frm, crc)
            %% Set manually-drawn CircuitJB object (original or flipped)
            if isempty(obj.Circuit)
                obj.Circuit = repmat(CircuitJB, obj.Lifetime, 1);
            end

            crc.trainCircuit(true);
            obj.Circuit(frm) = crc;
        end

        function crc = getCircuit(obj, frm)
            %% Return original or flipped version of CircuitJB object
            if nargin < 2; frm = 0;      end % First available CircuitJB

            crc = [];
            if ~isempty(obj.Circuit)
                % Find first available frame
                if ~frm
                    cc  = arrayfun(@(x) ~isempty(x.Origin), obj.Circuit);
                    cc  = find(cc);
                    if isempty(cc)
                        fprintf(2, '\nNo frames traced.\n\n');
                        return;
                    else
                        frm = cc(1);
                    end
                end

                % Make sure frame is available
                if frm > size(obj.Circuit,1); return; end
                try
                    % Set isTrained status to false if not yet set
                    c = obj.Circuit(frm);
                    if isempty(c.isTrained);      c.trainCircuit(false); end
                    if isvalid(c) && c.isTrained; crc = c;               end
                catch
                    return;
                end
            else
                % Initialize Circuit property
                obj.Circuit = repmat(CircuitJB, obj.Lifetime);
                crc         = obj.Circuit(frm);
            end
        end

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
                if isempty(obj.Circuit)
                    % Initialize Circuit property
                    obj.Circuit = repmat(CircuitJB, obj.Lifetime);
                else
                    crcs             = obj.Circuit;
                    trained_frames   = ind2sub(size(crcs), ...
                        find(arrayfun(@(x) x.isTrained, crcs)));
                    untrained_frames = ...
                        find(~ismember(1 : numel(crcs), trained_frames))';
                end
            catch e
                fprintf(2, 'Error returning untrained frames\n%s', e.message);
                [untrained_frames , trained_frames] = deal([]);
            end
        end

        function ResetCropBox(obj, frms)
            %% Set lower region bounding box for frame
            if nargin < 2; frms = 1 : obj.Lifetime; end

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
