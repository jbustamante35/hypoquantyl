classdef hasMidline < handle
    methods
        function [midline] = traceMidline(this, nextBundle, edgeSearchDomains, resolution, disp)
            if nargin < 3; edgeSearchDomains = 7;     end
            if nargin < 4; resolution        = 0.01;  end
            if nargin < 5; disp              = false; end
            
            %%
            lenMAX         = 250 * 5;
            edgeDomainSize = 0.1;
            options        = optimset('TolX',resolution,'TolFun',resolution);
            nRange         = 2;
            
            %%
            leftObjective    = @(x,y) this.nearestBasePoint(nextBundle.evalCurve(x, 'normalized')', 'leftSide',  y);
            rightObjective   = @(x,y) this.nearestBasePoint(nextBundle.evalCurve(x, 'normalized')', 'rightSide', y);
            
            leftPoint        = @(x,y) this.evalCurve(leftObjective(x,y), 'normalized');
            rightPoint       = @(x,y) this.evalCurve(rightObjective(x,y),'normalized');
            
            leftDelta        = @(x,y) leftPoint(x,y)  - nextBundle.evalCurve(x,'normalized');
            rightDelta       = @(x,y) rightPoint(x,y) - nextBundle.evalCurve(x,'normalized');
            
            patrialObjective = @(yLeft,yRight)@(x) norm(norm(leftDelta(x,yLeft)) - norm(rightDelta(x,yRight)));
            
            %%
            leftSideRange  = this.domains('leftSide');
            rightSideRange = this.domains('rightSide');
            leftBorder     = ...
                [leftSideRange(1) , edgeDomainSize , edgeSearchDomains + 1];
            rightBorder    = ...
                [rightSideRange(2) , edgeDomainSize , edgeSearchDomains + 1];
            
            leftSTOP  = leftSideRange(2);
            rightSTOP = rightSideRange(1);
            
            %             leftObjective = @(x)this.nearestBasePoint(nextBundle.evalCurve(x,'normalized')','leftSide');
            %             rightObjective = @(x)this.nearestBasePoint(nextBundle.evalCurve(x,'normalized')','rightSide');
            %
            %             leftPoint = @(x)this.evalCurve(leftObjective(x),'normalized');
            %             rightPoint = @(x)this.evalCurve(rightObjective(x),'normalized');
            %
            %             leftDelta = @(x)leftPoint(x) - nextBundle.evalCurve(x,'normalized');
            %             rightDelta = @(x)rightPoint(x) - nextBundle.evalCurve(x,'normalized');
            %
            %             totalObjective = @(x)norm(norm(leftDelta(x)) - ...
            %                 norm(rightDelta(x)));
            
            path = [];
            path = [0 , 0];
            D    = [];
            
            if disp
                this.plot;
                hold on;
                axis equal;
                nextBundle.plot;
            end
            
            stop                     = false;
            cycle                    = 1;
            rightBorderSolutionStore = [];
            leftBorderSolutionStore  = [];
            
            %%
            while ~stop
                %% Break down the search into segments on the base
                l     = linspace(0, 1, nRange);
                t_si  = [];
                t_dis = [];
                
                for s = 1 : (numel(l) - 1)
                    totalObjective = patrialObjective(leftBorder, rightBorder);
                    %options = optimset('Display','iter');
                    
                    [t_si(s) , t_dis(s) , ex , ou] = ...
                        fminbnd(totalObjective, l(s), l(s+1), options);
                    
                    %[t_si(s),t_dis(s)] = fminsearch(totalObjective,.5*(l(s)+l(s+1)));
                    %[t_si(s),t_dis(s)] = fmincon(totalObjective,.5*(l(s)+l(s+1)));
                    %[t_si(s),t_dis(s)] = patternsearch(totalObjective,.5*(l(s)+l(s+1)),[],[],[],[],0,1);
                end
                
                % select the min from the segmented search
                [dis,midx] = min(t_dis);
                si = t_si(midx);
                
                %                 currLeft_solution  = leftObjective(si);
                %                 currRight_solution = rightObjective(si);
                %                 lP                 = leftPoint(si);
                %                 rP                 = rightPoint(si);
                
                %
                currLeft_solution  = leftObjective(si, leftBorder);
                currRight_solution = rightObjective(si, rightBorder);
                
                %                 if norm(rightSTOP - currRight_solution) < .001
                %                     stop = true;
                %                 end
                %
                %                 if norm(leftSTOP - currLeft_solution) < .001
                %                     stop = true;
                %                 end
                
                %
                if cycle > lenMAX
                    stop = true;
                end
                
                %
                lP        = leftPoint(si, leftBorder);
                rP        = rightPoint(si, rightBorder);
                nextPoint = nextBundle.evalCurve(si, 'normalized');
                
                %%
                if ~this.inContour(nextPoint)
                    delta     = nextPoint - path(end,:);
                    delta     = delta / norm(delta);
                    alpha     = 0;
                    step      = 0.1;
                    nextPoint = path(end,:) + (alpha * delta);
                    
                    while this.inContour(nextPoint)
                        alpha = alpha + step;
                        nextPoint = path(end,:) + (alpha * delta);
                    end
                    stop = true;
                end
                
                %%
                leftBorder(1)            = currLeft_solution;
                rightBorder(1)           = currRight_solution;
                leftBorderSolutionStore  = ...
                    [leftBorderSolutionStore ; currLeft_solution];
                rightBorderSolutionStore = ...
                    [rightBorderSolutionStore ; currRight_solution];
                
                T = nextPoint - path(end,:);
                T = T / norm(T);
                T = [T , 0]';
                N = [T(2) ; -T(1) ; 0];
                P = [nextPoint , 1]';
                F = [N , T , P];
                F = fiberBundle0d(F);
                
                nextBundle.attachProjector(F,'outof','into');
                
                %%
                if disp
                    if cycle >= 30
                        here = 1 ;
                    end
                    
                    %
                    plot(lP(1), lP(2), 'bo');
                    plot(rP(1), rP(2), 'b.');
                    F.plot;
                    nextBundle.plot;
                    title(num2str(cycle));
                    drawnow;
                    
                    if cycle >= 30
                        here = 1 ;
                    end
                end
                
                %
                path  = [path ; nextPoint];
                D     = [D ; dis];
                cycle = cycle + 1;
            end
            
            %%
            midline = fiberBundle1d(path);
        end
    end
end