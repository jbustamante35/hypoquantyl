%% pcaJB: my custom PCA class

% classdef PcaJB < handle
classdef PcaJB 
    properties (Access = public)
        %% Main properties
        DataName
        InputData
        NumberOfPCs
    end
    
    properties (Access = protected)
        %% Private properties 
        % Not sure what I'd put here yet
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
        function inpD = getInput(obj, ndims)
            %% Get specific rows of the input
            if nargin < 2
                ndims = ':';
            end
            
            inpD = obj.InputData(ndims, :);
        end
        
        function avgD = MeanVals(obj)
            %% Means of the input data
            avgD = mean(obj.InputData, 1);
        end
        
        function covD = CovVarMatrix(obj)
            %% Variance-Covariance matrix
            rawD = obj.InputData;
            avgD = obj.MeanVals;
            subD = bsxfun(@minus, rawD, avgD);
            covD = (subD' * subD) / size(subD, 1);
        end
        
        function vecs = EigVecs(obj, neigs)
            %% Eigenvectors
            if nargin < 2 || neigs == 0
                neigs = obj.NumberOfPCs;
            end
            
            vecs = obj.getEigens('vec', neigs);
            vecs = vecs(:, 1 : neigs);
        end
        
        function vals = EigVals(obj, neigs)
            %% Eigenvalues
            if nargin < 2
                neigs = obj.NumberOfPCs;
            end
            
            vals = obj.getEigens('val', neigs);
            vals = vals(1:neigs, 1:neigs);
        end
        
        function [varX, pctN] = VarExplained(obj, pct, neigs)
            %% Variance explained
            if nargin < 2
                pct   = 1;
                neigs = obj.NumberOfPCs;
            elseif nargin < 3
                neigs = obj.NumberOfPCs;
            end
            
            eigX         = obj.EigVals(neigs);
            [varX, pctN] = variance_explained(eigX, pct);
        end
        
        function pcaS = PCAScores(obj, ndims, neigs)
            %% Principal component scores
            if nargin < 2
                ndims = ':';
                neigs = obj.NumberOfPCs;
            elseif nargin < 3
                neigs = obj.NumberOfPCs;
            end
            
            rawD = obj.InputData;
            avgD = obj.MeanVals;
            eigV = obj.EigVecs(neigs);
            pcaS = pcaProject(rawD, eigV, avgD, 'sim2scr');
            
            pcaS = pcaS(ndims, :);
        end
        
        function simD = SimData(obj, ndims, neigs)
            %% Simulated data after projecting data on eigenvectors
            if nargin < 2
                ndims = ':';
                neigs = obj.NumberOfPCs;
            elseif nargin < 3
                neigs = obj.NumberOfPCs;
            end
            
            pcaS = obj.PCAScores(ndims, neigs);
            eigV = obj.EigVecs(neigs);
            avgD = obj.MeanVals;
            simD = pcaProject(pcaS, eigV, avgD, 'scr2sim');
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
            
            % Parse arguments into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
        function eigX = getEigens(obj, req, npcs)
            %% Get Eigenvectors or Eigenvalues
            if nargin < 2
                req  = 'vec';
                npcs = obj.NumberOfPCs;
            end
            
            covD             = obj.CovVarMatrix;
            [eigVec, eigVal] = eigs(covD, npcs);
            
            switch req
                case 'vec'
                    eigX = eigVec;
                case 'val'
                    eigX = eigVal;
                otherwise
                    fprintf(2, 'Error getting eigen%s\n', req);
                    eigX = [];
            end
            
        end
        
    end
    
end

