classdef hasAframe < handle
    %%
    properties
        %%
        expressFrame;
    end
    
    methods
        %%
        function this = hasAframe(varargin)
            %% hasAframe
            expressFrame = [];
        end
        
        function attachProjector(this, projector, source, target)
            %% attachProjector
            switch source
                case 'outof'
                    switch target
                        case 'outof'
                        case 'into'
                            this.expressFrame = projector;
                    end
                case 'into'
                    switch target
                        case 'outof'
                        case 'into'
                    end
            end
        end
    end
end