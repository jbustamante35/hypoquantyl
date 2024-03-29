%% HypocotylTrainer: class for sections of contours for a CircuitJB object
% Descriptions
%
% Example:
%
%

classdef HypocotylTrainer < handle
    properties (Access = public)
        Curves
        HTName
        UniqueName
        SaveDirectory
        Splits

        % Image Properties
        Histogram
        ManBuf
        ArtBuf
        ImgScl

        % Curve Segment Properties
        ContourVsn
        ImageFnc
        SegmentSize
        SegmentSteps

        % Dataset Splitting
        TrainingPct
        TestingPct
        ValidationPct

        % PCA Parameters
        NPX
        NPY
        NPZ
        NZP
        NPM
        NCV
        NMV
        NPT
        ZNorm
        ZShape

        % Z-Vector Attributes
        AddMid
        ZRotate
        ZRotateType
        Split2Stitch

        % Midline Patch Attributes
        PatchSize
        MLineSize
        MLineParams
        MLineMethod
        Bwid
        TolFun
        TolX
        CEpochs

        % Cotyledon Patch Attributes
        TScale
        TLen
        TNWid
        TRes
        TTWid

        % Z-Vector CNN
        FilterRange
        NumFilterRange
        FilterLayers
        DropoutLayer
        MiniBatchSize
        ZEpochs
        InitialLearningRate

        % D-Vector NN
        Recursions
        FoldMethod
        toFix
        SegLengths
        NPF
        NPD
        DLayers
        DTrainFnc
        Dshape
        Dzoom

        % BasePoint CNN
        BasePoint
        BaseRows
        BaseShift
        BaseFilterRange
        BaseNumFilterRange
        BaseDropoutLayer
        BaseMiniBatchSize
        BaseInitialLearningRate

        % S-Vector NN
        SLayers
        STrainFnc

        % Miscellaneous Properties
        Save
        Visualize
        toStore
        Parallel
        Verbose
        Figures
        isOptimized
    end

    properties (Access = protected)
        SplitCurves
        PCA
        ZVectors
        ZFnc
        ZBay
        ZParams
        ZParams_bak
        BVectors
        BFnc
        BBay
        BParams
        BParams_bak
        DVectors
        SVectors
        FigNames
        Images
    end

    %%
    methods (Access = public)
        %% Constructor and primary methods
        function obj = HypocotylTrainer(varargin)
            %% Constructor method for single Cure
            if ~isempty(varargin)
                % Parse inputs to set properties
                vargs = varargin;
            else
                % Set default properties for empty object
                vargs = {};
            end

            prps   = properties(class(obj));
            deflts = { ...
                % Curve Properties
                'HTName'              , []     ; ... % Long name
                'UniqueName'          , []     ; ... % Descriptive name
                'SaveDirectory'       , pwd    ; ... % Main folder to store data
                'SegmentSize'         , 25     ; ... % Number of coordinates per segment
                'SegmentSteps'        , 1      ; ... % Step size to next segment
                'ContourVsn'          , 'Clip' ; ... % Contour type [Full|Clip]
                'ImageFnc'            , 'left' ; ... % Direction of seedling to use [left|right]

                % Dataset Splitting
                'TrainingPct'         , 0.8 ; ... % Split percentage to use for training
                'TestingPct'          , 0.1 ; ... % Split percentage to use for testing
                'ValidationPct'       , 0.1 ; ... % Split percentage to use for validation
                'Splits'              , []  ; ... % Splitting dataset

                % Image Properties
                'Histogram'           , struct('Data', [], 'Tag', '', 'NumBins', 0) ; ... % Histogram to normalize to
                'ManBuf'              , 0 ; ... % Buffer size for seedling cropbox
                'ArtBuf'              , 0 ; ... % Buffer size to artificially generate
                'ImgScl'              , 1 ; ... % Scaling size for cropped hypocotyl image

                % PCA Parameters
                'NPX'                 , 0 ; ... % PCs for x-component of segments [default 6]
                'NPY'                 , 0 ; ... % PCs for y-component of segments [default 6]
                'NPZ'                 , 0 ; ... % PCs for Z-Vector [default 10]
                'NZP'                 , 0 ; ... % PCs for sampled Z-Vector patches [default 10]
                'NPM'                 , 0 ; ... % PCs for sampled midline [default 20]
                'NCV'                 , 0 ; ... % PCs for contours in stitching [default 20]
                'NMV'                 , 0 ; ... % PCs for midlines in stitching [default 20]
                'NPT'                 , 0 ; ... % PCs for sampled cotyledon [default 3]
                'ZNorm'               , struct('ps', 0, 'pz', 0, 'pp', 0) ; ... % Z-Score Normalize for PCA
                'ZShape'              , struct('ps', 0, 'pz', 0, 'pp', 0) ; ... % Dimensions to reshape Z-Score normalization

                % Z-Vector Attributes
                'AddMid'              , 0     ; ... % Re-center Z-Vector from [0 , 0]
                'ZRotate'             , 0     ; ... % Using radians for Z-Vector instead of tangents-normals
                'ZRotateType'         , 'rad' ; ... % Method if using radians for Z-Vector
                'Split2Stitch'        , 0     ; ... % PCA on individual Z-Vector factors

                % Midline Patch Attributes
                'PatchSize'           , 20            ;                 ... % Width to sample out from midline
                'MLineSize'           , 50            ;                 ... % Midline length
                'MLineParams'         , [5 , 3 , 0.1] ;                 ... % Midline generation parameters
                'MLineMethod'         , 'nate' ;                        ... % Midline generation method
                'Bwid'                , [0.1 , 0.1 , 0.1 , 0.1 , 1.0] ; ... % Bwid for ksdensity
                'TolFun'              , 1e-4 ;                          ... % Termination tolerance on function value
                'TolX'                , 1e-4 ;                          ... % Termination tolerance on X
                'CEpochs'             , 100  ;                          ... % Max iterations for segmentation optimizer

                % Cotyledon Patch Attributes
                'TScale'              , 5         ; ... % Scaling distance of tangent vector
                'TLen'                , 50        ; ... % Length of ellispse along tangent
                'TNWid'               , 30        ; ... % Width of ellipse along normal
                'TRes'                , [30 , 30] ; ... % Resolution of sampling ellipse
                'TTWid'               , 3         ; ... % Size of window for computing tangent

                % Z-Vector CNN
                'FilterRange'         , 7            ; ...
                'NumFilterRange'      , [10 , 5 , 3] ; ...
                'FilterLayers'        , 1            ; ...
                'DropoutLayer'        , 0.2          ; ...
                'MiniBatchSize'       , 128          ; ...
                'ZEpochs'             , 300          ; ...
                'InitialLearningRate' , 1e-4         ; ...

                % D-Vector NN
                'Recursions'          , 20                  ; ... % D-Vector recursive recursions
                'FoldMethod'          , 'local'             ; ... % Smoothing method after recursion
                'toFix'               , 0                   ; ... %
                'Dshape'              , 1                   ; ... % Z-Vector patch shapes to remove
                'Dzoom'               , [0.5 , 1.5]         ; ... %Z-Vector patch zoom levels
                'SegLengths'          , [53 , 52 , 53 , 51] ; ... % Lengths to split left-top-right-bottom segments
                'NPF'                 , [7 , 6 , 5]         ; ... % PCs for folding D-Vector contour predictions
                'NPD'                 , 10                  ; ... % PCs for Z-Vector patches containing D-Vector
                'DLayers'             , 5                   ; ... % Number of layers for D-Vector fitnet
                'DTrainFnc'           , 'trainlm'           ; ... % Training algorithm for D-Vector fitnet

                % BasePoint CNN
                'BasePoint'               , 0           ; ...
                'BaseRows'                , 10          ; ...
                'BaseShift'               , [-40 , 40]  ; ...
                'BaseFilterRange'         , 5           ; ...
                'BaseNumFilterRange'      , [7 , 5 , 3] ; ...
                'BaseDropoutLayer'        , 0.2         ; ...
                'BaseMiniBatchSize'       , 128         ; ...
                'BaseInitialLearningRate' , 1e-4        ; ...

                % S-Vector NN
                'SLayers'             , 5         ; ...
                'STrainFnc'           , 'trainlm' ; ...

                % Miscellaneous Properties
                'Save'                , 0 ; ...
                'Visualize'           , 0 ; ...
                'toStore'             , 0 ; ...
                'Parallel'            , 0 ; ...
                'Verbose'             , 0 ; ...
                'Figures'             , 1 : 4  ; ...
                'isOptimized'         , struct('znn', 0, 'bnn', 0) ...
                };

            obj = classInputParser(obj, prps, deflts, vargs);

            % Auto-Generate Name
            if isempty(obj.HTName); obj.HTName = makeName(obj); end
        end

        function ProcessCurves(obj)
            %% Configure segment length and step size
            crvs = obj.Curves;

            t = tic;
            n = fprintf('Pre-Processing data for %d Cuves', numel(crvs));

            arrayfun(@(c) c.setProperty('SEGMENTSIZE', obj.SegmentSize), ...
                crvs, 'UniformOutput', 0);
            arrayfun(@(c) c.setProperty('SEGMENTSTEPS', obj.SegmentSteps), ...
                crvs, 'UniformOutput', 0);
            arrayfun(@(c) c.getSegmentedOutline, ...
                crvs, 'UniformOutput', 0);

            jprintf(' ', toc(t), 1, 80 - n);
        end

        function splt = SplitDataset(obj, toSplit, toSet)
            %% Split Curves into training, validation, and testing sets
            % Validation and Testing sets not seen by training algorithm
            if nargin < 2; toSplit = 0; end
            if nargin < 3; toSet   = 0; end

            t       = tic;
            crvs    = obj.Curves;
            numCrvs = numel(crvs);
            if toSplit
                n = fprintf('Splitting into training,validation,testing sets');

                % Get indices of split datasets
                splt = splitDataset(1 : numCrvs, ...
                    obj.TrainingPct, obj.ValidationPct, obj.TestingPct);
                if toSet; obj.Splits = splt; end
            else
                n    = fprintf('Data already split');
                splt = obj.Splits;
            end
            jprintf(' ', toc(t), 1, 80 - n);
        end

        function RunPCA(obj, mth)
            %% Run PCA functions
            % PCA can be run with method 1 (training only) or method 2
            % (training and validation, testing untouched [default])
            if nargin < 2; mth = 'withval'; end % With training and validation

            switch mth
                case 'trn'
                    % Run with only training set
                    C = obj.getCurves('trnIdx');
                case 'withval'
                    % Run with training and validation sets
                    % Order is training in front, validation in back
                    C = [obj.getCurves('trnIdx') ; obj.getCurves('valIdx')];
                otherwise
                    fprintf(2, '%d not optimizable [trn|withval]\n', mth);
                    return;
            end

            [~ , ~ , ~ , ~ , ~ , ~ , ~ , ~ , ~ , ~ , msample , ~ , ...
                tsample , ~] = obj.getFunctions;

            [px , py , pz , pp , pm , pc , pv , pt] = hypoquantylPCA(C, ...
                obj.Save, 'vsn', obj.ContourVsn, 'fnc', obj.ImageFnc, ...
                'pcx', obj.NPX, 'pcy', obj.NPY, 'pcp', obj.NZP, ...
                'pcm', obj.NPM, 'pcv', obj.NCV, 'pmv', obj.NMV, ...
                'pct', obj.NPT, 'addMid', obj.AddMid, 'znorm', obj.ZNorm, ...
                'zshp', obj.ZShape, 'bdsp', obj.BasePoint, ...
                'nsplt', obj.SegmentSize, 'zrotate', obj.ZRotate, ...
                'msample', msample, 'tsample', tsample, ...
                'href', obj.Histogram, 'rtyp', obj.ZRotateType, ...
                'split2stitch', obj.Split2Stitch, 'mbuf', obj.ManBuf, ...
                'abuf', obj.ArtBuf, 'scl', obj.ImgScl, ...
                'SaveDir', obj.SaveDirectory);

            obj.PCA = struct('px', px, 'py', py, 'pz', pz, 'pp', pp, ...
                'pm', pm, 'pc', pc, 'pv', pv, 'pt', pt);
        end

        function TrainZVectors(obj, pcs, par, sav, vis, vrb)
            %% Train Z-Vectors
            if nargin < 2; pcs = 1 : obj.NPZ;   end
            if nargin < 3; par = obj.Parallel;  end
            if nargin < 4; sav = obj.Save;      end
            if nargin < 5; vis = obj.Visualize; end
            if nargin < 6; vrb = obj.Verbose;   end

            t = tic;
            if obj.Split2Stitch
                n    = fprintf(['Preparing %d images and [%d|%d] ' ...
                    'Z-Vectors PC scores'], ...
                    numel(obj.getSplits('trnIdx')), obj.NPZ{1}, obj.NPZ{2});
                flds = fieldnames(obj.PCA.pz);
                vtyp = flds{end};
            else
                n = fprintf(['Preparing %d images and %d Z-Vectors ' ...
                    'PC scores'], numel(obj.getSplits('trnIdx')), obj.NPZ);
            end

            if ~isempty(obj.Images)
                IMGS = obj.Images(obj.Splits.trnIdx);
            else
                IMGS = arrayfun(@(c) ...
                    c.getImage('gray', 'upper', ...
                    obj.ImageFnc, [], obj.ManBuf, obj.ArtBuf, obj.ImgScl), ...
                    obj.Curves(obj.Splits.trnIdx), 'UniformOutput', 0);
            end

            % Normalize images to histogram
            if ~isempty(obj.Histogram)
                href  = obj.Histogram.Data;
                hmth  = obj.Histogram.Tag;
                nbins = obj.Histogram.NumBins;
                IMGS  = cellfun(@(x) normalizeImageWithHistogram( ...
                    x, href, hmth, nbins), IMGS, 'UniformOutput', 0);
            end

            IMGS = cat(4, IMGS{:});

            % Stitch midpoints-tangents
            if obj.Split2Stitch
                ZSCRS = [obj.PCA.pz.mids.PCAScores(1 : size(IMGS,4)) , ...
                    obj.PCA.pz.(vtyp).PCAScores(1 : size(IMGS,4))];
            else
                ZSCRS = obj.PCA.pz.PCAScores(1 : size(IMGS,4));
            end

            jprintf(' ', toc(t), 1, 80 - n);

            %%
            [IN , OUT] = deal(cell(1, numel(pcs)));

            if isempty(obj.isOptimized); obj.isOptimized.znn = 0; end

            if obj.isOptimized.znn
                % Set PC-optimized parameters if not already
                if ~iscell(obj.FilterRange)
                    obj.SetOptimizedParameters('znn');
                end

                % Loop through optimized parameters or single PC
                for pc = pcs
                    [IN{pc}, OUT{pc}] = znnTrainer(IMGS, ZSCRS, obj.Splits, pc, ...
                        'Save', obj.Save, 'FltRng', obj.FilterRange{pc}, ...
                        'NumFltRng', obj.NumFilterRange{pc}, ...
                        'MBSize', obj.MiniBatchSize, ...
                        'Dropout', obj.DropoutLayer{pc}, ...
                        'ILRate', obj.InitialLearningRate{pc}, ...
                        'MaxEps', obj.ZEpochs, 'Parallel', par, ...
                        'Verbose', vrb, 'Visualize', vis, ...
                        'Save', sav, 'SaveDir', obj.SaveDirectory);
                end
            else
                % Use same parameters for each PC [old method]
                for pc = pcs
                    [IN{pc}, OUT{pc}] = znnTrainer(IMGS, ZSCRS, obj.Splits, ...
                        pc, 'Save', obj.Save, 'FltRng', obj.FilterRange, ...
                        'NumFltRng', obj.NumFilterRange, ...
                        'MBSize', obj.MiniBatchSize, ...
                        'Dropout', obj.DropoutLayer, ...
                        'ILRate', obj.InitialLearningRate, ...
                        'MaxEps', obj.ZEpochs, 'Parallel', par, ...
                        'Verbose', vrb, 'Visualize', vis, ...
                        'Save', sav, 'SaveDir', obj.SaveDirectory);
                end
            end

            if isempty(obj.ZVectors)
                obj.ZVectors = struct('ZIN', IN(pcs), 'ZOUT', OUT(pcs));
            else
                obj.ZVectors(pcs) = struct('ZIN', IN(pcs), 'ZOUT', OUT(pcs));
            end
        end

        function TrainDVectors(obj, par, sav, vis, myShps, zoomLvl)
            %% Train D-Vectors
            if nargin < 2; par     = obj.Parallel;  end
            if nargin < 3; sav     = obj.Save;      end
            if nargin < 4; vis     = obj.Visualize; end
            if nargin < 5; myShps  = obj.Dshape;   end
            if nargin < 6; zoomLvl = obj.Dzoom;     end

            t = tic;
            n = fprintf(['Training D-Vectors through %d ' ...
                'recursions [%s folding]'], obj.Recursions, obj.FoldMethod);

            IMGS  = arrayfun(@(c) c.getImage('gray', 'upper', ...
                obj.ImageFnc, [], obj.ManBuf, obj.ArtBuf, obj.ImgScl), ...
                obj.getCurves('trnIdx'), 'UniformOutput', 0);
            CNTRS = arrayfun(@(c) c.getTrace(obj.ContourVsn, ...
                obj.ImageFnc, obj.ManBuf, obj.ImgScl), ...
                obj.getCurves('trnIdx'), 'UniformOutput', 0);

            % Normalize images to histogram
            if ~isempty(obj.Histogram)
                href  = obj.Histogram.Data;
                hmth  = obj.Histogram.Tag;
                nbins = obj.Histogram.NumBins;
                IMGS  = cellfun(@(x) normalizeImageWithHistogram( ...
                    x, href, hmth, nbins), IMGS, 'UniformOutput', 0);
            end

            nfigs             = numel(obj.Figures);
            cidxs             = pullRandom(obj.Splits.trnIdx, nfigs, 0);
            [IN , OUT , fnms] = dnnTrainer(IMGS, CNTRS, ...
                'nitrs', obj.Recursions, 'nsplt', obj.SegmentSize, ...
                'cidxs', cidxs, 'fmth', obj.FoldMethod, 'toFix', obj.toFix, ...
                'seg_lengths', obj.SegLengths, 'NPF', obj.NPF, ...
                'myShps', myShps, 'zoomLvl', zoomLvl, 'NPD', obj.NPD, ...
                'NLAYERS', obj.DLayers, 'TRNFN', obj.DTrainFnc, ...
                'Visualize', vis, 'Parallel', par, ...
                'Save', sav, 'SaveDir', obj.SaveDirectory);

            jprintf(' ', toc(t), 1, 80 - n);

            obj.DVectors = struct('DIN', IN, 'DOUT', OUT);
            obj.FigNames = fnms;
        end

        function TrainBVectors(obj, par, sav, vis, vrb)
            %% Train B-Vectors: base point displacements
            if nargin < 2; par = obj.Parallel;  end
            if nargin < 3; sav = obj.Save;      end
            if nargin < 4; vis = obj.Visualize; end
            if nargin < 5; vrb = obj.Verbose;   end

            t = tic;
            n = fprintf('Preparing %d images and base points', ...
                numel(obj.getSplits('trnIdx')));

            if ~isempty(obj.Images)
                IMGS = obj.Images(obj.Splits.trnIdx);
            else
                IMGS = arrayfun(@(c) ...
                    c.getImage('gray', 'upper', ...
                    obj.ImageFnc, [], obj.ManBuf, obj.ArtBuf, obj.ImgScl), ...
                    obj.Curves(obj.Splits.trnIdx), 'UniformOutput', 0);
            end

            % Normalize images to histogram
            if ~isempty(obj.Histogram)
                href  = obj.Histogram.Data;
                hmth  = obj.Histogram.Tag;
                nbins = obj.Histogram.NumBins;
                IMGS  = cellfun(@(x) normalizeImageWithHistogram( ...
                    x, href, hmth, nbins), IMGS, 'UniformOutput', 0);
            end

            IMGS = cat(4, IMGS{:});

            nrows = obj.BaseRows;
            isz   = size(IMGS(:,:,:,1), 1);
            irows = isz - nrows : isz;
            IMGS  = IMGS(irows,:,:,:);

            BPTS = cell2mat(arrayfun(@(x) x.getBotMid( ...
                obj.ContourVsn, obj.ImageFnc, obj.ManBuf, obj.ImgScl), ...
                obj.Curves(obj.Splits.trnIdx), 'UniformOutput', 0));
            BPTS = BPTS(:,1);

            jprintf(' ', toc(t), 1, 80 - n);

            %% Randomly shift BasePoint left and right
            % Broaden range of values and inflate data
            bimgs = IMGS;
            bpts  = BPTS;
            bsht  = randi(obj.BaseShift, 1, 10, 'double');
            for nb = 1 : numel(bsht)
                tmpx  = circshift(IMGS, bsht(nb), 2);
                tmpy  = BPTS + bsht(nb);
                bimgs = cat(4, bimgs, tmpx);
                bpts  = cat(1, bpts, tmpy);
            end

            IMGS = bimgs;
            BPTS = bpts;

            %% Fix training splits
            [IN , OUT] = znnTrainer(IMGS, BPTS, [], 1, ...
                'Save', obj.Save, 'FltRng', obj.BaseFilterRange, ...
                'NumFltRng', obj.BaseNumFilterRange, ...
                'MBSize', obj.BaseMiniBatchSize, ...
                'Dropout', obj.BaseDropoutLayer, ...
                'ILRate', obj.BaseInitialLearningRate, ...
                'MaxEps', obj.ZEpochs, 'Parallel', par, ...
                'Verbose', vrb, 'Visualize', vis, ...
                'Save', sav, 'SaveDir', obj.SaveDirectory);

            obj.BVectors = struct('BIN', IN, 'BOUT', OUT);
        end

        function TrainSVectors(obj)
            %% Train S-Vectors
            t = tic;
            n = fprintf('Training S-Vectors using %d-layer neural net', ...
                obj.SLayers);

            [SSCR , ZSLC] = prepareSVectors(obj);
            [IN, OUT]     = snnTrainer(SSCR, ZSLC, obj.SLayers, ...
                obj.Splits, obj.Save, obj.Parallel);

            jprintf(' ', toc(t), 1, 80 - n);

            obj.SVectors = struct('SIN', IN, 'SOUT', OUT);
        end

        function obj = RunFullPipeline(obj, training2run, toProcess, toSplit)
            %% Run full training pipeline
            if nargin < 2; training2run = [1 , 1 , 1 , 0]; end % Don't train S-Vectors
            if nargin < 3; toProcess    = 0;               end % Process and PCA
            if nargin < 4; toSplit      = 0;               end % Split sets

            if obj.Save
                saveDir = obj.SaveDirectory;
                if ~isfolder(saveDir); mkdir(saveDir); end
            end

            if toProcess
                obj.ProcessCurves;
                obj.SplitDataset(toSplit); % Don't split if already split
                obj.RunPCA;
            end

            if training2run(1); obj.TrainZVectors; end
            if training2run(2); obj.TrainDVectors; end
            if training2run(3); obj.TrainBVectors; end
            if training2run(4); obj.TrainSVectors; end

            if obj.Save; obj.SaveTrainer(saveDir); end
        end

        function obj = SaveTrainer(obj, dnm)
            %% Save this object into a .mat file
            if nargin < 2; dnm = obj.SaveDirectory; end

            if ~isfolder(dnm); mkdir(dnm); end

            % Remove Curves
            crvs       = obj.Curves;
            obj.Curves = [];

            % Remove Images
            imgs = obj.Images;
            obj.storeImages('kill');

            HT  = obj;
            fnm = sprintf('%s%s%s_%dZOpt_%dBOpt', dnm, filesep, obj.HTName, ...
                obj.isOptimized.znn, obj.isOptimized.bnn);
            save(fnm, '-v7.3', 'HT');

            % Replace Curves and Images after saving
            obj.Curves = crvs;
            obj.Images = imgs;
        end

        function LoadZVectors(obj, zdir, pcs)
            %% Load training from .mat file
            if nargin < 2; zdir = sprintf('%s/zvector_training/pcs', pwd); end
            if nargin < 3; pcs  = 1 : obj.NPZ;                             end
            zd      = dir(zdir);
            zd(1:2) = [];
            ZD      = arrayfun(@(x) load(sprintf('%s/%s', ...
                x.folder, x.name)), zd);

            AD = repmat(struct, size(ZD));
            for i = 1 : numel(ZD)
                AD(i).ZIN = ZD(i).IN;
                AD(i).ZOUT = ZD(i).OUT;
            end

            if isempty(obj.ZVectors)
                obj.ZVectors = AD;
            else
                obj.ZVectors(pcs) = [];
                obj.ZVectors      = AD(pcs);
            end
        end

        function OptimizeParameters(obj, mth, pc)
            %% Optimize parameters if given a range of values
            % Input:
            %   obj: this object
            %   mth: which learning method to train [znn|dnn|snn]
            %   pc: continue from most recent PC (0) or redo from 1st PC (1)
            %
            % Output:
            %   params: optimized values from range of parameters
            if nargin < 2; mth = 'znn'; end % Z-Vector
            if nargin < 3; pc  = 0;     end % Pick up from last PC

            switch mth
                case 'znn'
                    %% Run metaparameter optimization for Z-Vector CNN
                    if iscell(obj.NumFilterRange) && ~isempty(obj.ZParams_bak)
                        % Replace previously-optimized with original ranges
                        zparams                  = obj.ZParams_bak;
                        obj.FilterRange          = zparams.FilterRange_bak;
                        obj.NumFilterRange       = zparams.NumFilterRange_bak;
                        obj.DropoutLayer         = zparams.DropoutLayer_bak;
                        obj.InitialLearningRate  = zparams.InitialLearningRate_bak;
                    end

                    flt    = obj.FilterRange;
                    nflt   = obj.NumFilterRange;
                    drp    = obj.DropoutLayer;
                    ilrate = obj.InitialLearningRate;
                    %                     nlay   = obj.FilterLayers;
                    %                     mbsize = obj.MiniBatchSize;
                    %                     maxeps = obj.ZEpochs;

                    % Define optimizable variables
                    params = [
                        optimizableVariable('FilterSize'      , flt,     'Type', 'integer')
                        optimizableVariable('NumFilters1'     , nflt{1}, 'Type', 'integer')
                        optimizableVariable('NumFilters2'     , nflt{2}, 'Type', 'integer')
                        optimizableVariable('NumFilters3'     , nflt{3}, 'Type', 'integer')
                        optimizableVariable('DropoutLayer'    , drp)
                        optimizableVariable('InitialLearnRate', ilrate, 'Transform', 'log')
                        %                         optimizableVariable('FilterLayers'    , nlay,   'Type', 'integer')
                        %                         optimizableVariable('MiniBatchSize'   , mbsize, 'Type', 'integer')
                        %                         optimizableVariable('ZEpochs'       , maxeps, 'Type',  'integer')
                        ];

                    % Get training and validation images and scores
                    if ~isempty(obj.Images)
                        IMGS = obj.Images;
                    else
                        IMGS = arrayfun(@(x) x.getImage('gray', 'upper', ...
                            obj.ImageFnc, [], obj.ManBuf, obj.ArtBuf, ...
                            obj.ImgScl), obj.Curves, 'UniformOutput', 0);
                    end

                    % Normalize images to histogram
                    if ~isempty(obj.Histogram)
                        href  = obj.Histogram.Data;
                        hmth  = obj.Histogram.Tag;
                        nbins = obj.Histogram.NumBins;
                        IMGS  = cellfun(@(x) normalizeImageWithHistogram( ...
                            x, href, hmth, nbins), IMGS, 'UniformOutput', 0);
                    end

                    zscrs = obj.getPCA('pz').PCAScores;
                    ntrn  = numel(obj.getSplits.trnIdx);

                    Timgs = cat(4, IMGS{obj.getSplits.trnIdx});
                    Tscrs = zscrs(1 : ntrn, :);
                    Vimgs = cat(4, IMGS{obj.getSplits.valIdx});
                    Vscrs = zscrs((ntrn + 1) : end, :);

                    % Determine which PC to start from
                    try
                        switch pc
                            case 0
                                % Start from last available PC
                                [bay , fnc] = obj.getOptimizer(mth);
                                pci         = sum(~cellfun(@isempty, bay)) + 1;
                                pcf         = size(Tscrs, 2);
                                pcrng       = pci : pcf;
                            case 'redo'
                                % Restart from beginning
                                [bay , fnc] = deal(cell(size(Tscrs,2), 1));
                                obj.ZFnc    = fnc;
                                obj.ZBay    = bay;
                                obj.ZParams = cell(size(Tscrs,2),1);
                                pci         = 1;
                                pcf         = size(Tscrs, 2);
                                pcrng       = pci : pcf;
                            otherwise
                                % Optimize selected PC or range of PCs
                                [bay , fnc] = obj.getOptimizer;
                                pcrng       = pc;
                        end
                    catch
                        fprintf(2, 'Error determining selected pc %s\n', pc);
                        return;
                    end

                    %% Run Bayes Optimization on all Z-Vector PCs
                    for npc = pcrng
                        fnc{npc} = obj.makeZFnc( ...
                            Timgs, Tscrs, Vimgs, Vscrs(:,npc), npc);

                        % Bayes optimization
                        hrs      = 2; % Hours to run optimization
                        bay{npc} = bayesopt(fnc{npc}, params, ...
                            'MaxTime', hrs*60*60, ...
                            'IsObjectiveDeterministic', 0, ...
                            'UseParallel', 0, 'Verbose', obj.Verbose);

                        % Store into this object for debugging
                        obj.ZFnc{npc}    = fnc{npc};
                        obj.ZBay{npc}    = bay{npc};
                        obj.ZParams{npc} = params;
                    end

                    obj.isOptimized.znn = 1;

                    % Save object afterwards
                    if obj.Save
                        saveDir = obj.SaveDirectory;
                        if ~isfolder(saveDir); mkdir(saveDir); end
                        obj.SaveTrainer(saveDir);
                    end

                case 'bnn'
                    %% Run metaparameter optimization for B-Vector CNN
                    flt    = obj.BaseFilterRange;
                    nflt   = obj.BaseNumFilterRange;
                    drp    = obj.DropoutLayer;
                    ilrate = obj.InitialLearningRate;
                    %                     nlay   = obj.FilterLayers;
                    %                     mbsize = obj.MiniBatchSize;
                    %                     maxeps = obj.ZEpochs;

                    % Define optimizable variables
                    params = [
                        optimizableVariable('FilterSize'      , flt,     'Type', 'integer')
                        optimizableVariable('NumFilters1'     , nflt{1}, 'Type', 'integer')
                        optimizableVariable('NumFilters2'     , nflt{2}, 'Type', 'integer')
                        optimizableVariable('NumFilters3'     , nflt{3}, 'Type', 'integer')
                        optimizableVariable('DropoutLayer'    , drp)
                        optimizableVariable('InitialLearnRate', ilrate, 'Transform', 'log')
                        %                         optimizableVariable('FilterLayers'    , nlay,   'Type', 'integer')
                        %                         optimizableVariable('MiniBatchSize'   , mbsize, 'Type', 'integer')
                        %                         optimizableVariable('ZEpochs'       , maxeps, 'Type',  'integer')
                        ];

                    % Get training and validation images and scores
                    %                     if isempty(obj.Images)
                    if ~isempty(obj.Images)
                        IMGS = obj.Images;
                    else
                        IMGS = arrayfun(@(x) x.getImage('gray', 'upper', ...
                            obj.ImageFnc, [], obj.ManBuf, obj.ArtBuf, ...
                            obj.ImgScl), obj.Curves, 'UniformOutput', 0);
                    end

                    zscrs = obj.getPCA('pz').PCAScores;
                    ntrn  = numel(obj.getSplits.trnIdx);

                    Timgs = cat(4, IMGS{obj.getSplits.trnIdx});
                    Tscrs = zscrs(1 : ntrn, :);
                    Vimgs = cat(4, IMGS{obj.getSplits.valIdx});
                    Vscrs = zscrs((ntrn + 1) : end, :);

                    % Determine which PC to start from
                    try
                        switch pc
                            case 0
                                % Start from last available PC
                                [bay , fnc] = obj.getOptimizer(mth);
                                pci         = sum(~cellfun(@isempty, bay)) + 1;
                                pcf         = size(Tscrs, 2);
                                pcrng       = pci : pcf;
                            case 'redo'
                                % Restart from beginning
                                [bay , fnc] = deal(cell(size(Tscrs,2), 1));
                                obj.ZFnc    = fnc;
                                obj.ZBay    = bay;
                                obj.ZParams = cell(size(Tscrs,2),1);
                                pci         = 1;
                                pcf         = size(Tscrs, 2);
                                pcrng       = pci : pcf;
                            otherwise
                                % Optimize selected PC or range of PCs
                                [bay , fnc] = obj.getOptimizer;
                                pcrng       = pc;
                        end
                    catch
                        fprintf(2, 'Error determining selected pc %s\n', pc);
                        return;
                    end

                    %% Run Bayes Optimization on all Z-Vector PCs
                    for npc = pcrng
                        fnc{npc} = obj.makeZFnc( ...
                            Timgs, Tscrs, Vimgs, Vscrs(:,npc), npc);

                        % Bayes optimization
                        hrs      = 2; % Hours to run optimization
                        bay{npc} = bayesopt(fnc{npc}, params, ...
                            'MaxTime', hrs*60*60, ...
                            'IsObjectiveDeterministic', 0, ...
                            'UseParallel', 0, 'Verbose', obj.Verbose);

                        % Store into this object for debugging
                        obj.ZFnc{npc}    = fnc{npc};
                        obj.ZBay{npc}    = bay{npc};
                        obj.ZParams{npc} = params;
                    end

                    obj.isOptimized.bnn = 1;

                    % Save object afterwards
                    if obj.Save
                        saveDir = obj.SaveDirectory;
                        if ~isfolder(saveDir); mkdir(saveDir); end
                        obj.SaveTrainer(saveDir);
                    end
                case 'dnn'
                    fprintf('Optimizing %s doesn''t work yet!\n', mth);
                case 'snn'
                    fprintf('Optimizing %s doesn''t work yet!\n', mth);
                otherwise
                    fprintf(2, 'Incorrect method %s [znn|dnn|snn]\n', mth);
            end
        end

        function SetOptimizedParameters(obj, req)
            %% Set parameters to best values after optimization
            % Each PC should have it's own set of optimized parameters
            % NOTE: Rename properties to parameter names (get rid of XRange)
            if nargin < 2; req = 'znn'; end % Z-Vector

            switch req
                case 'znn'
                    %% Backup original ranges/values
                    oflds = {'FilterRange' ; 'NumFilterRange' ; ...
                        'DropoutLayer'  ; 'InitialLearningRate'};
                    bflds = cellfun(@(x) sprintf('%s_bak', x), ...
                        oflds, 'UniformOutput', 0);

                    if isempty(obj.ZParams_bak)
                        for fld = 1 : numel(oflds)
                            obj.ZParams_bak.(bflds{fld}) = obj.(oflds{fld});
                        end
                    end

                    %% Extract optimized parameters
                    bay = obj.getOptimizer(req);
                    bp  = arrayfun(@(x) x.bay.bestPoint, ...
                        bay, 'UniformOutput', 0);
                    bp  = cat(1, bp{:});

                    % Combine NumFilter1-3 into 1 column
                    bp.NumFilterRange = ...
                        [bp.NumFilters1 , bp.NumFilters2 , bp.NumFilters3];

                    bp = movevars( ...
                        bp, 'NumFilterRange', 'After', 'FilterSize');
                    bp = removevars( ...
                        bp, {'NumFilters1', 'NumFilters2', 'NumFilters3'});

                    nflds                         = fieldnames(bp);
                    nflds(numel(nflds) - 2 : end) = [];

                    % Replace original properties with values for each PC
                    for fld = 1 : numel(nflds)
                        obj.(oflds{fld}) = cell(obj.NPZ, 1);
                        for pc = 1 : obj.NPZ
                            obj.(oflds{fld}){pc} = bp(pc,:).(nflds{fld});
                        end
                    end
                case 'dnn'
                    fprintf('Optimizing %s doesn''t work yet!\n', mth);
                case 'snn'
                    fprintf('Optimizing %s doesn''t work yet!\n', mth);
                otherwise
                    fprintf(2, 'Incorrect method %s [znn|dnn|snn]\n', mth);
            end
        end
    end

    %% -------------------------- Helper Methods ---------------------------- %%
    methods (Access = public)
        %% Various helper methods
        function splts = getSplits(obj, req)
            %% Return dataset splits
            switch nargin
                case 1
                    splts = obj.Splits;
                case 2
                    if ~isempty(obj.Splits); splts = obj.Splits.(req); end
            end
        end

        function crvs = getCurves(obj, typ)
            %% Return Curves from split datasets
            if nargin < 2
                % Return full structure
                crvs.trnIdx = obj.Curves(obj.getSplits.trnIdx);
                crvs.valIdx = obj.Curves(obj.getSplits.valIdx);
                crvs.tstIdx = obj.Curves(obj.getSplits.tstIdx);
            else
                % Return specific set of Curves
                try
                    crvs = obj.Curves(obj.getSplits.(typ));
                catch
                    fprintf(2, ...
                        'Incorrect type %s [trnIdx|valIdx|tstIdx]\n', typ);
                    crvs = [];
                end
            end
        end

        function pca = getPCA(obj, req)
            %% Return PCA results
            try
                switch nargin
                    case 1
                        pca = obj.PCA;
                    case 2
                        pca = obj.PCA.(req);
                end
            catch
                % If 'req' doesn't exist, create it
                obj.PCA.(req) = [];
                pca           = obj.PCA.(req);
            end
        end

        function z = getZVector(obj, req, pc)
            %% Return Z-Vector training results
            switch nargin
                case 1
                    z = obj.ZVectors;
                case 2
                    z = obj.ZVectors;
                    z = arrayfun(@(x) x.(req), z, 'UniformOutput', 0);
                    z = cat(1, z{:});
                case 3
                    z = obj.ZVectors(pc);
                    z = arrayfun(@(x) x.(req), z, 'UniformOutput', 0);
                    z = cat(1, z{:});
            end
        end

        function b = getBVector(obj, req)
            %% Return Z-Vector training results
            switch nargin
                case 1
                    b = obj.BVectors;
                case 2
                    b = obj.BVectors;
                    b = arrayfun(@(x) x.(req), b, 'UniformOutput', 0);
                    b = cat(1, b{:});
            end
        end

        function d = getDVector(obj, req)
            %% Return D-Vector training results
            switch nargin
                case 1
                    d = obj.DVectors;
                case 2
                    d = obj.DVectors.(req);
            end
        end

        function s = getSVector(obj, req)
            %% Return S-Vector training results
            switch nargin
                case 1
                    s = obj.SVectors;
                case 2
                    s = obj.SVectors(req);
            end
        end

        function [bay , objfn , params] = getOptimizer(obj, req)
            %% Return optimization components
            if nargin < 2; req = 'all'; end

            [bay , objfn , params] = deal([]);
            switch req
                case 'znn'
                    % Return parameters for Z-Vector training
                    bay    = obj.ZBay;
                    objfn  = obj.ZFnc;
                    params = obj.ZParams;

                    if nargout < 2
                        bay = struct( ...
                            'bay', bay, 'objfn', objfn, 'params', params);
                    end

                case 'dnn'
                    % Return parameters for D-Vector training
                case 'snn'
                    % Return parameters for S-Vector training
                case 'all'
                    % Return all parameters
                otherwise
                    fprintf(2, ['Error requesting optimization parameters ' ...
                        '%s\n'], req);
            end
        end

        function fnms = getFigNames(obj)
            %% Return figure names
            fnms = obj.FigNames;
        end

        function obj = storeImages(obj, req)
            %% Store images in a property variable, or remove them for saving
            if nargin < 2; req = 'set'; end

            switch req
                case 'set'
                    % Store images in property
                    imgs = arrayfun(@(x) x.getImage('gray', 'upper', ...
                        obj.ImageFnc, [], obj.ManBuf, obj.ArtBuf, ...
                        obj.ImgScl), obj.Curves, 'UniformOutput', 0);
                    obj.Images = imgs;

                case 'kill'
                    % Remove images (for saving this object)
                    obj.Images = [];

                otherwise
                    fprintf(2, 'Error with req %s [set|kill]\n', req);
                    return;
            end
        end

        function [din , dout] = prepareData(obj, typ, IMGS, ZSCRS)
            %% Prepare neural net input data from raw input to stacked vectors
            % 2D Images: cell array --> 4D vector
            % Z-Vectors: cell array --> 2D data
            if nargin < 1; typ = 'training'; end

            switch typ
                case 'training'
                    % Training indices from combined datasets
                    typstr = 'trnIdx';
                    typidx = 1 : numel(obj.getSplits.trnIdx);

                case 'validation'
                    % Validation indices from combined datasets
                    typstr = 'valIdx';
                    typidx = numel(obj.getSplits.trnIdx) + 1 : ...
                        numel(obj.getSplits.trnIdx) + ...
                        numel(obj.getSplits.valIdx);

                case 'testing'
                    % Not yet implemented
                    fprintf(2, ['Type (%s) not implemented ' ...
                        '[training|validation]\n'], typ);
                    [din , dout] = deal([]);
                    return;

                otherwise
                    fprintf(2, ['Type (%s) should be ' ...
                        '[training|validation|testing]\n'], typ);
                    [din , dout] = deal([]);
                    return;
            end

            if nargin <= 2
                % Cell arrays not inputted, so extract them from dataset
                rin  = arrayfun(@(c) c.getImage('gray', 'upper', ...
                    obj.ImageFnc, [], obj.ManBuf, obj.ArtBuf, obj.ImgScl), ...
                    obj.getCurves(typ), 'UniformOutput', 0);
                rout = obj.getPCA.pz.PCAScores(typidx);
            else
                % Split inputted cell arrays by their indices
                rin  = IMGS(obj.getSplits.(typstr));
                rout = ZSCRS(typidx,:);
            end

            % Vectorize data and store into ZVector input structure
            din  = cat(4, rin{:});
            dout = rout;

            obj.ZVectors.IN.(typ).IMGS  = din;
            obj.ZVectors.IN.(typ).ZSCRS = dout;
        end

        function [pz , pdp , pdx , pdy , pdw , pm , pt , Nz , Nd , Nb , trnIdx , valIdx , tstIdx] = loadHTNetworks(obj, varargin)
            %% loadHTNetworks: Load models and PCA from HypocotylTrainer object
            % Description
            %
            % Usage:
            %   [pz , pdp , pdx , pdy , pdw , pm , pt , Nz , Nd , Nb , ...
            %       trnIdx , valIdx , tstIdx] = obj.loadHTNetworks(varargin)
            %
            % Output:
            %   pz:
            %   pdp:
            %   pdx:
            %   pdy:
            %   pdw:
            %   pm:
            %   pc:
            %   Nz:
            %   Nd:
            %   Nb:
            %   trnIdx:
            %   valIdx:
            %   tstIdx:
            %

            %% Get training and validation indices
            splts  = obj.getSplits;
            trnIdx = splts.trnIdx;
            valIdx = splts.valIdx;
            tstIdx = splts.tstIdx;

            % ---------------------------------------------------------------- %
            % Load Z-Vector models
            zout = obj.getZVector('ZOUT');
            pz   = obj.getPCA('pz');
            Nz   = arrayfun(@(x) x.Net, zout, 'UniformOutput', 0);
            nstr = arrayfun(@(x) sprintf('N%d', x), ...
                1 : numel(Nz), 'UniformOutput', 0);
            Nz   = cell2struct(Nz, nstr);

            % ---------------------------------------------------------------- %
            % Load D-Vector models
            dout = obj.getDVector('DOUT');
            Nd   = dout.Net;
            nstr = arrayfun(@(x) sprintf('N%d', x), ...
                1 : numel(Nd), 'UniformOutput', 0);
            Nd   = cell2struct(Nd, nstr, 2);

            pdp.EigVecs  = dout.EigVecs;
            pdp.MeanVals = dout.MeanVals;

            pdx = dout.pdf.pdx;
            pdy = dout.pdf.pdy;
            pdw = dout.pdf.pdw;

            % ---------------------------------------------------------------- %
            % Load midline and cotyledon patch PCA
            pm = obj.getPCA('pm');
            pt = obj.getPCA('pt');

            % ---------------------------------------------------------------- %
            % Load B-Vector model
            bout = obj.getBVector('BOUT');
            Nb   = bout.Net;

            if nargout == 1
                splts = struct('trnIdx', trnIdx , 'valIdx', valIdx , ...
                    'tstIdx', tstIdx);
                hout  = {pz   ,  pdp  ,  pdx  ,  pdy  ,  pdw  , ...
                    pm , pt , Nz  ,  Nd  ,  Nb  ,  splts}';
                flds  = {'pz' , 'pdp' , 'pdx' , 'pdy' , 'pdw' , ...
                    'pm' , 'pt' , 'Nz' , 'Nd' , 'Nb' , 'splts'}';
                pz    = cell2struct(hout, flds);
            end
        end

        function [bpredict , bcnv, zpredict , zcnv, cpredict , mline , mscore , tscore , escore , sopt , mmaster , msample , mcnv , tsample , tcnv] = getFunctions(obj, seg_lengths, par, vis, toFix, bwid, psz, cepox, tolf, tolx, npxy, npw, myShps, zoomLvl, mpts, mmth, mparams, tscl, tlen , tnwid, tres, ttwid)
            %% getFunctions
            % Defaults
            if nargin < 2;  seg_lengths = obj.SegLengths;  end
            if nargin < 3;  par         = obj.Parallel;    end
            if nargin < 4;  vis         = obj.Visualize;   end
            if nargin < 5;  toFix       = obj.toFix;       end
            if nargin < 6;  bwid        = obj.Bwid;        end
            if nargin < 7;  psz         = obj.PatchSize;   end
            if nargin < 8;  cepox       = obj.CEpochs;     end
            if nargin < 9;  tolf        = obj.TolFun;      end
            if nargin < 10; tolx        = obj.TolX;        end
            if nargin < 11; npxy        = obj.NPF(1:2);    end
            if nargin < 12; npw         = obj.NPF(3);      end
            if nargin < 13; myShps      = obj.Dshape;      end
            if nargin < 14; zoomLvl     = obj.Dzoom;       end
            if nargin < 15; mpts        = obj.MLineSize;   end
            if nargin < 16; mmth        = obj.MLineMethod; end
            if nargin < 17; mparams     = obj.MLineParams; end
            if nargin < 18; tscl        = obj.TScale;      end
            if nargin < 19; tlen        = obj.TLen;        end
            if nargin < 20; tnwid       = obj.TNWid;       end
            if nargin < 21; tres        = obj.TRes;        end
            if nargin < 22; ttwid       = obj.TTWid;       end

            %%
            [pz , pdp , pdx , pdy , pdw , pm , pt , Nz , Nd , Nb] = ...
                obj.loadHTNetworks;

            %
            [bpredict , bcnv , zpredict , zcnv , cpredict , mline , mscore , ...
                tscore , escore , sopt , mmaster, msample , mcnv , ...
                tsample , tcnv] = loadSegmentationFunctions(pz, pdp, pdx, ...
                pdy, pdw, pm, pt, Nz, Nd, Nb, 'par', par, 'vis', vis, ...
                'psz', psz, 'npw', npw, 'seg_lengths', seg_lengths, ...
                'toFix', toFix, 'npxy', npxy, 'bwid', bwid, 'cepox', cepox, ...
                'tolf', tolf, 'tolx', tolx, 'myShps', myShps, ...
                'zoomLvl', zoomLvl, 'mpts', mpts, 'mmth', mmth, ...
                'mparams', mparams, 'tscl', tscl, 'tlen', tlen, ...
                'nwid', tnwid, 'tres', tres, 'twid', ttwid);
        end

        function htname = makeName(obj, toUpdate, sdir, unm)
            %% Auto-Generate a name for this object
            if nargin < 2; toUpdate =  0;             end
            if nargin < 3; sdir     = 'htrainer';     end
            if nargin < 4; unm      = obj.UniqueName; end

            ncrvs = numel(obj.Curves);
            npx   = obj.NPX;
            npy   = obj.NPY;
            npz   = obj.NPZ;
            nzp   = obj.NZP;
            npf   = obj.NPF;
            npd   = obj.NPD;
            rot   = obj.ZRotate;
            rtyp  = obj.ZRotateType;
            itrs  = obj.Recursions;

            % Has Histogram to Normalize to
            h = ~isempty(obj.Histogram);

            % Dataset Splits
            if ~isempty(obj.Splits)
                ntrnd = numel(obj.getSplits('trnIdx'));
            else
                ntrnd = 0;
            end

            if obj.Split2Stitch
                htname = sprintf(['%s_hypocotyltrainer_%dcurves_%dtrained_' ...
                    '%02dpx_%02dpy_%02d-%02dpz_%02dzp_%02dfw_%02dfx_%02dfy_' ...
                    '%02dpd_%dzrotate_%s_%dhistogram_%drecursions'], ....
                    tdate, ncrvs, ntrnd, npx, npy, npz{1}, npz{2}, ...
                    nzp, npf, npd, rot, rtyp, h, itrs);
            else
                htname = sprintf(['%s_hypocotyltrainer_%dcurves_%dtrained_' ...
                    '%02dpx_%02dpy_%02dpz_%02dzp_%02dfw_%02dfx_%02dfy_' ...
                    '%02dpd_%dzrotate_%s_%dhistogram_%drecursions'], ....
                    tdate, ncrvs, ntrnd, npx, npy, npz, nzp, npf, ...
                    npd, rot, rtyp, h, itrs);
            end

            % Append unique name to generated name
            if ~isempty(unm); htname = sprintf('%s_%s', htname, unm); end

            % Overwrite name
            if toUpdate
                obj.HTName        = htname;
                obj.SaveDirectory = sprintf('%s/%s', sdir, unm);
            end
        end

        function prp = getProperty(obj, prp)
            %% Return property of this object
            try
                prp = obj.(prp);
            catch
                fprintf(2, 'Property %s does not exist\n', prp);
            end
        end

        function setProperty(obj, req, val, subreq)
            %% Set requested property if it exists [for private properties]
            if nargin < 4; subreq = []; end

            try
                if isempty(subreq)
                    obj.(req) = val;
                else
                    obj.(req).(subreq) = val;
                end
            catch
                fprintf(2, 'Property %s.%s not found\n', req, subreq);
            end
        end
    end

    %% ------------------------- Private Methods --------------------------- %%
    methods (Access = private)
        %% Private helper methods
        function [SSCR , ZSLC] = prepareSVectors(obj)
            %% Process x-/y-coordinate PCA scores and Z-Vector slices
            t = tic;
            n = fprintf(['Prepping Z-Vector slices and ' ...
                'S-Vector scores to train S-Vectors']);

            % Combine PC scores for X-/Y-Coordinates
            SSCR = [obj.PCA.px.PCAScores , obj.PCA.py.PCAScores];

            % Re-shape Z-Vectors to Z-Slices
            ZSLC = zVectorConversion( ...
                obj.PCA.pz.InputData, obj.Curves(1).NumberOfSegments, ...
                numel(obj.Splits.trnIdx), 'rev');
            % ZSLC = [ZSLC , addNormalVector(ZSLC)]; % Exclude normal vector

            % Add Z-Patch PC scores to Z-Slice
            ZSLC = [ZSLC , obj.PCA.pp.PCAScores];

            jprintf(' ', toc(t), 1, 80 - n);
        end

        function ZFnc = makeZFnc(obj, Timgs, Tscrs, Vimgs, Vscrs, pc)
            %% Create objective function for optimization
            ZFnc = @valErrorFun;

            function [valErr , cons , fnm] = valErrorFun(params)
                %% Train network with parameters and evaluate validation error
                % Load parameters
                flt    = params.FilterSize;
                nflt   = [params.NumFilters1 , params.NumFilters2 , ...
                    params.NumFilters3];
                drp    = params.DropoutLayer;
                ilrate = params.InitialLearnRate;
                %                 nlay   = params.FilterLayers;
                %                 mbsize = params.MiniBatchSize;
                %                 maxeps = params.ZEpochs;

                %% Default properties [no to optimize]
                nlay   = obj.FilterLayers;
                mbsize = obj.MiniBatchSize;
                maxeps = obj.ZEpochs;

                %% Misc properties
                sav = 0; % Don't save output between optimizations
                par = obj.Parallel;
                vis = obj.Visualize;
                vrb = obj.Verbose;

                %%
                [~ , ZOUT] = znnTrainer(Timgs, Tscrs, obj.Splits, pc, ...
                    'FltRng', flt, 'NumFltRng', nflt, 'FltLayers', nlay, ...
                    'MBSize', mbsize, 'Dropout', drp, 'ILRate', ilrate, ...
                    'MaxEps', maxeps, 'Vimgs', Vimgs, 'Vscrs', Vscrs, ...
                    'Save', sav, 'Parallel', par, ...
                    'Verbose', vrb, 'Visualize', vis);

                %% Get data from output
                net    = ZOUT.Net;
                valErr = ZOUT.ValErr;

                %% Save results in a .mat file
                outdir = sprintf('optimization%spc%02d', filesep, pc);
                fnm    = sprintf('%s%s%s_optimization_%0.04ferror.mat', ...
                    outdir, filesep, tdate, valErr);
                BAYES  = struct('Net', net, 'Error', valErr, ...
                    'Params', table2struct(params));

                if ~isfolder(outdir); mkdir(outdir); end

                save(fnm, '-v7.3', 'BAYES');
                cons = [];
            end
        end
    end
end
