%% HypoQuantyl: main class for running program
% This class runs the main HypoQuantyl program blah blah blah

classdef HypoQuantyl < handle
    properties (Access = public)
    %% HypoQuantyl properties
        AnalysisName
        AnalysisDate
        Experiments
    
    end
    
    properties (Access = private)
    %% Private data for this class    
        NumExperiments
    end
    
    
    methods (Access = public)
    %% Constructor and Main methods
        function obj = HypoQuantyl(varargin)
        %% Constructor method for Main Program
            narginchk(1, 2);
            switch nargin
                case 1
                    obj.AnalysisName        = getDirName(pwd);
                    obj.AnalysisDate        = getDateString(obj, 'long');
                    obj.Experiments         = LoadExperiments(pwd);
                    
                case 2
                    disp(varargin{1});
                    disp(varargin{2});
                    
                otherwise
                    fprintf(2, 'Incorrect arguments');
                    return;
            end
        
        end    
       
    end
    
    methods (Access = public)
    %% Main helper methods
        function obj = LoadExperiments(obj, fin)
        %% Loads folders containing different experiment conditions
            if numel(obj.Experiments) == 0
                obj.Experiments    = dir('*');
                obj.NumExperiments = obj.NumExperiments + 1;
            else
                obj.Experiments(obj.NumExperiments) = dir('*');
            end

        end
    
    end
    
    
    methods (Access = private)
    %% Private helper methods
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