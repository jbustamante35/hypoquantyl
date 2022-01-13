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

        %         function FixGenotypeName(obj)
        %             sdl = obj.Parent;
        %             obj.GenotypeName = sdl.GenotypeName;
        %         end

        function img = FlipMe(obj, frm, req, rgn, buf)
            %% Store a flipped version of each Hypocotyl
            % Flipped version allows equal representation of all orientations of
            % contours because equality. If buf > 0, first buffer the region
            % around the image and then flip it.
            %
            % Input:
            %   obj: this Hypocotyl object
            %   frm: time point to extract image from
            %   buf: boolean to return buffered region around image
            if nargin < 2; frm = obj.getFrame('b') : obj.getFrame('d'); end
            if nargin < 3; req = 'gray';                                end
            if nargin < 4; rgn = 'upper';                               end
            if nargin < 5; buf = 0;                                     end

            flp = 1;
            img = obj.getImage(frm, req, rgn, flp, buf);
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

        function [dat , fmsk] = getImage(obj, frm, req, rgn, flp, buf)
            %% Return image for this Hypocotyl
            % Image is obtained from the Parent Seedling, cropped, and resized
            % to this object's RESCALE property
            if nargin < 2; frm = obj.getFrame('b') : obj.getFrame('d'); end
            if nargin < 3; req = 'gray';                                end
            if nargin < 4; rgn = 'upper';                               end
            if nargin < 5; flp = 0;                                     end
            if nargin < 6; buf = 0;                                     end

            % Get full image
            sclsz = obj.Parent.getScaleSize;
            fimg  = obj.Parent.getImage(frm, req);

            % Buffer with median background intensity
            if buf
                if buf >= 1
                    % Buffer by pixels
                    buffval = buf;
                else
                    % Buffer by percentage
                    scl     = obj.Parent.getProperty('SCALESIZE');
                    isz     = scl(1);
                    buffval = round(buf * isz);
                end

                % Get masks first
                fmsk = obj.Parent.getImage(frm, 'bw');
                if iscell(fmsk)
                    % Cell array
                    bnd = num2cell(obj.getCropBox(frm, rgn), 2)';
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
                    if flp
                        dat = cellfun(@(x) flip(x,2), dat, 'UniformOutput', 0);
                    end
                else
                    % Single image
                    bnd = obj.getCropBox(frm, rgn);
                    if strcmpi(req, 'bw')
                        medBg = 0;
                    else
                        medBg = median(fimg(fmsk == 0));
                    end

                    % Buffer it
                    crp = cropWithBuffer(fimg, bnd, buffval, medBg);
                    dat = imresize(crp, sclsz);

                    % Flip it
                    if flp
                        dat = flip(dat, 2);
                    end
                end
            else
                % Don't buffer
                if iscell(fimg)
                    % Crop them
                    bnd = num2cell(...
                        obj.getCropBox(frm, rgn), 2)';
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
                    bnd = obj.getCropBox(frm, rgn);
                    crp = imcrop(fimg, bnd);
                    dat = imresize(crp, sclsz);

                    % Flip it
                    if flp
                        dat = flip(dat, 2);
                    end
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

        function bbox = getCropBox(obj, frm, rgn)
            %% Return CropBox parameter
            % The CropBox is a [4 x 1] vector that defines the bounding box
            % to crop from Parent Seedling. This can be from either the upper or
            % lower region of the Seedling.

            % Defaults
            if nargin < 2; frm = ':';     end
            if nargin < 3; rgn = 'upper'; end

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
                obj.Contour(frm,r) = ctr;
            end
        end

        function crc = getContour(obj, frm, rgn)
            %% Return all ContourJB objects or ContourJB at frame
            if nargin < 2; frm = obj.getFrame('b') : obj.getFrame('d'); end
            if nargin < 3; rgn = 'upper';                               end

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
                crcs             = obj.Circuit(:,1,1);
                trained_frames   = ind2sub(size(crcs), ...
                    find(arrayfun(@(x) x.isTrained, crcs)));
                untrained_frames = ...
                    find(~ismember(1 : numel(crcs), trained_frames))';
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
