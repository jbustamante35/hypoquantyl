%% pcaJB: my custom PCA class

classdef PcaJB < handle
% classdef PcaJB
    properties (Access = public)
        %% Main properties
        DataName
        InputData
        ZScoreNormalize
        NumberOfPCs        
        OptimalPCs
    end
    
    properties (Access = protected)
        %% Private properties
        ZScoreReshape % Dimensions to reshape data before Z-Score normalization
        ZScoreNorm    % Strucutre with values for Z-Score normalization
    end
    
    methods (Access = public)
        %% Constructor method
        function obj = PcaJB(varargin)
        %% Constructor for this object
        if ~isempty(varargin)
            % Parse inputs to set properties
            args = obj.parseConstructorInput(varargin);
            
            fn = fieldnames(args);
            for k = fn'
                obj.(cell2mat(k)) = args.(cell2mat(k));
            end
            
            % Process Name for savefile
            appendName   = sprintf('%s_pcaResults_%s_%dPCs', ...
                tdate, obj.DataName, obj.NumberOfPCs);
            obj.DataName = appendName;
        else
            % Set default properties for empty object
            obj.DataName = sprintf('%s_pcaResults', tdate);
        end
        end
        
    end
    
    methods (Access = public)
        %% Primary Methods to get data
        function X = getInput(obj, znorm, N)
        %% Get N-rows of the input
        switch nargin
            case 1
                znorm = obj.ZScoreNormalize;
                N     = ':';
            case 2
                N = ':';
        end
        
        % Use raw input or perform Z-Score normalization
        if znorm
            if isempty(obj.ZScoreNorm.Input)
                D = obj.ComputeZScoreNorm;
            else
                D = obj.ZScoreNorm.Input;
            end
        else
            D = obj.InputData;
        end
        
        X = D(N, :);
        
        end
        
        function [z , mu , sig , rshp] = getZScoreNorm(obj, req)
        %% Return properties from Z-Score normalization
        if isempty(obj.ZScoreNorm.Input)
            [z , mu , sig , obj] = obj.ComputeZScoreNorm;
        end
        
        switch nargin
            case 1
                z   = obj.ZScoreNorm.Input;
                mu  = obj.ZScoreNorm.Mu;
                sig = obj.ZScoreNorm.Sigma;                
            case 2
                z = obj.ZScoreNorm.(req);
        end
        
        rshp = obj.ZScoreReshape;
        
        end
        
        function M = MeanVals(obj, X, ndims)
        %% Means of the input data
        switch nargin
            case 1
                X     = obj.getInput;
                ndims = [];
            case 2
                ndims = [];
            case 3
        end
        
        % Dimensions of input to compute on
        if isempty(ndims)
            ndims = size(X, 2);
        end
        
        M = mean(X, 1);
        M = M(1 : ndims);
        end
        
        function C = CovVarMatrix(obj, X, M)
        %% Variance-Covariance matrix
        % The (subD' * subD) calculation takes a very long time for large
        % datasets (N > 10000). Consider using a faster function.
        switch  nargin
            case 1
                X = obj.getInput;
                M = obj.MeanVals(X);
            case 2
                M = obj.MeanVals(X);
            case 3
        end

        S = bsxfun(@minus, X, M);
        C = (S' * S) / size(S, 1);
        end
        
        function E = EigVecs(obj, neigs)
        %% Eigenvectors
        if nargin < 2 || neigs == 0
            neigs = obj.NumberOfPCs;
        end
        
        E = obj.getEigens('vec', neigs);
        E = E(:, 1 : neigs);
        end
        
        function V = EigVals(obj, neigs)
        %% Eigenvalues
        if nargin < 2 || neigs == 0
            neigs = obj.NumberOfPCs;
        end
        
        V = obj.getEigens('val', neigs);
        V = V(1 : neigs , 1 : neigs);
        end
        
        function [varX, pctN] = VarExplained(obj, pct, n)
        %% Variance explained
        % pct: cutoff percentage (default: 1.0)
        % n: number of dimensions to return (default: NumberOfPCs)
        switch nargin
            case 1
                pct = 0.999;
                n   = obj.NumberOfPCs;
            case 2
                n = obj.NumberOfPCs;
            case 3
        end
        
        V            = obj.EigVals(n);
        [varx, pctN] = variance_explained(V, pct);
        
        varX = varx(1 : n);
        
        obj.OptimalPCs = pctN;
        
        end
        
        function S = PCAScores(obj, N, neigs)
        %% Principal component scores
        switch nargin
            case 1
                N     = ':';
                neigs = obj.NumberOfPCs;
            case 2
                neigs = obj.NumberOfPCs;
            case 3
        end
        
        X = obj.getInput;
        M = obj.MeanVals(X);
        E = obj.EigVecs(neigs);
        S = pcaProject(X, E, M, 'sim2scr');        
        S = S(N, :);
        end
        
        function Y = SimData(obj, N, neigs)
        %% Simulated data after projecting data on eigenvectors
        switch nargin
            case 1
                N     = ':';
                neigs = obj.NumberOfPCs;
            case 2
                neigs = obj.NumberOfPCs;
            case 3
        end
        

        S = obj.PCAScores(N, neigs);
        E = obj.EigVecs(neigs);
        M = obj.MeanVals;
        Y = pcaProject(S, E, M, 'scr2sim');
        end
        
        function [z , mu , sig] = ComputeZScoreNorm(obj, ndim, rshp)
        %% Perform Z-Score normalization
        % To convert normalized dataset 'z' back to the original, multiply
        % by sigma 'sig' and add back the mean 'mu.'
        %   x = (y * sig) + mu
        %
        % To convert the input dataset to another shape, signify the
        % dimensions to reshape into using the 'rshp' parameter. This is
        % specifically meant to reshape Z-Vectors from slices to vectors.
        % Use 0 to skip reshaping and use original shape.
        %
        % Input:
        %   obj: this PCA object
        %   ndim: dimension to compute on (default 1 [columns])
        %   rshp: reshape InputData before normalization (default 0)
        %
        % Output:
        %   z: Z-Score normalized data
        %   mu: mean of dataset
        %   sig: standard deviation of dataset
        %
        
        %%
        switch nargin
            case 1
                ndim = 1;
                rshp = obj.ZScoreReshape;
            case 2
                rshp = obj.ZScoreReshape;
        end
        
        % Reshape data
        if rshp
            shp = size(obj.InputData);
            X   = reshape(obj.InputData, rshp);
        else
            X = obj.InputData;
        end
        
        % Z-Score normalize
        [z , mu , sig] = zscore(X, ndim);
        
        % Convert back to original shape
        if rshp
            z = reshape(z, shp);
        end
        
        obj.ZScoreNorm = struct('Input', z, 'Mu', mu, 'Sigma', sig);
        
        end
        
    end
    
    methods (Access = private)
        %% Private helper methods
        function args = parseConstructorInput(varargin)
        %% Parse input parameters for Constructor method
        p = inputParser;
        p.addRequired('InputData');
        p.addRequired('NumberOfPCs');
        p.addOptional('DataName', '');
        p.addOptional('OptimalPCs', []);
        p.addOptional('ZScoreNormalize', 0);
        p.addOptional('ZScoreReshape', 0);
        p.addOptional('ZScoreNorm', ...
            struct('Input', [], 'Mu', [], 'Sigma', []));
        
        % Parse arguments into structure
        p.parse(varargin{2}{:});
        args = p.Results;
        end
        
        function X = getEigens(obj, req, npcs)
        %% Get Eigenvectors or Eigenvalues
        switch nargin
            case 1
                req   = 'vec';
                npcs  = obj.NumberOfPCs;
            case 2
                npcs  = obj.NumberOfPCs;
        end
        
        C      = obj.CovVarMatrix;
        [E, V] = eigs(C, npcs);
        
        switch req
            case 'vec'
                X = E;
            case 'val'
                X = V;
            otherwise
                fprintf(2, 'Error getting eigen%s\n', req);
                X = [];
        end
        
        end
        
    end
    
end

