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

        function obj = Hypocotyl(s)
        %% Constructor method for Hypocotyl
            obj.ExperimentName = s.ExperimentName;
            obj.GenotypeName   = s.GenotypeName; 
            obj.SeedlingName   = char(s.getSeedlingName);
            obj.HypocotylName  = sprintf('Hypocotyl_%d', str2double(obj.SeedlingName(end)));            
            obj.Data = struct('Image_gray', zeros(0), ...
                              'Image_BW',   zeros(0), ...
                              'Skeleton',   zeros(0));
        end
        
%         function obj = Hypocotyl(hypName, im, bw, sk)
%         %% Constructor method
%             if nargin == 0
%                 disp('nothing entered');
%             else           
%                 obj.HypocotylName = string(['Hypocotyl_' hypName]);
%                 obj.Image_gray    = im;
%                 obj.Image_BW      = bw;
%                 obj.Skeleton      = sk;
%             end
% 
%         end
        
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

        

    end
    
    methods (Access = private)
    % Private helper methods
    
    end
    
end
