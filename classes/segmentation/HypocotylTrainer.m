%% Cuve: class for sections of contours for a CircuitJB object
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
        ConvolutionLayers
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
        Splits
        PCA
        ZVectors
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
                'TestingPct'          , 0 ; ...
                
                % PCA Parameters
                'PCX'                 , 3 ; ...
                'PCY'                 , 3 ; ...
                'PCZ'                 , 20 ; ...
                'PCP'                 , 10 ; ...
                'AddMid'              , 0 ; ...
                
                % Z-Vector CNN
                'ConvolutionLayers'   , {[7 , 10] ; [7 , 5]} ; ...
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
                'Verbose'             , 1 ; ...
                'Figures'             , 1 : 4  ...
                };
            
            obj = classInputParser(obj, prps, deflts, vargs);
            
        end
        
        function obj = ProcessCurves(obj)
            %% Configure segment length and step size
            arrayfun(@(c) c.setProperty('SEGMENTSIZE', obj.SegmentSize), ...
                obj.Curves, 'UniformOutput', 0);
            arrayfun(@(c) c.setProperty('SEGMENTSTEPS', obj.SegmentSteps), ...
                obj.Curves, 'UniformOutput', 0);
            
        end
        
        function obj = SplitDataset(obj)
            %% Split Curves into training, validation, and testing sets
            % Validation and Testing sets shouldn't be seen by any training algorithms
            t = tic;
            n = fprintf('Splitting into training,validation,testing sets');
            
            numCrvs    = numel(obj.Curves);
            obj.Splits = splitDataset(1 : numCrvs, ...
                obj.TrainingPct, obj.ValidationPct, obj.TestingPct);
            
            jprintf(' ', toc(t), 1, 80 - n);
        end
        
        function obj = RunPCA(obj)
            %% Run PCA functions
            [px, py, pz, pp] = hypoquantylPCA(obj.Curves(obj.Splits.trnIdx), ...
                obj.Save, obj.PCX, obj.PCY, obj.PCZ, obj.PCP, obj.AddMid);
            
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
            
            [IN, OUT] = znnTrainer(IMGS, ZSCRS, ...
                obj.Splits, obj.Save, obj.Parallel, obj.Verbose);
            
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
    end
    
    %% -------------------------- Helper Methods ---------------------------- %%
    methods (Access = public)
        %% Various helper methods
        function splts = getSplits(obj)
            %% Return dataset splits
            splts = obj.Splits;
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
    end
end

