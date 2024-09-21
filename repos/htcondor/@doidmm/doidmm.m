classdef doidmm < oidmm
    properties
        genDate;
    end
    
    methods
        function [obj] = doidmm(varargin)
            %{
            obj = obj@oidmm(varargin{:});
            if nargin < 3
                dt = datestr(now,'SSMMHHddmmYYYY');
            else
                dt = varargin{3};
            end
            %}
            dt = datestr(now,'SSMMHHddmmYYYY');
            obj.genDate = dt;
        end
        
        function [cthis] = cupy(this)
            cthis = cupy@oidmm(this);
            cthis.genDate = datestr(now,'SSMMHHddmmYYYY');
        end
    end
    
    methods(Access = protected)
        function [cthis] = copyElement(this,isUnique)
            if nargin == 1;isUnique=false;end
            cthis = copyElement@oidmm(this);
            if isUnique
                cthis.genDate = datestr(now,'SSMMHHddmmYYYY');
            end
        end
    end
end