%% pcaJB: my custom PCA class

classdef PcaJB < handle
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

                % Set name for savefile
                obj.DataName = obj.setName(obj.DataName);
            else
                % Set default properties for empty object
                obj.DataName = obj.setName;
            end
        end
    end

    methods (Access = public)
        %% Primary Methods to get data
        function pnm = setName(obj, pstr, ovr)
            %% Set default name for this object
            if nargin < 2; pstr = ''; end
            if nargin < 3; ovr  = 0;  end

            pnm = sprintf('%s_pcaResults_%s_%dPCs', ...
                tdate, pstr, obj.NumberOfPCs);

            if ovr; obj.DataName = pnm; end
        end

        function X = getInput(obj, znorm, N)
            %% Get N-rows of the input
            if nargin < 2; znorm = obj.ZScoreNormalize; end
            if nargin < 3; N     = ':';                 end

            % Use raw input or perform Z-Score normalization
            if znorm
                if isempty(obj.ZScoreNorm.Input)
                    X = obj.ComputeZScoreNorm;
                else
                    X = obj.ZScoreNorm.Input;
                end
            else
                X = obj.InputData;
            end

            if ~strcmpi(N, ':'); X = X(N,:); end
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

        function [M , X] = MeanVals(obj, X, ndims)
            %% Means of the input data
            if nargin < 2; X     = obj.getInput; end
            if nargin < 3; ndims = [];           end

            % Dimensions of input to compute on
            if isempty(ndims); ndims = size(X, 2); end

            M = mean(X, 1);
            M = M(1 : ndims);
        end

        function [C , X , M] = CovVarMatrix(obj, X, M)
            %% Variance-Covariance matrix
            % The (subD' * subD) calculation takes a very long time for large
            % datasets (N > 10000). Consider using a faster function.
            if nargin < 2; X = obj.getInput; end
            if nargin < 3; M = obj.MeanVals; end

            S = bsxfun(@minus, X, M);
            C = cov(S);
        end

        function [E , C , X , M] = EigVecs(obj, neigs)
            %% Eigenvectors
            if nargin < 2 || neigs == 0; neigs = obj.NumberOfPCs; end

            [E , C , X , M] = obj.getEigens('vec', neigs);
            E               = E(:, 1 : neigs);
        end

        function [V , C , X , M] = EigVals(obj, neigs)
            %% Eigenvalues
            if nargin < 2 || neigs == 0; neigs = obj.NumberOfPCs; end

            [V , C , X , M] = obj.getEigens('val', neigs);
            V               = V(1 : neigs , 1 : neigs);
        end

        function [varX , pctN] = VarExplained(obj, pct, n)
            %% Variance explained
            % pct: cutoff percentage (default: 1.0)
            % n: number of dimensions to return (default: NumberOfPCs)
            if nargin < 2; pct = 0.999;           end
            if nargin < 3; n   = obj.NumberOfPCs; end

            V             = obj.EigVals(size(obj.InputData,2));
            [varx , pctN] = variance_explained(V, pct);

            varX = varx(1 : n);

            obj.OptimalPCs = pctN;
        end

        function [S , E , U] = PCAScores(obj, N, neigs)
            %% Principal component scores
            if nargin < 2; N     = ':';             end
            if nargin < 3; neigs = obj.NumberOfPCs; end

            X = obj.getInput;
            U = obj.MeanVals(X);
            E = obj.EigVecs(neigs);
            S = pcaProject(X, E, U, 'sim2scr');
            S = S(N,:);
        end

        function Y = SimData(obj, N, neigs)
            %% Simulated data after projecting data on eigenvectors
            if nargin < 2; N     = ':';             end
            if nargin < 3; neigs = obj.NumberOfPCs; end

            [S , E , M] = obj.PCAScores(N, neigs);
            Y           = pcaProject(S, E, M, 'scr2sim');
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
            if nargin < 2; ndim = 1;                 end
            if nargin < 3; rshp = obj.ZScoreReshape; end

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
            if rshp; z = reshape(z, shp); end

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

        function [E , C , X , M] = getEigens(obj, req, npcs)
            %% Get Eigenvectors or Eigenvalues
            if nargin < 2; req  = 'vec';           end
            if nargin < 3; npcs = obj.NumberOfPCs; end

            [M , X] = obj.MeanVals;
            C       = obj.CovVarMatrix(X, M);
%             [E , V] = eigs(C, npcs);
            [E , V] = eigs(C, size(C,1));

            switch req
                case 'vec'
                case 'val'
                    E = V;
                otherwise
                    fprintf(2, 'Error getting eigen%s\n', req);
                    E = [];
            end
        end
    end
end
