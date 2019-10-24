%% pcaJB: my custom PCA class

classdef PcaJB < handle
    properties (Access = public)
        DataName
        InputData
        NumberOfPCs
    end
    
    properties (Access = protected)
    end
    
    methods (Access = public)
        %% Constructor method
        function obj = PcaJB(varargin)
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
        function avgD = MeanVals(obj)
            avgD = mean(obj.InputData, 1);
        end
        
        function covD = CovVarMatrix(obj)
            rawD = obj.InputData;
            avgD = obj.MeanVals;
            subD = bsxfun(@minus, rawD, avgD);
            covD = (subD' * subD) / size(subD, 1);
        end
        
        function vecs = EigVecs(obj)
            vecs = obj.getEigens;
        end
        
        function vals = EigVals(obj)
            vals = obj.getEigens('val');
        end
        
        function [varX, pctN] = VarExplained(obj, pct)
            if nargin < 2
                pct = 1;
            end
            
            eigX         = obj.EigVals;
            [varX, pctN] = variance_explained(eigX, pct);
        end
        
        function pcaS = PCAScores(obj, ndims)
            if nargin < 2
                ndims = ':';
            end
            
            rawD = obj.InputData;
            avgD = obj.MeanVals;
            eigV = obj.EigVecs;
            pcaS = pcaProject(rawD, eigV, avgD, 'sim2scr');
            
            pcaS = pcaS(ndims, :);
        end
        
        function simD = SimData(obj, ndims)
            if nargin < 2
                ndims = ':';
            end
            
            pcaS = obj.PCAScores(ndims);
            eigV = obj.EigVecs;
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
        
        function eigX = getEigens(obj, req)
            if nargin < 2
                req = 'vec';
            end
            
            covD             = obj.CovVarMatrix;
            [eigVec, eigVal] = eigs(covD, obj.NumberOfPCs);
            
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