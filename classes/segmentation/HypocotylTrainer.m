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
        NPX
        NPY
        NPZ
        NZP
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
        NPF
        NPD
        DLayers
        DTrainFnc
        
        % S-Vector NN
        SLayers
        STrainFnc
        
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
        ZFnc
        ZBay
        ZParams
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
                
                % PCA Parametersrunning
                'NPX'                 , 6 ; ...
                'NPY'                 , 6 ; ...
                'NPZ'                 , 20 ; ...
                'NZP'                 , 20 ; ...
                'AddMid'              , 0 ; ...
                
                % Z-Vector CNN
                'FilterRange'         , 7 ; ...
                'NumFilterRange'      , [10 , 5 , 3] ; ...
                'FilterLayers'        , 1 ; ...
                'DropoutLayer'        , 0.2 ; ...
                'MiniBatchSize'       , 128 ; ...
                'MaxEpochs'           , 300 ; ...
                'InitialLearningRate' , 1e-4 ; ...
                
                % D-Vector NN
                'Iterations'          , 20 ; ...
                'FoldPredictions'     , 1  ; ...
                'NPF'                 , 20 ; ...
                'NPD'                 , 20 ; ...
                'DLayers'             , 5  ; ...
                'DTrainFnc'           , 'trainlm' ; ...
                
                % S-Vector NN
                'SLayers'             , 5 ; ...
                'STrainFnc'           , 'trainlm' ; ...
                
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
                mth = 'withval';
            end
            
            switch mth
                case 'trn'
                    % Run with only training set
                    C = obj.getSplitCurves('training');

                case 'withval'
                    % Run with training and validation sets
                    % Order is training in front, validation in back
                    C = [obj.getSplitCurves('training') ; ...
                        obj.getSplitCurves('validation')];                                        
                    
                otherwise
                    fprintf(2, 'Method %d not implemented [trn|withval]\n', mth);
                    return;
            end
            
            [px, py, pz, pp] = hypoquantylPCA(C, obj.Save, ...
                obj.NPX, obj.NPY, obj.NPZ, obj.NZP, obj.AddMid);
            obj.PCA          = struct('px', px, 'py', py, 'pz', pz, 'pp', pp);
            
        end
        
        function obj = TrainZVectors(obj)
            %% Train Z-Vectors
            t = tic;
            n = fprintf('Preparing %d images and %d Z-Vectors PC scores', ...
                numel(obj.Curves(obj.Splits.trnIdx)), obj.NPZ);
                        
            IMGS  = arrayfun(@(c) c.getImage, ...
                obj.Curves(obj.Splits.trnIdx), 'UniformOutput', 0);
            IMGS  = cat(4, IMGS{:});
            ZSCRS = obj.PCA.pz.PCAScores(1 : size(IMGS,4));
            
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
                nfigs, obj.FoldPredictions, obj.NPF, obj.NPD, obj.DLayers, ...
                obj.DTrainFnc, obj.Save, obj.Visualize, obj.Parallel);
            
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
        
        function obj = OptimizeParameters(obj, mth, pc)
            %% Optimize parameters if given a range of values
            % Input:
            %   obj: this object
            %   mth: which learning method to train [znn|dnn|snn]
            %   pc: continue from most recent PC (0) or redo from 1st PC (1)
            %
            % Output:
            %   params: optimized values from range of parameters
            if nargin < 3
                pc = 0; % Default to picking up from last PC
            end
            
            switch mth
                case 'znn'
                    %% Run metaparameter optimization for Z-Vector CNN
                    flt    = obj.FilterRange;
                    nflt   = cellfun(@(x) num2str(x), obj.NumFilterRange, 'UniformOutput', 0);
                    nlay   = obj.FilterLayers;
                    mbsize = obj.MiniBatchSize;
                    drp    = obj.DropoutLayer;
                    ilrate = obj.InitialLearningRate;
                    maxeps = obj.MaxEpochs;
                    
                    % Define optimizable variables
                    params = [
                        optimizableVariable('FilterSize'      , flt, 'Type', 'integer')
                        optimizableVariable('NumFilters'      , nflt, 'Type', 'categorical')
                        optimizableVariable('FilterLayers'    , nlay, 'Type', 'integer')
                        optimizableVariable('MiniBatchSize'   , mbsize, 'Type', 'integer')
                        optimizableVariable('DropoutLayer'    , drp)
                        optimizableVariable('InitialLearnRate', ilrate, 'Transform', 'log')
                        optimizableVariable('MaxEpochs'       , maxeps, 'Type', 'integer')];
                    
                    % Get training and validation images and scores
                    Timgs = obj.getZVector.IN.training.IMGS;
                    Tscrs = obj.getZVector.IN.training.ZSCRS;
                    Vimgs = obj.getZVector.IN.validation.IMGS;
                    Vscrs = obj.getZVector.IN.validation.ZSCRS;
                    
                    % Determine which PC to start from
                    try
                        switch pc
                            case 0
                                % Start from last available PC
                                [bay , fnc] = obj.getOptimizer;
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
                    for pc = pcrng
                        fnc{pc} = obj.makeZFnc( ...
                            Timgs, Tscrs(:,pc), Vimgs, Vscrs(:,pc), pc);
                        
                        % Bayes optimization
                        bay{pc} = bayesopt(fnc{pc}, params, ...
                            'MaxTime', 1*60*60, 'IsObjectiveDeterministic', 0, ...
                            'UseParallel', 0, 'Verbose', obj.Verbose);
                        
                        % Store into this object for debugging
                        obj.ZFnc{pc}    = fnc{pc};
                        obj.ZBay{pc}    = bay{pc};
                        obj.ZParams{pc} = params;
                    end
                    
                case 'dnn'
                    fprintf('Optimizing %s doesn''t work yet!\n', mth);
                    return;
                    
                case 'snn'
                    fprintf('Optimizing %s doesn''t work yet!\n', mth);
                    return;
                    
                otherwise
                    fprintf(2, 'Incorrect method %s [znn|dnn|snn]\n', mth);
                    return;
            end
            
        end
        
        function P = SetOptimizedParameters(obj, mth, pc, mpath)
            %% Set parameters to best values after optimization
            %
            % Input:
            %   mth: algorithm to get parameters for [znn|dnn|snn]
            %   pc: principal component to set optimized parameters for
            %   mpath: path to directory of mat-files after optimization
            
            %% Parse inputs
            switch nargin
                case 1
                    mth   = 'znn';
                    pc    = 1;
                    mpath = sprintf('%s%soptimization%spc%02d', ...
                        pwd, filesep, filesep, pc);
                case 2
                    pc    = 1;
                    mpath = sprintf('%s%soptimization%spc%d', ...
                        pwd, filesep, filesep, pc);
                case 3
                    mpath = sprintf('%s%soptimization%spc%d', ...
                        pwd, filesep, filesep, pc);
                case 4
                otherwise
                    fprintf(2, 'Error with inputs [%d]\n', nargin);
                    return;
            end
            
            %% Set parameters
            switch mth
                case 'znn'
                    %% Set parameters for Z-Vector training
                    % Extract directory of datasets
                    exp = 'n_*.*e';
                    d   = dir2(mpath);
                    m   = arrayfun(@(x) x.name, d, 'UniformOutput', 0);
                    
                    [a , b] = cellfun(@(x) regexpi(x, exp), ...
                        m, 'UniformOutput', 0);
                    val     = cell2mat(cellfun(@(mm,aa,bb) str2double( ...
                        mm(aa+2:bb-1)), m, a, b, 'UniformOutput', 0));
                    
                    % Get data with minimum error
                    minVal = min(val(val > 0));
                    minIdx = find(val == minVal);
                    minFnm = sprintf('%s%s%s', ...
                        d(minIdx).folder , filesep , d(minIdx).name);
                    
                    % Load data and extract values
                    P       = load(minFnm);
                    P       = P.BAYES;
                    %                     net     = P.Net;
                    %                     layers  = P.Net.Layers;
                    %                     options = P.Options;
                    %                     params  = P.Params;
                    
                    
                case 'dnn'
                case 'snn'
                otherwise
                    fprintf(2, 'Method %s not recognized [znn|dnn|snn]\n', mth);
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
                try
                    crvs = obj.SplitCurves.(typ);
                catch
                    fprintf(2, ...
                        'Incorrect type %s [training|validation|testing]\n', typ);
                    crvs = [];
                end
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
        
        function [bay , objfn , params] = getOptimizer(obj)
            %% Return optimization components
            bay    = obj.ZBay;
            objfn  = obj.ZFnc;
            params = obj.ZParams;
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
        
        function ZFnc = makeZFnc(obj, Timgs, Tscrs, Vimgs, Vscrs, pc)
            %% Create objective function for optimization
            ZFnc = @valErrorFun;
            
            function [valErr , cons , fnm] = valErrorFun(params)
                %% Train network with parameters and evaluate validation error
                % Load parameters
                flt    = params.FilterSize;
                nflt   = str2num(char(params.NumFilters)); %#ok<ST2NM>
                nlay   = params.FilterLayers;
                mbsize = params.MiniBatchSize;
                drp    = params.DropoutLayer;
                ilrate = params.InitialLearnRate;
                maxeps = params.MaxEpochs;
                
                %% Misc properties
                sav = 0; % Don't save output
                par = obj.Parallel;
                vis = obj.Visualize;
                vrb = obj.Verbose;
                
                %%
                [~, ZOUT] = znnTrainer(Timgs, Tscrs, obj.Splits, ...
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
                %                 BAYES  = struct('Net', net, 'Error', valErr, ...
                %                     'Options', options, 'Params', table2struct(params));
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

