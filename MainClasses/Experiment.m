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
            obj.ExperimentDate      = getDateString(obj, 'long');
            
        end
        
        function obj = AddGenotypes(varargin)
            %% Load image stacks and store as Genotype objects
            % Add Genotype to this Experiment. Input is flexible to either
            % automatically add genotypes from current directory, or manually select
            % the folder containing desired image stacks.
            %
            % Input:
            %   fProps: directory and file properties for creating Genotype
            %   imgExt: extension of image files
            %   srtBy: table property to sort images by
            %   vis: visualize images loaded in Genotype
            %   num: current Genotype to create
            %
            % Output: n/a
            %   If Genotype was sucessfully created, NumberOfGenotypes is incremented by 1
            
            % So far, only 3 methods for creating new Genotype 
            narginchk(1, 5);
            switch nargin
                case 1
                    % Manually select Genotype directory and file extension,
                    % Automatically appends images to next available Genotype
                    obj                = varargin{1};
                    num                = obj.NumberOfGenotypes + 1;
                    obj.Genotypes(num) = Genotype('', 'ExperimentName', obj.ExperimentName, ...
                        'ExperimentPath', obj.ExperimentPath);
                    
                case 2
                    % Manually select Genotype directory and file extension, but
                    % Manually add Genotype to desired index.
                    obj = varargin{1};
                    num = varargin{2};
                    
                    if num <= obj.NumberOfGenotypes + 1
                        obj.Genotypes(num) = Genotype('', 'ExperimentName', obj.ExperimentName, ...
                            'ExperimentPath', obj.ExperimentPath);
                    else
                        fprintf(2, 'No Genotype at index %d \n', num);
                        return;
                    end
                    
                case 5
                    % Automatically select Genotype directory from current directory,
                    % Automatically append images to next available Genotype.
                    
                    % Set parameters for creating Genotype
                    obj    = varargin{1};
                    fProps = varargin{2};
                    imgExt = varargin{3};
                    srtBy  = varargin{4};
                    vis    = varargin{5};
                    num    = obj.NumberOfGenotypes + 1;
                    
                    % Create new Genotype and directly load images in that directory
                    obj.Genotypes(num) = Genotype(fProps.name, ...
                        'ExperimentName', obj.ExperimentName, ...
                        'ExperimentPath', obj.ExperimentPath);
                    
                    obj.getGenotype(num).StackLoader(fProps, imgExt, srtBy, vis);
                    
                otherwise
                    fprintf(2, 'Input error for adding genotypes\n');
                    return;
            end
            
            obj.NumberOfGenotypes = obj.NumberOfGenotypes + 1;
            
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
        
        function S = combineSeedlings(obj)
            %% Combine all Seedlings from all Genotypes into single object array
            n = sum(cat(1, obj.getGenotype(':').NumberOfSeedlings));
            S = repmat(Seedling(''), [1 n]);
            j = 1;
            for i = 1 : obj.NumberOfGenotypes
                g = obj.getGenotype(i);
                for ii = 1 : g.NumberOfSeedlings
                    S(j) = g.getSeedling(ii);
                    j = j + 1;
                end
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
        function args = parseConstructorInput(varargin)
            %% Parse input parameters for Constructor method
            p = inputParser;
            p.addRequired('ExperimentPath');
            p.addOptional('ExperimentDate', '');
            p.addOptional('ExperimentName', '');
            p.addOptional('NumberOfGenotypes', 0);
            p.addOptional('Genotypes', Genotype);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
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
