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
        SaveDirectory
        Splits

        % Curve Segment Properties
        ContourVsn
        ImageFnc
        SegmentSize
        SegmentSteps

        % Dataset Splitting
        TrainingPct
        ValidationPct
        TestingPct

        % PCA Parameters
        NPX
        NPY
        NPZ
        NZP
        NPM
        ZNorm
        ZShape

        % Z-Vector Attributes
        AddMid
        ZRotate
        ZRotateType
        Split2Stitch
        NSplt

        % Midline Patch Attributes
        PatchSize

        % Z-Vector CNN
        FilterRange
        NumFilterRange
        FilterLayers
        DropoutLayer
        MiniBatchSize
        MaxEpochs
        InitialLearningRate

        % D-Vector NN
        Iterations
        FoldMethod
        toFix
        SegLengths
        NPF
        NPD
        DLayers
        DTrainFnc

        % BasePoint CNN
        BasePoint
        BaseRows
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
    end

    properties (Access = protected)
        SplitCurves
        PCA
        isOptimized
        ZVectors
        ZFnc
        ZBay
        ZParams
        ZParams_bak
        bOptimized
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
                'HTName'              , []     ; ...
                'SaveDirectory'       , pwd    ; ...
                'SegmentSize'         , 25     ; ...
                'SegmentSteps'        , 1      ; ...
                'ContourVsn'          , 'Clip' ; ...
                'ImageFnc'            , 'left' ; ...

                % Dataset Splitting
                'TrainingPct'         , 0.8 ; ...
                'ValidationPct'       , 0.1 ; ...
                'TestingPct'          , 0.1 ; ...

                % PCA Parametersrunning
                'NPX'                 , 0 ; ... % 6
                'NPY'                 , 0 ; ... % 6
                'NPZ'                 , 0 ; ... % 10
                'NZP'                 , 0 ; ... % 10
                'NPM'                 , 0 ; ... % 20
                'ZNorm'               , struct('ps', 0, 'pz', 0, 'pp', 0) ; ...
                'ZShape'              , struct('ps', 0, 'pz', 0, 'pp', 0) ; ...

                % Z-Vector Attributes
                'AddMid'              , 0     ; ...
                'ZRotate'             , 0     ; ...
                'ZRotateType'         , 'rad' ; ...
                'Split2Stitch'        , 0     ; ...
                'NSplt'               , 25    ; ...

                % Midline Patch Attributes
                'PatchSize'           , 20    ; ...

                % Z-Vector CNN
                'FilterRange'         , 7            ; ...
                'NumFilterRange'      , [10 , 5 , 3] ; ...
                'FilterLayers'        , 1            ; ...
                'DropoutLayer'        , 0.2          ; ...
                'MiniBatchSize'       , 128          ; ...
                'MaxEpochs'           , 300          ; ...
                'InitialLearningRate' , 1e-4         ; ...

                % D-Vector NN
                'Iterations'          , 20                  ; ...
                'FoldMethod'          , 'local'             ; ...
                'toFix'               , 0                   ; ...
                'SegLengths'          , [53 , 52 , 53 , 51] ; ...
                'NPF'                 , 10                  ; ...
                'NPD'                 , 10                  ; ...
                'DLayers'             , 5                   ; ...
                'DTrainFnc'           , 'trainlm'           ; ...

                % BasePoint CNN
                'BasePoint'               , 0           ; ...
                'BaseRows'                , 10          ;
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
                'Figures'             , 1 : 4  ...
                };

            obj = classInputParser(obj, prps, deflts, vargs);

            if isempty(obj.HTName)
                % Auto-Generate Name
                obj.HTName = makeName(obj);
            end

        end

        function ProcessCurves(obj)
            %% Configure segment length and step size
            t = tic;
            n = fprintf('Pre-Processing data for %d Cuves', numel(obj.Curves));

            arrayfun(@(c) c.setProperty('SEGMENTSIZE', obj.SegmentSize), ...
                obj.Curves, 'UniformOutput', 0);
            arrayfun(@(c) c.setProperty('SEGMENTSTEPS', obj.SegmentSteps), ...
                obj.Curves, 'UniformOutput', 0);
            arrayfun(@(c) c.getSegmentedOutline, ...
                obj.Curves, 'UniformOutput', 0);

            jprintf(' ', toc(t), 1, 80 - n);
        end

        function SplitDataset(obj, toSplit)
            %% Split Curves into training, validation, and testing sets
            % Validation and Testing sets shouldn't be seen by training algorithm
            t = tic;
            if toSplit
                n = fprintf('Splitting into training,validation,testing sets');

                % Get indices of split datasets
                numCrvs    = numel(obj.Curves);
                obj.Splits = splitDataset(1 : numCrvs, ...
                    obj.TrainingPct, obj.ValidationPct, obj.TestingPct);
            else
                n = fprintf('Data already split');
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

            [px , py , pz , pp , pm] = hypoquantylPCA(C, obj.Save, ...
                'vsn', obj.ContourVsn, 'fnc', obj.ImageFnc, ...
                'pcx', obj.NPX, 'pcy', obj.NPY, 'pcz', obj.NPZ, 'pcp', obj.NZP, ...
                'pcm', obj.NPM, 'addMid', obj.AddMid, 'zrotate', obj.ZRotate, ...
                'rtyp', obj.ZRotateType, 'znorm', obj.ZNorm, 'zshp', obj.ZShape, ...
                'split2stitch', obj.Split2Stitch, 'nsplt', obj.NSplt, ...
                'bdsp', obj.BasePoint, 'sdir', obj.SaveDirectory);

            obj.PCA = struct('px', px, 'py', py, 'pz', pz, 'pp', pp, 'pm', pm);
        end

        function TrainZVectors(obj)
            %% Train Z-Vectors
            t = tic;

            if obj.Split2Stitch
                n    = fprintf('Preparing %d images and [%d|%d] Z-Vectors PC scores', ...
                    numel(obj.getSplits('trnIdx')), obj.NPZ{1}, obj.NPZ{2});
                flds = fieldnames(obj.PCA.pz);
                vtyp = flds{end};
            else
                n = fprintf('Preparing %d images and %d Z-Vectors PC scores', ...
                    numel(obj.getSplits('trnIdx')), obj.NPZ);
            end

            if ~isempty(obj.Images)
                IMGS = obj.Images(obj.Splits.trnIdx);
                IMGS = cat(4, IMGS{:});
            else
                IMGS = arrayfun(@(c) c.getImage(obj.ImageFnc), ...
                    obj.Curves(obj.Splits.trnIdx), 'UniformOutput', 0);
                IMGS = cat(4, IMGS{:});
            end

            % Stitch midpoints-tangents
            if obj.Split2Stitch
                ZSCRS = [obj.PCA.pz.mids.PCAScores(1 : size(IMGS,4)) , ...
                    obj.PCA.pz.(vtyp).PCAScores(1 : size(IMGS,4))];
            else
                ZSCRS = obj.PCA.pz.PCAScores(1 : size(IMGS,4));
            end

            jprintf(' ', toc(t), 1, 80 - n);

            %%
            [IN , OUT] = deal(cell(1, size(ZSCRS,2)));

            if isempty(obj.isOptimized)
                obj.isOptimized.znn = 0;
            end

            if obj.isOptimized.znn
                % Set PC-optimized parameters if not already
                if ~iscell(obj.FilterRange)
                    obj.SetOptimizedParameters('znn');
                end

                % Loop through optimized parameters
                for pc = 1 : size(ZSCRS,2)
                    [IN{pc}, OUT{pc}] = znnTrainer(IMGS, ZSCRS, obj.Splits, pc, ...
                        'Save', obj.Save, 'FltRng', obj.FilterRange{pc}, ...
                        'NumFltRng', obj.NumFilterRange{pc}, ...
                        'MBSize', obj.MiniBatchSize, ...
                        'Dropout', obj.DropoutLayer{pc}, ...
                        'ILRate', obj.InitialLearningRate{pc}, ...
                        'MaxEps', obj.MaxEpochs, ...
                        'Parallel', obj.Parallel, 'Verbose', obj.Verbose);
                end
            else
                % Use same parameters for each PC [old method]
                for pc = 1 : size(ZSCRS,2)
                    [IN{pc}, OUT{pc}] = znnTrainer(IMGS, ZSCRS, obj.Splits, pc, ...
                        'Save', obj.Save, 'FltRng', obj.FilterRange, ...
                        'NumFltRng', obj.NumFilterRange, ...
                        'MBSize', obj.MiniBatchSize, 'Dropout', obj.DropoutLayer, ...
                        'ILRate', obj.InitialLearningRate, 'MaxEps', obj.MaxEpochs, ...
                        'Parallel', obj.Parallel, 'Verbose', obj.Verbose);
                end
            end

            obj.ZVectors = struct('ZIN', IN, 'ZOUT', OUT);
        end

        function TrainDVectors(obj)
            %% Train D-Vectors
            t = tic;
            n = fprintf('Training D-Vectors through %d recursive iterations [%s folding]', ...
                obj.Iterations, obj.FoldMethod);

            IMGS  = arrayfun(@(c) c.getImage(obj.ImageFnc), ...
                obj.getCurves('trnIdx'), 'UniformOutput', 0);
            CNTRS = arrayfun(@(c) c.getTrace(obj.ContourVsn, obj.ImageFnc), ...
                obj.getCurves('trnIdx'), 'UniformOutput', 0);

            nfigs           = numel(obj.Figures);
            cidxs           = pullRandom(obj.Splits.trnIdx, nfigs, 0);
            [IN, OUT, fnms] = dnnTrainer(IMGS, CNTRS, obj.Iterations, ...
                obj.NSplt, cidxs, obj.FoldMethod, obj.toFix, obj.SegLengths, ...
                obj.NPF, obj.NPD, obj.DLayers, obj.DTrainFnc, ...
                obj.Save, obj.Visualize, obj.Parallel);

            jprintf(' ', toc(t), 1, 80 - n);

            obj.DVectors = struct('DIN', IN, 'DOUT', OUT);
            obj.FigNames = fnms;
        end

        function TrainBVectors(obj)
            %% Train B-Vectors: base point displacements
            t = tic;
            n = fprintf('Preparing %d images and base points', ...
                numel(obj.getSplits('trnIdx')));

            if ~isempty(obj.Images)
                IMGS = obj.Images(obj.Splits.trnIdx);
                IMGS = cat(4, IMGS{:});
            else
                IMGS = arrayfun(@(c) c.getImage(obj.ImageFnc), ...
                    obj.Curves(obj.Splits.trnIdx), 'UniformOutput', 0);
                IMGS = cat(4, IMGS{:});
            end

            nrows = obj.BaseRows;
            isz   = size(IMGS(:,:,:,1), 1);
            irows = isz - nrows : isz;
            IMGS  = IMGS(irows,:,:,:);

            BPTS = cell2mat(arrayfun(@(x) x.BasePoint(1), ...
                obj.Curves(obj.Splits.trnIdx), 'UniformOutput', 0));

            jprintf(' ', toc(t), 1, 80 - n);

            %%
            [IN , OUT] = znnTrainer(IMGS, BPTS, obj.Splits, 1, ...
                'Save', obj.Save, 'FltRng', obj.BaseFilterRange, ...
                'NumFltRng', obj.BaseNumFilterRange, ...
                'MBSize', obj.BaseMiniBatchSize, 'Dropout', obj.BaseDropoutLayer, ...
                'ILRate', obj.BaseInitialLearningRate, 'MaxEps', obj.MaxEpochs, ...
                'Parallel', obj.Parallel, 'Verbose', obj.Verbose);

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

        function obj = RunFullPipeline(obj, training2run, toSplit)
            %% Run full training pipeline
            if nargin < 2; training2run = [1 , 1 , 1 , 0]; end % Don't train S-Vectors
            if nargin < 3; toSplit      = 0;               end % Split sets

            if obj.Save
                saveDir = obj.SaveDirectory;
                if ~isfolder(saveDir)
                    mkdir(saveDir);
                end
            end

            obj.ProcessCurves;
            obj.SplitDataset(toSplit); % Don't split if already split
            obj.RunPCA;

            if training2run(1); obj.TrainZVectors; end
            if training2run(2); obj.TrainDVectors; end
            if training2run(3); obj.TrainBVectors; end
            if training2run(4); obj.TrainSVectors; end

            if obj.Save
                obj.SaveTrainer(saveDir);
            end
        end

        function obj = SaveTrainer(obj, dnm)
            %% Save this object into a .mat file
            if nargin < 2; dnm = obj.SaveDirectory; end

            if ~isfolder(dnm)
                mkdir(dnm);
            end

            % Remove Curves
            crvs       = obj.Curves;
            obj.Curves = [];

            HT  = obj;
            fnm = sprintf('%s%s%s', dnm, filesep, obj.HTName);
            save(fnm, '-v7.3', 'HT');

            % Replace Curves after saving
            obj.Curves = crvs;
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
                    if iscell(obj.FilterRange)
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
                    %                     maxeps = obj.MaxEpochs;

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
                        %                         optimizableVariable('MaxEpochs'       , maxeps, 'Type',  'integer')
                        ];

                    % Get training and validation images and scores
                    %                     if isempty(obj.Images)
                    if obj.toStore
                        obj.storeImages;
                        imgs = obj.Images;
                    else
                        imgs = arrayfun(@(x) x.getImage(obj.ImageFnc), ...
                            obj.Curves, 'UniformOutput', 0);
                    end

                    zscrs = obj.getPCA('pz').PCAScores;
                    ntrn  = numel(obj.getSplits.trnIdx);

                    Timgs = cat(4, imgs{obj.getSplits.trnIdx});
                    Tscrs = zscrs(1 : ntrn, :);
                    Vimgs = cat(4, imgs{obj.getSplits.valIdx});
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
                            'MaxTime', hrs*60*60, 'IsObjectiveDeterministic', 0, ...
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

                        if ~isfolder(saveDir)
                            mkdir(saveDir);
                        end

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
                    %                     maxeps = obj.MaxEpochs;

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
                        %                         optimizableVariable('MaxEpochs'       , maxeps, 'Type',  'integer')
                        ];

                    % Get training and validation images and scores
                    %                     if isempty(obj.Images)
                    if obj.toStore
                        obj.storeImages;
                        imgs = obj.Images;
                    else
                        imgs = arrayfun(@(x) x.getImage(obj.ImageFnc), ...
                            obj.Curves, 'UniformOutput', 0);
                    end

                    zscrs = obj.getPCA('pz').PCAScores;
                    ntrn  = numel(obj.getSplits.trnIdx);

                    Timgs = cat(4, imgs{obj.getSplits.trnIdx});
                    Tscrs = zscrs(1 : ntrn, :);
                    Vimgs = cat(4, imgs{obj.getSplits.valIdx});
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
                            'MaxTime', hrs*60*60, 'IsObjectiveDeterministic', 0, ...
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

                        if ~isfolder(saveDir)
                            mkdir(saveDir);
                        end

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
            % NOTE: Rename properties to actual parameter names (get rid of XRange)
            if nargin < 2; req = 'znn'; end % Z-Vector

            switch req
                case 'znn'
                    %% Backup original ranges/values
                    %                     oflds = {'FilterRange' ; 'NumFilterRange' ; 'MiniBatchSize' ; ...
                    %                         'DropoutLayer'  ; 'InitialLearningRate' ; 'MaxEpochs'};
                    oflds = {'FilterRange' ; 'NumFilterRange' ; ...
                        'DropoutLayer'  ; 'InitialLearningRate'};
                    bflds = cellfun(@(x) sprintf('%s_bak', x), oflds, 'UniformOutput', 0);

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
                    if ~isempty(obj.Splits)
                        splts = obj.Splits.(req);
                    end
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
            switch nargin
                case 1
                    pca = obj.PCA;
                case 2
                    pca = obj.PCA.(req);
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
            if nargin < 2
                req = 'all';
            end

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
                    fprintf(2, 'Error requesting optimization parameters %s\n', ...
                        req);
            end
        end

        function fnms = getFigNames(obj)
            %% Return figure names
            fnms = obj.FigNames;
        end

        function obj = storeImages(obj, req)
            %% Store images in a property variable, or remove them for saving
            if nargin < 2
                req = 'set';
            end

            switch req
                case 'set'
                    % Store images in property
                    imgs  = arrayfun(@(x) x.getImage(obj.ImageFnc), ...
                        obj.Curves, 'UniformOutput', 0);
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
            if nargin < 1
                typ = 'training';
            end

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
                    fprintf(2, 'Type (%s) not implemented [training|validation]\n', ...
                        typ);
                    [din , dout] = deal([]);
                    return;

                otherwise
                    fprintf(2, 'Type (%s) should be [training|validation|testing]\n', ...
                        typ);
                    [din , dout] = deal([]);
                    return;
            end

            if nargin <= 2
                % Cell arrays not inputted, so extract them from dataset
                rin  = arrayfun(@(c) c.getImage(obj.ImageFnc), ...
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

        function [pz , pdp , pdx , pdy , pdw , pm , Nz , Nd , Nb , trnIdx , valIdx , tstIdx] = loadHTNetworks(obj, varargin)
            %% loadHTNetworks: Load models and PCA from HypocotylTrainer object
            % Description
            %
            % Usage:
            %   [pz , pdp , pdx , pdy , pdw , pm , Nz , Nd , Nb , ...
            %       trnIdx , valIdx , tstIdx] = obj.loadHTNetworks(varargin)
            %
            % Output:
            %   pz:
            %   pdp:
            %   pdx:
            %   pdy:
            %   pdw:
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

            % ---------------------------------------------------------------------------- %
            % Load Z-Vector models
            zout = obj.getZVector('ZOUT');
            pz   = obj.getPCA('pz');
            Nz   = arrayfun(@(x) x.Net, zout, 'UniformOutput', 0);
            nstr = arrayfun(@(x) sprintf('N%d', x), ...
                1 : numel(Nz), 'UniformOutput', 0);
            Nz   = cell2struct(Nz, nstr);

            % ---------------------------------------------------------------------------- %
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

            % ---------------------------------------------------------------------------- %
            % Load midline patch PCA
            pm = obj.getPCA('pm');

            % ---------------------------------------------------------------------------- %
            % Load B-Vector model
            bout = obj.getBVector('BOUT');
            Nb   = bout.Net;

            if nargout == 1
                splts = struct('trnIdx', trnIdx , 'valIdx', valIdx , 'tstIdx', tstIdx);
                hout  = {pz   , pdp   , pdx   , pdy   , pdw   , Nz   , Nd   , splts}';
                flds  = {'pz' , 'pdp' , 'pdx' , 'pdy' , 'pdw' , 'Nz' , 'Nd' , 'splts'}';
                pz    = cell2struct(hout, flds);
            end
        end

        function [bpredict , zpredict , cpredict , mline , msample , mcnv , mgrade , sopt] = getFunctions(obj, seg_lengths, par, vis, toFix, bwid, psz, nopts, varargin)
            %% getFunctions
            %
            %

            %%
            [pz , pdp , pdx , pdy , pdw , pm , Nz , Nd , Nb] = ...
                obj.loadHTNetworks;

            %
            scrs  = pm.PCAScores;
            pvecs = pm.EigVecs;
            pmns  = pm.MeanVals;

            %
            bpredict  = @(i,w) double(Nb.predict(i(w,:)));
            zpredict  = @(i,r) predictZvectorFromImage(i, Nz, pz, r);
            cpredict  = @(i,zs) displacementWindowPredictor(i, 'Nz', Nz, 'pz', pz, 'Nd', Nd, ...
                'pdp', pdp, 'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'z', zs, ...
                'toFix', toFix, 'seg_lengths', seg_lengths, 'par', par, 'vis', vis);
            mline     = @(c) nateMidline(c);
            msample   = @(i,m) sampleMidline(i, m, 0, psz, 'full');
            mcnv      = @(m) pcaProject(m(:)', pvecs, pmns, 'sim2scr');
            mgrade    = computeKSdensity(scrs, bwid);

            % Optimize with nopts iterations
            if nopts
                sopt = @(i) segmentationOptimizer(i, 'Nz', Nz, 'pz', pz, 'Nd', Nd, ...
                    'pdp', pdp, 'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'pm', pm, ...
                    'toFix', toFix, 'seg_lengths', seg_lengths, 'bwid', bwid, ...
                    'nopts', nopts, 'par', par, 'vis', vis, 'z2c', 1);
            else
                sopt = [];
            end
        end

        function prp = getProperty(obj, prp)
            %% Return property of this object
            try
                prp = obj.(prp);
            catch e
                fprintf(2, 'Property %s does not exist\n%s\n', ...
                    prp, e.getReport);
            end
        end

        function obj = setProperty(obj, req, val)
            %% Set requested property if it exists [for private properties]
            try
                obj.(req) = val;
            catch e
                fprintf(2, 'Property %s not found\n%s\n', req, e.getReport);
            end
        end
    end

    %% ------------------------- Private Methods --------------------------- %%
    methods (Access = private)
        %% Private helper methods
        function htname = makeName(obj)
            %% Auto-Generate a name for this object
            ncrvs = numel(obj.Curves);
            npx   = obj.NPX;
            npy   = obj.NPY;
            npz   = obj.NPZ;
            nzp   = obj.NZP;
            npf   = obj.NPF;
            npd   = obj.NPD;
            rot   = obj.ZRotate;
            rtyp  = obj.ZRotateType;
            itrs  = obj.Iterations;

            if ~isempty(obj.Splits)
                ntrnd = numel(obj.getSplits('trnIdx'));
            else
                ntrnd = 0;
            end

            if obj.Split2Stitch
                htname = sprintf('%s_hypocotyltrainer_%dcurves_%dtrained_%02dpx_%02dpy_%02-%02ddpz_%02dzp_%02dpf_%02dpd_%dzrotate_%s_%diterations', ....
                    tdate, ncrvs, ntrnd, npx, npy, npz{1}, npz{2}, ...
                    nzp, nzp, npf, npd, rot, rtyp, itrs);
            else
                htname = sprintf('%s_hypocotyltrainer_%dcurves_%dtrained_%02dpx_%02dpy_%02dpz_%02dzp_%02dpf_%02dpd_%dzrotate_%s_%diterations', ....
                    tdate, ncrvs, ntrnd, npx, npy, npz, nzp, npf, ...
                    npd, rot, rtyp, itrs);
            end
        end

        function [SSCR , ZSLC] = prepareSVectors(obj)
            %% Process x-/y-coordinate PCA scores and Z-Vector slices
            t = tic;
            n = fprintf('Prepping Z-Vector slices and S-Vector scores to train S-Vectors');

            % Combine PC scores for X-/Y-Coordinates
            SSCR = [obj.PCA.px.PCAScores , obj.PCA.py.PCAScores];

            % Re-shape Z-Vectors to Z-Slices
            ZSLC = zVectorConversion( ...
                obj.PCA.pz.InputData, obj.Curves(1).NumberOfSegments, ...
                numel(obj.Splits.trnIdx), 'rev');
            %             ZSLC = [ZSLC , addNormalVector(ZSLC)]; % Exclude normal vector

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
                nflt   = [params.NumFilters1 , params.NumFilters2 , params.NumFilters3];
                drp    = params.DropoutLayer;
                ilrate = params.InitialLearnRate;
                %                 nlay   = params.FilterLayers;
                %                 mbsize = params.MiniBatchSize;
                %                 maxeps = params.MaxEpochs;

                %% Default properties [no to optimize]
                nlay   = obj.FilterLayers;
                mbsize = obj.MiniBatchSize;
                maxeps = obj.MaxEpochs;

                %% Misc properties
                sav = 0; % Don't save output between optimizations
                par = obj.Parallel;
                vis = obj.Visualize;
                vrb = obj.Verbose;

                %%
                [~, ZOUT] = znnTrainer(Timgs, Tscrs, obj.Splits, pc, ...
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

                if ~isfolder(outdir)
                    mkdir(outdir);
                end

                save(fnm, '-v7.3', 'BAYES');
                cons = [];
            end
        end
    end
end
