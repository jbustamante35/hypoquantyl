classdef fiberBundle0d < fiberBundle & smoothPoint & handle & hasAframe
    
    
    methods
        
        function [this] = fiberBundle0d(frameData)
                %{
                % make the first dim?
                if ndims(frameData) == 2
                    frameData = shiftdim(frameData,-1);
                end
                %}
                
                x = frameData(1:(end-1),end);
                
                this = this@smoothPoint(x);
                %this = this@hasAframe();
                
                this = this@fiberBundle(0,(size(frameData,2)-1),(size(frameData,2))*ones(1,2));
               

                if isa(frameData,'sym')
                    this.bundleCore('default') = [];
                else
                    this.bundleCore('default') = @(x)frameData;
                end
        end
        
        function [y] = eval(this,x,type)
            if nargin < 2;x = 0;end
            if nargin < 3;type = 'default';end
            if size(x,1) > size(x,2);x = x';end
            
            
            y = eval@fiberBundle(this,x,type);
            y = squeeze(y);
            
        end
        
        function [] = plot(this)
            cl = 'k.';
            curveData = squeeze(this.eval(0));
            T = squeeze(curveData(1:2,1));
            N = squeeze(curveData(1:2,2));
            P = curveData(1:2,3);
            plot(P(1),P(2),cl);
            hold on
            myquiver(P(1),P(2),T(1),T(2),10,'b');
            myquiver(P(1),P(2),-T(1),-T(2),10,'c');
            myquiver(P(1),P(2),N(1),N(2),10,'g');
        end
        
        function [invB] = inv(this)
            invB = fiberBundle0d(inv(this.eval(0)));
            this.bundleCore = invB.bundleCore;
            this.sectionCore = invB.sectionCore;
            if ~isempty(this.expressFrame)
                this.expressFrame.inv();
            end
        end
    end
    
end