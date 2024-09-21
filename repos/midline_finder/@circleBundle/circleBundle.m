classdef circleBundle < fiberBundle1d
    %%
    methods
        function this = circleBundle(domainLimits, rho)
            %% circleBundle
            if nargin < 2; rho = 1; end
            f  = ...
                @(x) rho * [cos(x + domainLimits(1)) , sin(x + domainLimits(1))];
            
            df = @(x) rho * [ ...
                -sin(x + domainLimits(1)) , cos(x + domainLimits(1)) , zeros(size(x)) , ...
                -cos(x+domainLimits(1))   , -sin(x+domainLimits(1))  , zeros(size(x)) , ...
                cos(x+domainLimits(1))    , sin(x+domainLimits(1))   , ones(size(x)) / rho ...
                ];
            
            this@fiberBundle1d(f, [domainLimits , rho], df);
        end
    end
end