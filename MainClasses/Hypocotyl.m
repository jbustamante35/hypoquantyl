%% Hypocotyl: class for individual hypocotyls identified from parent Seedling 
% Class description

classdef Hypocotyl < handle
    properties (Access = public)
    %% Hypocotyl properties
        ExperimentName
        GenotypeName
        SeedlingName
        HypocotylName
        Frame = zeros(1, 2);
        Lifetime
        Data
    end
    
    properties (Access = private)
    %% Private data stored here
        Midline
    end
    
    methods (Access = public)
    %% Constructor and main methods

        function obj = Hypocotyl(exp, geno, sdl, typ, im, frm)
        %% Constructor method for Hypocotyl
            obj.ExperimentName = exp;
            obj.GenotypeName   = geno; 
            obj.SeedlingName   = sdl;            
            
            switch typ
                case 'raw'
                % Set PreHypocotyl at frame
                    n = 'PreHypocotyl';

                case 'new'
                % Set Processed Hypocotyl 
                    n = 'Hypocotyl';
                    
                otherwise
                % Just default to new Hypocotyl at frame 
                    n = 'Hypocotyl';

            end
            
            h = sprintf('%s_%s_{%d}', n, obj.SeedlingName(end), frm);
            setHypocotylName(obj, h);
            obj.Data = struct('Image_gray', im,       ...
                              'Image_BW',   zeros(0), ...
                              'Skeleton',   zeros(0));
            
        end
        
        
    end
    
    methods (Access = public)
    % Various helper methods
    
        function obj = setHypocotylName(obj, n)
        %% Set name of Hypocotyl           
            obj.HypocotylName = n;
        end

        function n = getHypocotylName(obj)
        %% Return name of Hypocotyl
            n = obj.HypocotylName;
        end

        function dt_out = getImageData(varargin)
        %% Return data for Hypocotyl
        % User can specify which image from structure with 3rd parameter    
            obj = varargin{1};
            switch nargin
                   
                case 1                    
                    dt_out = obj.Data;
                    
                case 2
                    dat = obj.Data;
                    req = varargin{2};
                    
                    try
                        switch req
                            case 'gray'
                                dt_out = dat.Image_gray;

                            case 'bw'
                                dt_out = dat.Image_BW;

                            case 'skel'
                                dt_out = dat.Skeleton;                           
                        end
                        
                    catch e
                        fprintf(2, 'Error requesting field, %d', e.Message);
                        dt_out = {};
                        return;
                    end
                    
                otherwise
                    fprintf(2, 'Error requesting data.');
                    dt_out = {};
                    return;
            end
                    
        end

    end
    
    methods (Access = private)
    % Private helper methods
    
    end
    
end
