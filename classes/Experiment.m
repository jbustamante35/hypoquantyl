%% Experiment: class containing multiple image stacks stored as separate Genotype objects
% Class description

classdef Experiment < handle
    properties (Access = public)
        %% Experiment properties
        ExperimentName
        ExperimentDate
        ExperimentPath
        NumberOfGenotypes
    end
    
    properties (Access = private)
        %% Private data properties
        Genotypes
    end
    
    methods (Access = public)
        %% Constructor and main methods
        function obj = Experiment(varargin)
            %% Constructor method for Genotype
            if ~isempty(varargin)
                % Parse inputs to set properties
                args = obj.parseConstructorInput(varargin);
                
                fn = fieldnames(args);
                for k = fn'
                    obj.(cell2mat(k)) = args.(cell2mat(k));
                end
                
            else
                % Set default properties for empty object
                obj.ExperimentPath = pwd;
            end
            
            [obj.ExperimentName, ~] = getDirName(obj.ExperimentPath);
            
        end
        
        function obj = AddGenotypes(obj)
            %% Get all directories (exclude . and ..)
            fld   = dir(obj.ExperimentPath);
            fld   = fld(3:end);
            fldrs = fld(cat(1, fld.isdir));
            
            for f = fldrs'
                try
                    obj.Genotypes(obj.NumberOfGenotypes + 1) = ...
                        initializeGenotype(f.name, 'Parent', obj);
                    obj.NumberOfGenotypes = obj.NumberOfGenotypes + 1;
                catch e
                    fprintf(2, e.getReport);
                    fprintf(2, '\nError adding Genotype %d\n', obj.NumberOfGenotypes);
                end
            end
            
        end        
        
    end
    
    methods (Access = public)
        %% Various helper methods for other classes to use
        
        function g = getGenotype(obj, idx)
            %% Returns genotype at desired index
            try
                g = obj.Genotypes(idx);
            catch e
                fprintf(2, 'No Genotype at index %d\n', idx);
                fprintf(2, '%s \n', e.message);
            end
        end
        
        function G = combineGenotypes(obj)
            %% Combine all Genotypes into single object array
            G = obj.getGenotype(':');
        end
        
        function g = search4Genotype(obj, nm)
            %% Return specific Genotype by GenotypeName
            gts = obj.getGenotype(':')';
            
            for gt = gts
                mtc = gt.GenotypeName;
                if isequal(nm, mtc)
                    g = gt;
                    return;
                end
            end
        end
        
        function S = combineSeedlings(obj)
            %% Combine all Seedlings into single object array
            G = obj.combineGenotypes;
            S = arrayfun(@(x) x.getSeedling(':'), G, 'UniformOutput', 0);
            S = cat(1, S{:});
        end
        
        %         function s = search4Seedling(obj, nm)
        %             %% Return specific Genotype by GenotypeName
        %             sds = obj.combineSeedlings;
        %
        %             for sd = sds
        %                 mtc = sd.SeedlingName;
        %                 if isequal(nm, mtc)
        %                     s = sd;
        %                     return;
        %                 end
        %             end
        %         end
        
        function H = combineHypocotyls(obj)
            %% Combine all Hypocotyls into single object array
            % BE SURE TO CHANGE THIS WHEN I FIX HOW HYPOCOTYL IS STORED IN SEEDLING
            % Each Seedling will have single Hypocotyl, derived from data from the combination of
            % good frames of each PreHypocotyl
            S = obj.combineSeedlings;
            H = arrayfun(@(x) x.getAllPreHypocotyls, S, 'UniformOutput', 0);
            H = cat(2, H{:});
        end
        
        function C = combineContours(obj)
            %% Return all Hypocotyls with manually-drawn CircuitJB objects
            H = obj.combineHypocotyls;
            org = arrayfun(@(x) x.getContour('org'), H, 'UniformOutput', 0);
            org = cat(1, org{:});
            flp = arrayfun(@(x) x.getContour('flp'), H, 'UniformOutput', 0);
            flp = cat(1, flp{:});
            C   = [org ; flp];
        end
        
        function P = combineParameters(obj)
            %% Return all Ppar (theta, dX, dY) from all Routes from CircuitJB objects
            C = obj.combineContours;
            P = arrayfun(@(x) x.ParameterRoutes, C, 'UniformOutput', 0);
            P = cat(3, P{:});
            P = permute(P, [3 2 1]);
        end
        
        function check_outOfFrame(obj, frm, s)
            %% Check if Seedling grows out of frame
            %
            % obj: this Experiment
            % frm: frame of time-lapse
            % s  : Seedling to check
            
        end
        
    end
    
    methods (Access = private)
        %% Private helper methods for this class
        function args = parseConstructorInput(varargin)
            %% Parse input parameters for Constructor method
            p = inputParser;
            p.addRequired('ExperimentPath');
            p.addOptional('ExperimentDate', tdate('l'));
            p.addOptional('ExperimentName', '');
            p.addOptional('NumberOfGenotypes', 0);
            p.addOptional('Genotypes', Genotype);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
        
    end
end
