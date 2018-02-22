%% Experiment: class containing multiple image stacks stored as separate Genotype objects
% Class description

classdef Experiment < handle
    properties (Access = public)
    %% Experiment properties
        ExperimentName
        ExperimentDate
        NumberOfGenotypes
    end
    
    properties (Access = private)
    %% Private data properties
        Genotypes
        FullExperimentPath
    end
    
    methods (Access = public)
    %% Constructor and main methods
        function obj = Experiment(exptName)
        %% Constructor to instance Experiment with Name and Date
            [obj.ExperimentName, obj.FullExperimentPath] = getDirName(exptName);
            obj.ExperimentDate                           = getDateString(obj, 'long');
            obj.NumberOfGenotypes                        = 0;
        end
        
        function obj = AddGenotypes(varargin)
        %% Load image stacks and store as Genotype objects
        % Add Genotype to this Experiment. Input is flexible to either
        % automatically add genotypes from current directory, or manually select
        % the folder containing desired image stacks. 
        % 
        % Input:
        %   
        % 
        % Output:
        % 
        % 
        
            narginchk(1, 5);
            switch nargin
                case 1
                % Manually select Genotype directory and file extension, 
                % Automatically appends images to next available Genotype 
                    obj = varargin{1};
                    num = obj.NumberOfGenotypes + 1;
                    
                    if obj.NumberOfGenotypes == 0
                        obj.Genotypes      = Genotype(obj.ExperimentName);
                    else                        
                        obj.Genotypes(num) = Genotype(obj.ExperimentName);
                    end      

                case 2
                % Manually select Genotype directory and file extension, but
                % Manually add Genotype to desired index.
                    obj = varargin{1};
                    num = varargin{2};

                    if obj.NumberOfGenotypes == 0
                        obj.Genotypes      = Genotype(obj.ExperimentName);
                    else
                        obj.Genotypes(num) = Genotype(obj.ExperimentName);
                    end
                    
                case 5
                % Automatically select Genotype directory from current directory,
                % Automatically append images to next available Genotype 
                    obj    = varargin{1};
                    expPrp = varargin{2};
                    imgExt = varargin{3};
                    srtBy  = varargin{4};
                    vis    = varargin{5};
                    num    = obj.NumberOfGenotypes + 1;                    
                    
                    if obj.NumberOfGenotypes == 0
                        obj.Genotypes      = Genotype(obj.ExperimentName);
                    else
                        obj.Genotypes(num) = Genotype(obj.ExperimentName);
                    end                     
                    
                    obj.getGenotype(num).StackLoader(expPrp, imgExt, srtBy, vis);
                    
                otherwise
                    fprintf(2, 'Input error for adding genotypes\n');
            end
            
            obj.NumberOfGenotypes = obj.NumberOfGenotypes + 1;
            
        end
        
    end
    
    methods (Access = public)
    %% Various helper methods for other classes to use
    
        function g = getGenotype(obj, gIdx)
        %% Returns genotype at desired index
            try                 
                g = obj.Genotypes(gIdx);
            catch e
                fprintf(2, 'No Genotype at that index\n');
                fprintf(2, '%s \n', e.getReport);
            end
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
