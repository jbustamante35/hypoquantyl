%% HypocotylTrainer: class for sections of contours for a CircuitJB object
% Descriptions

classdef HypocotylTrainer < handle
    properties (Access = public)
        Curves
        
        % Curve Segment Properties
        SegmentSize
        SegmentSteps
        
        % Dataset Splitting
        TrainingPct
        ValidationPct
        TestingPct
        
        % PCA Parameters
        PCX
        PCY
        PCZ
        PCP
        AddMid
        
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
        FoldPredictions
        PDC
        
        % S-Vector NN
        SLayers
        TrainFnc
        
        % Miscellaneous Properties
        Save
        Visualize
        Parallel
        Verbose
        Figures
        
    end
    
    properties (Access = protected)
        SplitCurves
        Splits
        PCA
        ZVectors
        ObjFn
        ObjBay
        DVectors
        SVectors
        FigNames
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
                'SegmentSize'         , 25 ; ...
                'SegmentSteps'        , 1 ; ...
                
                % Dataset Splitting
                'TrainingPct'         , 0.8 ; ...
                'ValidationPct'       , 0.1 ; ...
                'TestingPct'          , 0.1 ; ...
                
                % PCA Parameters
                'PCX'                 , 3 ; ...
                'PCY'                 , 3 ; ...
                'PCZ'                 , 20 ; ...
                'PCP'                 , 10 ; ...
                'AddMid'              , 0 ; ...
                
                % Z-Vector CNN
                'FilterRange'         , 6 : 2 : 10 ; ...
                'NumFilterRange'      , 3 : 2 : 10 ; ...
                'FilterLayers'        , 1 ; ...
                'DropoutLayer'        , 0.2 ; ...
                'MiniBatchSize'       , 128 ; ...
                'MaxEpochs'           , 300 ; ...
                'InitialLearningRate' , 1e-4 ; ...
                
                % D-Vector NN
                'Iterations'          , 15 ; ...
                'FoldPredictions'     , 1  ; ...
                'PDC'                 , 10 ; ...
                
                % S-Vector NN
                'SLayers'             , 5 ; ...
                'TrainFnc'            , 'trainlm' ; ...
                
                % Miscellaneous Properties
                'Save'                , 0 ; ...
                'Visualize'           , 0 ; ...
                'Parallel'            , 0 ; ...
                'Verbose'             , 0 ; ...
                'Figures'             , 1 : 4  ...
                };
            
            obj = classInputParser(obj, prps, deflts, vargs);
            
        end
        
        function obj = ProcessCurves(obj)
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
        
        function obj = SplitDataset(obj)
            %% Split Curves into training, validation, and testing sets
            % Validation and Testing sets shouldn't be seen by any training algorithms
            t = tic;
            n = fprintf('Splitting into training,validation,testing sets');
            
            % Get indices of split datasets
            numCrvs    = numel(obj.Curves);
            obj.Splits = splitDataset(1 : numCrvs, ...
                obj.TrainingPct, obj.ValidationPct, obj.TestingPct);
            
            % Split Curves into specific sets
            obj.SplitCurves = struct( ...
                'training',   obj.Curves(obj.getSplits.trnIdx) , ...
                'validation', obj.Curves(obj.getSplits.valIdx), ...
                'testing',    obj.Curves(obj.getSplits.tstIdx));
            
            jprintf(' ', toc(t), 1, 80 - n);
        end
        
        function obj = RunPCA(obj, mth)
            %% Run PCA functions
            % PCA can be run with method 1 (training only) or method 2
            % (training and validation, testing untouched [default])
            if nargin < 2
                mth = 2;
            end
            
            switch mth
                case 1
                    % Run with only training set
                    [px, py, pz, pp] = hypoquantylPCA( ...
                        obj.Curves(obj.Splits.trnIdx), obj.Save, obj.PCX, ...
                        obj.PCY, obj.PCZ, obj.PCP, obj.AddMid);
                case 2
                    % Run with training and validation sets
                    C = [obj.getSplitCurves('training') ; ...
                        obj.getSplitCurves('validation')];
                    
                    % Order is training in front, validation in back
                    [px, py, pz, pp] = hypoquantylPCA(C, obj.Save, obj.PCX, ...
                        obj.PCY, obj.PCZ, obj.PCP, obj.AddMid);
                otherwise
                    fprintf(2, 'Method %d not implemented [1|2]\n', mth);
                    return;
            end
            
            obj.PCA = struct('px', px, 'py', py, 'pz', pz, 'pp', pp);
            
        end
        
        function obj = TrainZVectors(obj)
            %% Train Z-Vectors
            t = tic;
            n = fprintf('Preparing %d images and %d Z-Vectors PC scores', ...
                numel(obj.Curves(obj.Splits.trnIdx)), obj.PCZ);
            
            ZSCRS = obj.PCA.pz.PCAScores;
            IMGS  = arrayfun(@(c) c.getImage, ...
                obj.Curves(obj.Splits.trnIdx), 'UniformOutput', 0);
            IMGS  = cat(4, IMGS{:});
            
            jprintf(' ', toc(t), 1, 80 - n);
            
            [IN, OUT] = znnTrainer(IMGS, ZSCRS, obj.Splits, 'Save', obj.Save, ...
                'FltRng', obj.FilterRange, 'NumFltRng', obj.NumFilterRange, ...
                'MBSize', obj.MiniBatchSize, 'Dropout', obj.DropoutLayer, ...
                'ILRate', obj.InitialLearningRate, 'MaxEps', obj.MaxEpochs, ...
                'Parallel', obj.Parallel, 'Verbose', obj.Verbose);
            
            obj.ZVectors = struct('ZIN', IN, 'ZOUT', OUT);
            
        end
        
        function obj = TrainDVectors(obj)
            %% Train D-Vectors
            t = tic;
            n = fprintf('Training D-Vectors through %d recursive iterations [Folding = %s]', ...
                obj.Iterations, num2str(obj.FoldPredictions));
            
            IMGS  = arrayfun(@(c) double(c.getImage), ...
                obj.Curves(obj.Splits.trnIdx), 'UniformOutput', 0);
            CNTRS = arrayfun(@(c) c.getTrace, ...
                obj.Curves(obj.Splits.trnIdx), 'UniformOutput', 0);
            
            nfigs           = numel(obj.Figures);
            [IN, OUT, fnms] = dnnTrainer(IMGS, CNTRS, obj.Iterations, ...
                nfigs, obj.FoldPredictions, obj.PDC, ...
                obj.Save, obj.Visualize, obj.Parallel);
            
            jprintf(' ', toc(t), 1, 80 - n);
            
            obj.DVectors = struct('DIN', IN, 'DOUT', OUT);
            obj.FigNames = fnms;
            
        end
        
        function obj = TrainSVectors(obj)
            %% Train S-Vectors
            t = tic;
            n = fprintf('Training S-Vectors using %d-layer neural net', ...
                obj.SLayers);
            
            [SSCR , ZSLC] = prepareSVectors(obj);
            
            [IN, OUT] = snnTrainer(SSCR, ZSLC, obj.SLayers, ...
                obj.Splits, obj.Save, obj.Parallel);
            
            jprintf(' ', toc(t), 1, 80 - n);
            
            obj.SVectors = struct('SIN', IN, 'SOUT', OUT);
            
        end
        
        function obj = RunFullPipeline(obj, training2run)
            %% Run full training pipeline
            if nargin < 2
                % Default to not train S-Vectors
                training2run = [1 , 1 , 0];
            end
            
            obj.ProcessCurves;
            obj.SplitDataset;
            obj.RunPCA;
            
            if training2run(1); obj.TrainZVectors; end
            if training2run(2); obj.TrainDVectors; end
            if training2run(3); obj.TrainSVectors; end
            
        end
        
        function [obj , params] = OptimizeParameters(obj, mth)
            %% Optimize parameters if given a range of values
            % Input:
            %   obj: this object
            %   mth: which learning method to train [znn|dnn|snn]
            %
            % Output:
            %   params: optimized values from range of parameters
            
            switch mth
                case 'znn'
                    flt    = obj.FilterRange;
                    nflt   = obj.NumFilterRange;
                    nlay   = obj.FilterLayers;
                    mbsize = obj.MiniBatchSize;
                    drp    = obj.DropoutLayer;
                    ilrate = obj.InitialLearningRate;
                    maxeps = obj.MaxEpochs;
                    
                    %
                    params = [
                        optimizableVariable('FilterSize'     , flt, 'Type', 'integer')
                        optimizableVariable('SectionDepth'    , nflt, 'Type', 'integer')
                        optimizableVariable('FilterLayers'    , nlay, 'Type', 'integer')
                        optimizableVariable('MiniBatchSize'   , mbsize, 'Type', 'integer')
                        optimizableVariable('DropoutLayer'    , drp)
                        optimizableVariable('InitialLearnRate', ilrate, 'Transform', 'log')
                        optimizableVariable('MaxEpochs'       , maxeps, 'Type', 'integer')];
                    
                    %
                    Timgs = obj.getZVector.IN.training.IMGS;
                    Tscrs = obj.getZVector.IN.training.ZSCRS;
                    Vimgs = obj.getZVector.IN.validation.IMGS;
                    Vscrs = obj.getZVector.IN.validation.ZSCRS;
                    
                    % Run Bayes Optimization on all Z-Vector PCs
                    [objfn , bay] = deal(cell(size(Tscrs,2), 1));
                    for pc = 1 : size(Tscrs, 2)
                        objfn{pc} = obj.makeObjFn( ...
                            Timgs, Tscrs(:,pc), Vimgs, Vscrs(:,pc), pc);
                        
                        % Bayes optimization
                        bay{pc} = bayesopt(objfn{pc}, params, ...
                            'MaxTime', 14*60*60, 'IsObjectiveDeterministic', 0, ...
                            'UseParallel', 0);
                    end
                    
                    obj.ObjFn  = objfn;
                    obj.ObjBay = bay;
                    
                case 'dnn'
                    fprintf('Optimizing %s doesn''t work yet!\n', mth);
                    params = [];
                    return;
                    
                case 'snn'
                    fprintf('Optimizing %s doesn''t work yet!\n', mth);
                    params = [];
                    return;
                    
                otherwise
                    fprintf(2, 'Incorrect method %s [znn|dnn|snn]\n', mth);
                    params = [];
                    return;
            end
            
        end
    end
    
    %% -------------------------- Helper Methods ---------------------------- %%
    methods (Access = public)
        %% Various helper methods
        function splts = getSplits(obj)
            %% Return dataset splits
            splts = obj.Splits;
        end
        
        function crvs = getSplitCurves(obj, typ)
            %% Return Curves from split datasets
            if nargin < 2
                % Return full structure
                crvs = obj.SplitCurves;
            else
                % Return specific set of Curves
                crvs = obj.SplitCurves.(typ);
            end
            
        end
        
        function pca = getPCA(obj)
            %% Return PCA results
            pca = obj.PCA;
        end
        
        function z = getZVector(obj)
            %% Return Z-Vector training results
            z = obj.ZVectors;
        end
        
        function d = getDVector(obj)
            %% Return D-Vector training results
            d = obj.DVectors;
        end
        
        function s = getSVector(obj)
            %% Return S-Vector training results
            s = obj.SVectors;
        end
        
        function fnms = getFigNames(obj)
            %% Return figure names
            fnms = obj.FigNames;
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
                    fprintf(2, 'Type (%s) not yet implemented [training|validation]\n', typ);
                    [din , dout] = deal([]);
                    return;
                otherwise
                    fprintf(2, 'Type (%s) should be [training|validation|testing]\n', typ);
                    [din , dout] = deal([]);
                    return;
            end
            
            if nargin <= 2
                % Cell arrays not inputted, so extract them from dataset
                rin  = arrayfun(@(c) c.getImage, ...
                    obj.getSplitCurves(typ), 'UniformOutput', 0);
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
    end
    
    %% ------------------------- Private Methods --------------------------- %%
    methods (Access = private)
        %% Private helper methods
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
        
        function ObjFn = makeObjFn(obj, Timgs, Tscrs, Vimgs, Vscrs, pc)
            %% Create objective function for optimization
            ObjFn = @valErrorFun;
            isz   = [size(Timgs,1) , size(Timgs,2) , 1];
            
            function [valErr , cons , fnm] = valErrorFun(params)
                %%
                nout = size(Tscrs,2);
                %                 nflt = round(16 / sqrt(params.SectionDepth));
                
                %% Misc properties
                % Determine parallelization
                switch obj.Parallel
                    case 0
                        % Run with basic for loop [slower]
                        exenv = 'cpu';
                    case 1
                        % Run with parallel processing [less stable]
                        exenv = 'parallel';
                    case 2
                        % Run with multiple GPU cores [only tested on Nathan's]
                        exenv = 'multi-gpu';
                    otherwise
                        fprintf(2, 'Incorrect Option %d [0|1|2]\n', par);
                        [valErr , cons , fnm] = deal([]);
                        return;
                end
                
                % Plot Type
                switch obj.Visualize
                    case 0
                        vis = 'none';
                    case 1
                        vis = 'none';
                    case 2
                        vis = 'training-progress';
                    otherwise
                        fprintf(2, 'Incorrect Option %d [0|1|2]\n', par);
                        [valErr , cons , fnm] = deal([]);
                        return;
                end
                
                %%
                flts    = params.FilterSize;
                nflts   = params.SectionDepth;
                fltlyrs = params.FilterLayers;
                LAYERS  = generateLayers(flts, nflts, fltlyrs);
                
                layers = [
                    imageInputLayer(isz, 'Name', 'imgin', ...
                    'Normalization', 'none');
                    
                    LAYERS ;
                    
                    dropoutLayer(params.DropoutLayer, 'Name', 'dropout');
                    fullyConnectedLayer(nout, 'Name', 'conn');
                    regressionLayer('Name', 'reg');
                    ];
                
                % Configure CNN options
                Vfreq   = floor(numel(Tscrs) / params.MiniBatchSize);
                options = trainingOptions( ...
                    'sgdm', ...
                    'MiniBatchSize',        params.MiniBatchSize, ...
                    'MaxEpochs',            params.MaxEpochs, ...
                    'InitialLearnRate',     params.InitialLearnRate, ...
                    'Shuffle',              'every-epoch', ...
                    'Plots',                vis, ...
                    'Verbose',              obj.Verbose, ...
                    'ExecutionEnvironment', exenv, ...
                    'ValidationData',       {Vimgs , Vscrs}, ...
                    'ValidationFrequency',  Vfreq ...
                    );
                
                %% Run training and get error from validation set
                net    = trainNetwork(Timgs, Tscrs, layers, options);
                ypre   = net.predict(Vimgs);
                %                 valErr     = meansqr(diag(pdist2(ypre, Vscrs)));
                valErr = meansqr(diag(pdist2(ypre, Vscrs)) ./ Vscrs);
                
                %%
                outdir = sprintf('optimization%spc%d', filesep, pc);
                fnm    = sprintf('%s%s%s_optimization_%0.02ferror.mat', ...
                    outdir, filesep, tdate, valErr);
                BAYES  = struct('Net', net, 'Error', valErr, ...
                    'Options', options);
                
                if ~isfolder(outdir)
                    mkdir(outdir);
                end
                
                save(fnm, '-v7.3', 'BAYES');
                cons = [];
                
            end
            
            
        end
    end
end

