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
        HYPOCOTYLLENGTH = 250 % Distance to set cutoff for hypocotyl
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
                    fprintf(2, '\nError adding Genotype %d\n', ...
                    	obj.NumberOfGenotypes);
                end
            end
            
        end        
        
        function obj = FindHypocotylAllGenotypes(obj, v)
            %% Extract Hypocotyl from every frame of each Seedling from 
            % all Genotypes from this Experiment object
            try

            	if v
            	    fprintf('Extracting Hypocotyls from %s\n', ...
            	    	obj.ExperimentName);
            	    tic;
            	end
            
                gens  = obj.Genotypes;
                arrayfun(@(x) x.FindHypocotylAllSeedlings(v), ...
                	gens, 'UniformOutput', 0);

            	if v
            	    fprintf('[%.02f sec] Extracting Hypocotyls from %s\n', ...
            	    	toc, obj.ExperimentName);
            	end

            catch e
                fprintf(2, 'Error extracting Hypocotyls from %s\n%s', ...
                	obj.ExperimentName, e.getReport);

            	if v
            	    fprintf('[%.02f sec]\n', toc);
            	end
            end
        end

        function obj = FindSeedlingAllGenotypes(obj, v)
            %% Extract Seedling from every frame of each Genotype

            try 
                if v
                    fprintf('Extracting Seedlings from Experiment %s\n', ...
                    	obj.ExperimentName);
                end

                gens = obj.Genotypes;
                arrayfun(@(x) x.FindSeedlings(1:x.TotalImages, ...
                	obj.HYPOCOTYLLENGTH, v), gens, 'UniformOutput', 0);
                arrayfun(@(x) x.SortSeedlings, gens, 'UniformOutput', 0);

                if v
                    fprintf('[%.02f sec] Extracting Hypocotyls from %s\n', ...
                        toc, obj.ExperimentName);
                end

            catch e
                fprintf(2, 'Error extracting Seedlings from %s\n%s', ...
                	obj.ExperimentName, e.getReport);

            	if v
            	    fprintf('[%.02f sec]\n', toc);
            	end
            end

        end

      function obj = SaveExperiment(obj)
         %% Prune superfluous data, dereference parents, then save 
         % Remove RawSeedlings and PreHypocotyls
             g = obj.combineGenotypes;
             arrayfun(@(x) x.PruneSeedlings, g, 'UniformOutput', 0);

             s = obj.combineSeedlings;
             arrayfun(@(x) x.PruneHypocotyls, s, 'UniformOutput', 0);

         % Dereference parent objects
             h = obj.combineHypocotyls;

             X     = {g, s, h};
             deref = @(c) arrayfun(@(x) x.DerefParents, c, 'UniformOutput', 0);
             cellfun(@(x) deref(x), X, 'UniformOutput', 0);

         % Save full Experiment object

     end

     function obj = LoadExperiment(obj)
         %% Recursively set references back to Child objects
         g = obj.combineGenotypes;
         arrayfun(@(x) x.setParent(obj), g, 'UniformOutput', 0);

         s = obj.combineSeedlings;
         h = obj.combineHypocotyls;
         
         X = {g, s, h};
         ref = @(c) arrayfun(@(x) x.RefChild, c, 'UniformOutput', 0);
         cellfun(@(x) ref(x), X, 'UniformOutput', 0);
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
        
        function H = combineHypocotyls(obj)
            %% Combine all Hypocotyls into single object array
            % CHANGE THIS WHEN I FIX HOW HYPOCOTYLS ARE STORED IN SEEDLINGS
            % Each Seedling will have a single Hypocotyl, derived from data 
            % from the combination of good frames of each PreHypocotyl. 
            S = obj.combineSeedlings;
            H = arrayfun(@(x) x.getAllPreHypocotyls, S, 'UniformOutput', 0);
            H = cat(2, H{:});
        end
        
        function C = combineContours(obj)
            %% Return all Hypocotyls with manually-drawn CircuitJB objects
            H   = obj.combineHypocotyls;
            org = arrayfun(@(x) x.getContour('org'), H, 'UniformOutput', 0);
            org = cat(1, org{:});
            flp = arrayfun(@(x) x.getContour('flp'), H, 'UniformOutput', 0);
            flp = cat(1, flp{:});
            C   = [org ; flp];
        end
        
        function P = combineParameters(obj)
            %% Return all Ppar (theta, dX, dY) from CircuitJB Routes 
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
