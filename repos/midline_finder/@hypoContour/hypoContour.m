classdef hypoContour < fiberBundle1d
    %%
    properties
        %%
        domainNames = {'leftSide' , 'top', 'rightSide', 'bottom'};
        midlineBundle
    end
    
    methods
        %%
        function this = hypoContour(hypoC, anchors)
            %% hypoContour
            hypoC = arcLength(hypoC, 'arcLen');
            this@fiberBundle1d(hypoC);
            
            % anchors for the hypo find the base locations
            [new_baseI(1) , dist(1)] = this.nearestBasePoint(anchors(1,:)');
            [new_baseI(2) , dist(2)] = this.nearestBasePoint(anchors(2,:)');
            [new_baseI(3) , dist(3)] = this.nearestBasePoint(anchors(3,:)');
            [new_baseI(4) , dist(4)] = this.nearestBasePoint(anchors(4,:)');
            
            % order the domains
            for e = 2 : numel(new_baseI)
                while new_baseI(e) < new_baseI(e-1)
                    new_baseI(e) = new_baseI(e) + 1;
                end
            end
            
            new_baseI = [new_baseI , new_baseI(1) + 1];
            for e = 1:(numel(new_baseI)-1)
                domain = new_baseI(e : (e+1));
                this.labelDomain(domain, this.domainNames{e});
            end
        end
        
        function y = baseAnchor(this)
            %% baseAnchor
            bottomDomain = this.domains('bottom');
            
            l = linspace(bottomDomain(1), bottomDomain(2), 3);
            y = squeeze(this.eval(l(2), 'normalized'));
            y = inv(y);
            y = fiberBundle0d(y);
        end
        
        function plot(this, marker)
            %% plot
            CL = {'r' , 'b' , 'm' , 'c'};
            for e = 1:numel(this.domainNames)
                this.plotDomain(this.domainNames{e}, CL{e});
                hold on;
            end
            
            if ~isempty(this.midlineBundle)
                this.midlineBundle.plot('k');
            end
        end
        
        function curveData = pcaEval(this, ivec)
            %% pcaEval
            curveData = [];
            for e = 1 : numel(this.domainNames)
                ep = this.domains(this.domainNames{e});
                
                if ~(ivec(e) == 0)
                    l         = linspace(ep(1), ep(2), ivec(e));
                    y         = this.evalCurve(l, 'normalized');
                    curveData = [curveData ; y];
                end
            end
        end
        
        function bool = inHypo(this,p)
            %% inHypo
            if isempty(this.quickRef)
                this.quickRef = this.pcaEval([50 , 0 , 50 , 0]);
            end
            
            bool = inpolygon(p(1), p(2), ...
                this.quickRef(:,1), this.quickRef(:,2));
        end
        
        function midline = traceMidline(this, rho, edgeDomains, resolution, disp)
            %% traceMidline
            if nargin < 2; rho         = 2;    end
            if nargin < 3; edgeDomains = 7;    end
            if nargin < 4; resolution  = 0.01; end
            if nargin < 5; disp        = 0;    end
            
            a       = circleBundle([0 , pi], rho);
            midline = traceMidline@fiberBundle1d( ...
                this, a, edgeDomains, resolution, disp);
            
            this.midlineBundle = midline;
        end
        
        function angle = hookAngle(this, hookDefRange)
            %% hookAngle
            if nargin < 2
                hookDefRange = [0.5 , 1 , 0.05];
            end
            
            angle = this.midlineBundle.protractor( ...
                hookDefRange(1:2), hookDefRange(3), 'normalized');
        end
        
        function direction = direction(this)
            %% direction
            direction = 'right';
            angle     = this.midlineBundle.protractor( ...
                [0.5 , 1], 10, 'normalized');
            
            if angle > 0
                direction = 'left';
            end
        end
        
        function attachProjector(this, proj, source, target)
            %% attachProjector
            if ~isempty(this.midlineBundle)
                this.midlineBundle.attachProjector(proj, source, target);
            end
            
            attachProjector@fiberBundle1d(this, proj, source, target);
        end
        
        function [featureVector , angle , length , kurvature] = morphoMetricProfile(this, kn, hookDefRange)
            %% morphoMetricProfile
            if nargin < 2; kn           = [];               end
            if nargin < 3; hookDefRange = [0.5 , 1 , 0.05]; end
            
            %
            angle        = nan;
            length       = nan;
            kurvature    = nan;
            widthProfile = [];
            
            % get midline length
            if ~isempty(this.midlineBundle)
                angle     = this.hookAngle(hookDefRange);
                length    = this.midlineBundle.calculatelength;
                kurvature = this.midlineBundle.kurvature;
                if ~isempty(kn)
                    x         = linspace(0, 1, numel(kurvature));
                    xi        = linspace(0, 1, kn);
                    kurvature = interp1(x, kurvature, xi);
                end
            end
            
            featureVector = [length , angle , kurvature , widthProfile];
        end
        
        function wProfile = widthProfile(this)
            %% widthProfile
            mapType    = 'normalized';
            leftDomain = this.domains('leftSide');
            leftSource = linspace(leftDomain(1), leftDomain(2), 70);
            
            rightDomain = this.domains('rightSide');
            rightSource = linspace(rightDomain(1), rightDomain(2), 70);
            disp        = false;
            
            % best yet
            tangentThreshold = 3;
            metric           = @(v) ((abs(v(1)) < tangentThreshold) & ...
                (v(2) > 0)) * (1 * v(1)^2 + 1 * v(2)^2) .^ 0.5 + ...
                ~((abs(v(1)) < tangentThreshold) & ...
                (v(2) > 0)) * (1 * v(1)^2 + 1 * v(2)^2);
            
            %
            w      = [0 ; 1 ; 0];
            metric = @(v) norm(-(abs(w' * v)) * w(1:2) - v(1:2));
            
            %
            leftBundle  = fiberBundle1d.solveMap(this, ...
                this.midlineBundle, metric, leftSource, mapType, disp); % left
            rightBundle = fiberBundle1d.solveMap(this, ...
                this.midlineBundle,metric, rightSource, mapType, disp); % right
            
            %
            leftDistace  = leftBundle.distance(leftSource);
            rightDistace = rightBundle.distance(rightSource);
            rightDistace = flip(rightDistace, 1);
            wProfile     = min([leftDistace , rightDistace] , [] , 2);
        end
    end
end