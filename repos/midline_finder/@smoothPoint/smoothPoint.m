classdef smoothPoint < handle & matlab.mixin.Heterogeneous

    properties
    
        location;
    
    end
    
    methods
        
        function [this] = smoothPoint(x)
            this.location = x(2:(end-1),end);
        end
        
    end

end