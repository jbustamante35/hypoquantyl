%% Experiment: class containing multiple image stacks stored as separate Genotype objects
% Class description

classdef Experiment < handle
    properties (Access = public)
    % Experiment properties
        ExperimentName
        ExperimentDate
        Genotypes
    end
    
    properties (Access = private)
    % Private data properties
    
    end
    
    methods (Access = public)
    % Constructor and main methods
        function obj = Experiment(exptName)
        %% Constructor to instance Experiment with Name and Date
            obj.ExperimentName = getDirName(exptName);
            obj.ExperimentDate = getDateString(obj, 'long');
        end
        
        function obj = FindGenotypes(obj, num)
        %% Load image stacks and store as Genotype objects
            obj.Genotypes{num} = Genotype(obj.ExperimentName);
            obj.Genotypes{num}.StackLoader;
        
        end
        
    end
    
    methods (Access = public)
    % Various helper methods for other classes to use
    
    end
    
    methods (Access = private)
    % Private helper methods for this class
    
    % Set up date string for filename of results 
        function dout = getDateString(obj, datetype) %#ok<INUSL>
            switch datetype
                case 'short'
                    df = 'yymmdd';
                    dout = datestr(now, df);
                case 'long'
                    dout = datestr(now, 'dd-mmm-yyyy');
                otherwise 
                    dout = datestr(now, 'dd-mmm-yyyy');
            end
        end
        
    end
end
