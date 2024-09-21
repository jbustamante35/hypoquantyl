classdef hasAnamedDomains < handle
    %%
    properties
        %% named domain
        domains
    end
    
    methods
        %%
        function this = hasAnamedDomains(this)
            %%
            this.domains = ...
                containers.Map('KeyType', 'char', 'ValueType', 'any');
        end
        
        function labelDomain(this, domainRange, name)
            %% labelDomain
            this.domains(name) = domainRange;
        end
        
        function [endPoints_i , endPoints_p] = getDomainEndPoints(this, domainName)
            %% getDomainEndPoints
            endPoints_i = this.domains(domainName);
            endPoints_p = this.eval(endPoints_i, 'normalized');
        end
    end
end