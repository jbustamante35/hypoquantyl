%% ContourJB: my customized class for generating contours of Seedlings
% Class description

classdef ContourJB < handle
    properties (Access = public)
        Bounds
        Dists
        Sums
        Interps
    end
    
    properties (Access = private)
        Gray
        BW
    end
    
    methods (Access = public)
        function obj = ContourJB(varargin)
        %% Constructor to initialize object
            if isempty(varargin)
                obj.Gray    = [];
                obj.BW      = [];
                obj.Bounds  = [];
                obj.Dists   = [];
                obj.Sums    = [];
                obj.Interps = [];
            else
                obj.Gray    = [];
                obj.BW      = [];
                obj.Bounds  = varargin{1};
                obj.Dists   = varargin{2};
                obj.Sums    = varargin{3};
                obj.Interps = varargin{4};
            end
        end
        
        function obj = setGrayImageAtFrame(obj, im, frm)
        %% Set grayscale image at given frame
            obj.Gray{frm} = im;        
        end
        
        function im = getGrayImageAtFrame(obj, frm)
        %% Return grayscale image at given frame
            im = obj.Gray{frm};
        end
        
        function obj = setBWImageAtFrame(obj, bw, frm)
        %% Set bw image at given frame
            obj.BW{frm} = bw;        
        end
        
        function bw = getBWImageAtFrame(obj, frm)
        %% Return grayscale image at given frame
            bw = obj.BW{frm};
        end
    end
end
