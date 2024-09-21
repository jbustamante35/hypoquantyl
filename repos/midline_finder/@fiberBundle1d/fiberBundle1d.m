classdef fiberBundle1d < fiberBundle & smoothCurve & handle & hasAnamedDomains & hasMidline
    %% fiberBundle1d: class to treat a curve as a fiber bundle
    % hasaFrame means that it can project into the attached space
    % when projecting outof
    properties
        %%
        quickRef = [];
    end
    
    methods
        %%
        function this = fiberBundle1d(curveData, smoothValue, varargin)
            %% fiberBundle1d
            if nargin < 2; smoothValue = 0; end
            
            this = this@smoothCurve(curveData, smoothValue);
            this = this@hasAnamedDomains;
            this = this@fiberBundle(1, 0, 0);
            
            if isa(curveData, 'sym')
                %%
                example     = curveData(0);
                embeddedDim = size(example, 2);
                fiberDim    = (size(example, 2) + 1) * ones(1,2);
                
                tmpBundle  = fiberBundle1d.generateTangentBundle(curveData);
                x          = argnames(tmpBundle);
                MAG        = smoothValue(2) - smoothValue(1);
                ntmpBundle = subs(tmpBundle, x, x*MAG);
                
                tmpF      =  matlabFunction(tmpBundle');
                tmpBundle = @(x) reshape(cell2mat(arrayfun( ...
                    tmpF, x', 'UniformOutput', 0))', [numel(x) , 3 , 3]);
                
                ntmpF      =  matlabFunction(ntmpBundle');
                ntmpBundle = @(x) reshape(cell2mat(arrayfun( ...
                    ntmpF, x', 'UniformOutput', 0))',[numel(x) , 3 , 3]);
                
                this.bundleCore('default')    = tmpBundle;
                this.bundleCore('normalized') = ntmpBundle;
                
            elseif isa(curveData,'function_handle')
                %%
                % evaluate the curve at 0 for making the fiber size
                example     = curveData(0);
                embeddedDim = size(example,2);
                fiberDim    = (size(example,2) + 1) * ones(1,2);
                
                % syms generates the tangent bundle - here we must provide
                tmpBundle  = varargin{1};
                MAG        = (smoothValue(2) - smoothValue(1));
                ntmpBundle = @(x)tmpBundle(x * MAG);
                
                tmpF      = tmpBundle;
                tmpBundle = @(x) reshape(cell2mat(arrayfun( ...
                    tmpF, x, 'UniformOutput', 0)), [numel(x) , 3 , 3]);
                
                ntmpF      = ntmpBundle;
                ntmpBundle = @(x) reshape(cell2mat(arrayfun( ...
                    ntmpF, x, 'UniformOutput', 0)),[numel(x) , 3 , 3]);
                
                this.bundleCore('default')    = tmpBundle;
                this.bundleCore('normalized') = ntmpBundle;
                
            else
                %%
                embeddedDim = size(curveData,2);
                fiberDim    = (size(curveData,2) + 1) * ones(1,2);
                
                % recover the curve data from the above smoothing step
                curveData = this.getCurveData;
                tmpBundle = fiberBundle1d.generateTangentBundle(curveData);
                
                % get the arclength data for functions
                [S , aS] = this.getArcLength;
                w        = this.getXwrap;
                
                % init the iFunction
                this.bundleCore('default')    = @(x) reshape(interp1( ...
                    S, tmpBundle(:,2:end), w(x,S(end))), [numel(x) , 3 , 3]);
                this.bundleCore('normalized') = @(x) reshape(interp1( ...
                    aS, tmpBundle(:,2:end), w(x,aS(end))), [numel(x) , 3 , 3]);
                
                % init the iFunction
                tmpBundle = this.getCenterOfMassBundleCore;
                
                this.bundleCore('centerBundle')           = @(x) reshape(interp1( ...
                    S, tmpBundle(:,2:end), w(x,S(end))), [numel(x) , 3 , 3]);
                this.bundleCore('centerBundleNormalized') = @(x) reshape(interp1( ...
                    aS, tmpBundle(:,2:end), w(x,S(end))), [numel(x) , 3 , 3]);
            end
            
            %
            this.fiberDim    = fiberDim;
            this.embeddedDim = embeddedDim;
        end
        
        function curveData = pcaEval(this, ivec)
            %% pcaEval
            curveData = [];
            for e = 1:numel(this.domainNames)
                ep = this.domains(this.domainNames{e});
                if ~(ivec(e) == 0)
                    l = linspace(ep(1), ep(2), ivec(e));
                    y = this.evalCurve(l, 'normalized');
                    curveData = [curveData ; y];
                end
            end
        end
        
        function bool = inContour(this, p)
            %% inContour
            if isempty(this.quickRef)
                this.quickRef = this.pcaEval([50 , 50 , 50 , 50]);
            end
            
            bool = inpolygon(p(1), p(2), ...
                this.quickRef(:,1), this.quickRef(:,2));
        end
        
        function attachSection(this, sectionData, sectionName)
            %% attachSection
            % get the arclength data for functions
            [S , aS] = this.getArcLength;
            w        = this.getXwrap;
            
            this.sectionCore(sectionName)                 = @(x) reshape( ...
                interp1(S, sectionData, w(x, S(end))), [numel(x) , 3 , 3]);
            this.sectionCore([sectionName '_normalized']) = @(x) reshape( ...
                interp1(aS, sectionData, w(x, aS(end))), [numel(x) , 3 , 3]);
        end
        
        % moved to the fiberBundle
        function y = eval(this, varargin)
            %% eval
            y = eval@fiberBundle(this,varargin{:});
        end
        
        function f = lambda(this, type)
            %% lambda
            if nargin < 2; type = 'default'; end
            
            f = this.bundleCore(type);
        end
        
        function tmp = neighborHoods(this, nSZ, downSample)
            %% neighborHoods
            if nargin < 3; downSample = 1; end
            
            % stack the curve data
            tmpC = this.getCurveData;
            tmp  = [tmpC ; tmpC ; tmpC];
            
            %
            sz  = [nSZ , 2];
            tmp = im2colF(tmp, sz, [1 , 1]);
            tmp = reshape(tmp,[sz , size(tmp,2)]);
            
            blockIDX                        = (size(tmp,3) - size(tmpC,1)) / 2;
            tmp(:,:,1:blockIDX)             = [];
            tmp(:,:,(end-(blockIDX-1)):end) = [];
            tmp                             = permute(tmp, [2 , 1 , 3]);
            
            % down sample if requested
            if downSample ~= 1
                tmp = tmp(:, 1 : downSample : end, :);
            end
        end
        
        function tmp = projectNhood(this, nSZ, downSample)
            %% projectNhood
            try
                tmp = this.neighborHoods(nSZ, downSample);
                tmp = cat(1,tmp,ones(1, size(tmp,2), size(tmp,3)));
                S   = this.getArcLength;
                
                for e = 1:numel(S)
                    tmp(:,:,e) = this.into(S(e), tmp(:,:,e));
                end
                
                tmp(end,:,:) = [];
            catch ME
                ME;
            end
        end
        
        function plot(this, cl, toQ, type, n)
            %% plot
            if nargin < 5; n    = round(this.getLength); end
            if nargin < 4; type = 'normalized';          end
            if nargin < 3; toQ  = false;                 end
            if nargin < 2; cl   = 'r';                   end
            
            x = linspace(0,1,n)';
            y = this.eval(x,type);
            
            curveData = squeeze(y(:,1:2,3));
            T         = squeeze(y(:,1:2,1));
            N         = squeeze(y(:,1:2,2));
            
            %
            plot(curveData(:,1), curveData(:,2), cl);
            hold on;
            if toQ
                myquiver(curveData(:,1), curveData(:,2), ...
                    T(:,1), T(:,2), 10, 'b');
                myquiver(curveData(:,1), curveData(:,2), ...
                    N(:,1), N(:,2), 10, 'g');
            end
        end
        
        function plotSection(this, sectionName, n)
            %% plotSection
            if nargin < 3; n = 1000; end
            
            x     = linspace(0,1,n)';
            y     = this.eval(x, 'normalized');
            sigma = this.sectionCore([sectionName , '_normalized']);
            v     = sigma(x);
        end
        
        function bundleCore = getCenterOfMassBundleCore(this)
            %% getCenterOfMassBundleCore
            % get the arc length and tangent bund
            curveData = this.getCurveData;
            S         = this.getArcLength;
            
            N    = curveData - this.centerOfMass;
            N    = -N;
            magN = sum(N .* N, 2) .^ -0.5;
            N    = bsxfun(@times, N, magN);
            T    = [N(:,2) , -N(:,1)];
            T    = [T , 0 * ones(size(T,1) , 1)];
            N    = [N , 0 * ones(size(N,1) , 1)];
            P    = [curveData , 1 * ones(size(curveData,1), 1)];
            
            [S , sidx] = unique(S);
            T          = T(sidx,:);
            N          = N(sidx,:);
            P          = P(sidx,:);
            
            bundleCore = [S , T , N , P];
        end
        
        function tmpBundle = getBundleCore(this, type)
            %% getBundleCore
            w         = functions(this.bundleCore(type));
            tmpBundle = w.workspace{1}.tmpBundle;
        end
        
        function data = into(this, si, data, type)
            %% into
            if nargin < 4; type = 'default'; end
            if nargin < 3; data = [0;0;1];   end
            
            if ischar(data)
                type = data;
                data = [0 ; 0 ; 1];
            end
            
            if size(data,1) <= 2
                data = cat(1, data, ones(1,size(data,2)));
            end
            
            f    = squeeze(this.eval(si, type));
            data = mtimesx(inv(f), data);
        end
        
        function f = mapTo(this, target, sourceType, targetType)
            %% mapTo
            if nargin < 3; sourceType = 'normalized'; end
            if nargin < 4; targetType = sourceType;   end
            
            %
            f = @(x,y)this.into(x, target.evalCurve(y,targetType)', sourceType);
        end
        
        function reverse(this)
            %% reverse
            b          = this.domains('bottom');
            this.baseT = [-1 ; b(1)];
            
            s1 = this.domains('rightSide');
            s2 = this.domains('top');
            s3 = this.domains('leftSide');
            s4 = this.domains('bottom');
            
            n1 = [0 , diff(s1)];
            n2 = [n1(2) , n1(2) + diff(s2)];
            n3 = [n2(2) , n2(2) + diff(s3)];
            n4 = [n3(2) , n3(2) + diff(s4)];
            
            this.domains('leftSide')  = n1;
            this.domains('top')       = n2;
            this.domains('rightSide') = n3;
            this.domains('bottom')    = n4;
        end
        
        function plotDomain(this, domainName, cl)
            %% plotDomain
            if nargin < 3; cl = 'r'; end
            
            domain = this.domains(domainName);
            l      = linspace(domain(1), domain(2), 500);
            x      = this.evalCurve(l, 'normalized');
            
            plot(x(:,1), x(:,2), cl);
        end
        
        function f = getFrame(this, si, type)
            %% getFrame
            if nargin < 3; type = 'default'; end
            
            f = this.eval(si,type);
        end
        
        function angle = protractor(this, pq, domainL, type, units, vecEnds, clr)
            %% protractor
            if nargin < 4; type    = 'normalized'; end
            if nargin < 5; units   = 'raw';        end
            if nargin < 6; vecEnds = {[] , []};    end
            if nargin < 7; clr     = 'r';          end
            
            if strcmp(units,'raw')
                %%
                f = this.iFunc('percent');
                
                % convert p
                p_raw     = f(pq(1));
                p_raw_str = max(p_raw - domainL, 0);
                p_raw_stp = min(p_raw + domainL, f(1));
                p_str     = this.invPercent(p_raw_str);
                p_stp     = this.invPercent(p_raw_stp);
                
                % convert q
                q_raw     = f(pq(2));
                q_raw_str = max(q_raw - domainL, 0);
                q_raw_stp = min(q_raw + domainL, f(1));
                q_str     = this.invPercent(q_raw_str);
                q_stp     = this.invPercent(q_raw_stp);
            else
                %%
                p_str = max(pq(1) - domainL, 0);
                p_stp = min(pq(1) + domainL, inf);
                
                q_str = max(pq(2) - domainL, 0);
                q_stp = min(pq(2) + domainL, inf);
            end
            
            %%
            domain = linspace(p_str, p_stp, 100);
            fAtp   = squeeze(this.eval(domain, type));
            p      = squeeze(fAtp(:, 1:2, 3));
            
            p(any(isnan(p),2),:) = [];
            [p , vp]             = PCA_FIT_FULLws(p,1);
            
            if ~isempty(vecEnds{1}); vp = vecEnds{1}; end
            
            %%
            domain = linspace(q_str,q_stp,100);
            fAtq   = squeeze(this.eval(domain,type));
            q      = squeeze(fAtq(:,1:2,3));
            
            %
            q(any(isnan(q), 2), :) = [];
            [q , vq]               = PCA_FIT_FULLws(q, 1);
            if ~isempty(vecEnds{2}); vq = vecEnds{2}; end
            
            %
            [alpha , i1 , i2] = fastIntercept(p, vp', q, vq');
            delta1            = p - i1;
            delta2            = q - i1;
            n                 = sign(delta1 * vp);
            n2                = sign(delta2 * vq);
            
            %
            XX    = n * vp;
            YY    = -[XX(2) , -XX(1)];
            FF    = [XX , YY']';
            xy    = FF * n2 * (vq);
            al    = -atan2(xy(2), xy(1));
            PT    = p + vp' * alpha(1);
            angle = al * 180 / pi;
            
            %%
            protractorPlot(PT, al, XX, 10);
            hold on;
            myquiver(p(1), p(2), vp(1), vp(2), alpha(1), clr);
            myquiver(q(1), q(2), vq(1), vq(2), -1 * alpha(2), clr);
%             plot(PT(1), PT(2), 'k.');
            plt(PT, 'k.', 10);
        end
        
        function plotPoint(this, si, cl, type)
            %% plotPoint
            if nargin < 3; cl   = 'r.';         end
            if nargin < 4; type = 'normalized'; end
            
            f = squeeze(this.getFrame(si, type));
            
            plot(f(1,3), f(2,3), cl);
            myquiver(f(1,3), f(2,3), f(1,1), f(2,1), 10, 'r');
            myquiver(f(1,3), f(2,3), f(1,2), f(2,2), 10, 'r');
        end
        
        function [k , x] = kurvature(this, x, type, smoothValue)
            %% kurvature
            if nargin < 2; x           = linspace(0, 1, round(this.getLength)); end            
            if nargin < 3; type        = 'normalized';                          end
            if nargin < 4; smoothValue = 0;                                     end
            
            if isempty(x); x = linspace(0, 1, round(this.getLength)); end
            
            if isa(x,'char')
                x = this.domains(x);
                x = linspace(x(1), x(2), round(this.getLength));
            end
            
            %%            
            f = this.eval(x, type);
            c = this.evalCurve(x, type);
            
            for e = 1 : (size(f,1) - 1)
                map    = squeeze(f(e+1,:,:)) \ squeeze(f(e,:,:));
                ds     = norm(map(1:2,3));
                dTH(1) = atan2(map(2,1), map(1,1));
                dTH(2) = atan2(-map(1,2), map(2,2));
                k(e)   = mean(dTH) / ds;
            end
            
            k          = real(k);
            smoothEndP = 'replicate';
            
            if this.isClosed; smoothEndP = 'circular'; end
            
            if smoothValue ~= 0
                k = imfilter(k, fspecial('gaussian', ...
                    [1 , 5 * smoothValue], smoothValue), smoothEndP);
            end
            
            %
            x = x(1:numel(k));
        end
        
        function [si , dis] = nearestBasePoint(this, p, domainName, initData)
            %% nearestBasePoint
            if nargin < 3; domainName = ''; end
            if nargin < 4; initData   = []; end
            
            %%
            if size(p,1) == 2
                p = [p ; ones(1, size(p,2))];
            end
            
            nRange      = 50;
            domainRange = [0 , 1];
            
            %
            if ~isempty(domainName)
                domainRange = sort(this.domains(domainName));
                if ~isempty(initData)
                    minRange = initData(1) - initData(2);
                    maxRange = initData(1) + initData(2);
                    
                    domainRange(1) = max(domainRange(1), minRange);
                    domainRange(2) = min(domainRange(2), maxRange);
                    
                    nRange = initData(3);
                end
            end
            
            %% for each point in p
            for e = 1 : size(p,2)
                % objective for base - project outout @ 0
                objective = @(x)norm(this.outof(x,'normalized')' - p(:,e));
                
                % break down the search into segments on the base
                l     = linspace(domainRange(1), domainRange(2), nRange);
                t_si  = [];
                t_dis = [];
                for s = 1:(numel(l)-1)
                    %options = optimset('Display','iter');
                    [t_si(s) , t_dis(s)] = fminbnd(objective, l(s), l(s + 1));
                end
                
                % select the min from the segmented search
                [dis(e) , midx] = min(t_dis);
                si(e)           = t_si(midx);
            end
        end

        function length = calculatelength(this, a, b, n)
            %% calculatelength
            if nargin < 2; a = 0;    end
            if nargin < 3; b = 1;    end
            if nargin < 4; n = 1000; end

            l      = linspace(a, b, n);
            crv    = this.evalCurve(l, 'normalized');
            dL     = diff(crv, 1);
            dL     = sum(dL .* dL, 2) .^ 0.5;
            length = sum(dL);
        end

        function pct = calculatePercentage(this, a, b, n)
            %% calculatePercentage
            if nargin < 5; n = 1000; end

            tot  = this.calculatelength(0, 1, n);
            part = b - a;
            pct  = part / tot;
        end
        
        function [p , r] = getApexLength(this, l, n)
            %%
            if nargin < 3; n = 10000; end
                        
            func    = @(q) abs(this.calculatelength(q,1,n) - l);
            [p , r] = fminbnd(func, 0, 1);
        end

        function b1(this, p)
            %% b1: make a straight linear bundle from the bundle map
            w      = [0 ; 1 ; 1]';
            metric = @(v) -(w(1:(end-1)) * v(1:(end-1))) / ...
                (norm(w(1:(end-1))) * norm(v(1:(end-1))));
            
            % make a straight linear bundle from the bundle map
            majorMap = fiberBundle1d.solveMap(this, this, ...
                metric, p, 'centerBundleNormalized', false);
            
            % make a straight linear bundle from the bundle map
            majorBundle = majorMap.induceBundle(p);
            
            N      = 100;
            leftH  = zeros(3,N);
            rightH = zeros(3,N);
            
            %% draw normals from major axis
            along = linspace(0.02, 0.98, N);
            for e = 1:numel(along)
                %% solve the bundle map for the matric from the 50%
                % location to the kernel curve manifold
                w         = [0 ; 1 ; 1]';
                metric    = @(v) -(w(1:(end-1)) * v(1:(end-1))) / ...
                    (norm(w(1:(end-1))) * norm(v(1:(end-1))));
                minorMapP = fiberBundle1d.solveMap(majorBundle, this, ...
                    metric,along(e), 'normalized', false);
                
                % induce the straight-linear fiber bundle
                minorBundle_p = minorMapP.induceBundle(along(e));
                
                %% solve for the other direction
                w         = [0 ; -1 ; 1]';
                metric    = @(v) -(w(1:(end-1)) * v(1:(end-1))) / ...
                    (norm(w(1:(end-1))) * norm(v(1:(end-1))));
                minorMapN = fiberBundle1d.solveMap(majorBundle, this, ...
                    metric,along(e), 'normalized', false);
                
                % induce the fiber bundle from the bundle map
                minorBundle_n = minorMapN.induceBundle(along(e));
                
                % project outward the end points of the trace
                leftH(:,e) = minorBundle_p.outof(1,'normalized');
                rightH(:,e) = minorBundle_n.outof(1,'normalized');
                minorMapP.fuse(minorMapN); % fuse
                
                % make induced width bundle
                [~ , widthBundle] = minorMapP.induceBundle(along(e));
                
                %%
                this.plot('r');
                hold on;
                majorBundle.plot('g');
                minorBundle_p.plot('b');
                minorBundle_n.plot('c');
                widthBundle.plot('k');
                axis equal;
                hold off;
                drawnow;
            end
            
            this.into(along, leftH, 'normalized')
        end
        
        function [M , SEGblocks] = measureMajorAxis(this,NP,subD,mmT,sourceSpace)
            %% measureMajorAxis
            if nargin < 2; NP          = 500;          end
            if nargin < 3; subD        = 20;           end
            if nargin < 4; mmT         = 'normalized'; end
            if nargin < 5; sourceSpace = '*';          end
            
            try
                %%
                disp       = false;
                w          = [0 ; 1 ; 0];
                corrMetric = @(v) (w(1:(end-1))' * v(1:(end-1))) / ...
                    (norm(w(1:(end-1))) * norm(v(1:(end-1))));
                metric     = @(v) norm((w' * v) * ...
                    w(1:2) - v(1:2)) - corrMetric(v);
                majorMap   = fiberBundle1d.solveMap(this, this, ...
                    metric, sourceSpace, mmT, false, [0 , 1], subD);
                
                if isa(sourceSpace, 'char')
                    if strcmp(sourceSpace, '*')
                        sourceSpace = linspace(0, 1, NP);
                    end
                end
                
                %%
                for e = 1 : numel(sourceSpace)
                    %% make a straight linear bundle from the bundle map
                    majorBundle = majorMap.induceBundle(sourceSpace(e));
                    
                    % solve the bundle map for the metric from the 50%
                    % location to the kernel curve manifold
                    w      = [0 ; 1 ; 1]';
                    metric = @(v) -(w(1:(end-1)) * v(1:(end-1))) / ...
                        (norm(w(1:(end-1))) * norm(v(1:(end-1))));
                    
                    w          = [0 ; -1 ; 0];
                    corrMetric = @(v) (w(1:(end-1))' * v(1:(end-1))) / ...
                        (norm(w(1:(end-1))) * norm(v(1:(end-1))));
                    metric     = @(v) norm(abs((w' * v)) * ...
                        w(1:2) - v(1:2)) - corrMetric(v);
                    minorMapP  = fiberBundle1d.solveMap(majorBundle, this, ...
                        metric, 0.5, 'normalized', false, [0 , 1], subD);
                    
                    % induce the straight-linear fiber bundle
                    minorBundle_p = minorMapP.induceBundle(.5);
                    
                    %% solve for the other direction
                    w          = [0 ; 1 ; 0];
                    corrMetric = @(v) (w(1:(end-1))' * v(1:(end-1))) / ...
                        (norm(w(1:(end-1))) * norm(v(1:(end-1))));
                    metric     = @(v) norm(abs((w' * v)) * ...
                        w(1:2) - v(1:2)) - corrMetric(v);
                    minorMapN  = fiberBundle1d.solveMap(majorBundle, ...
                        this, metric, 0.5, 'normalized', false, [0 , 1], subD);
                    
                    % induce the fiber bundle from the bundle map
                    minorBundle_n = minorMapN.induceBundle(0.5);
                    
                    % fuse
                    minorMapP.fuse(minorMapN);
                    
                    % make induced width bundle
                    [~ , widthBundle] = minorMapP.induceBundle(0.5);
                    
                    %
                    M(e,:) = [majorBundle.getLength , widthBundle.getLength];
                    SEGblocks(:,:,1,e) = [majorBundle.outof([0], 'normalized')', ...
                        majorBundle.outof(1, 'normalized')'];
                    SEGblocks(:,:,2,e) = [widthBundle.outof([0], 'normalized')', ...
                        widthBundle.outof(1, 'normalized')'];
                    
                    %% Plot
                    if disp
                        this.plot('r');
                        hold on;
                        majorBundle.plot('g');
                        minorBundle_p.plot('b');
                        minorBundle_n.plot('c');
                        widthBundle.plot('k');
                        axis equal;
                        hold off;
                        drawnow;
                    end
                end
                here = 1;
            catch ME
                ME;
            end
            stop = 1;
        end
        
        function [M , SEGblocks] = measureMajorAxis2(this, MASK, maxLength, coreSelect)
            %% measureMajorAxis2
            if nargin < 4; coreSelect = 'bundleCore'; end
            if nargin < 3; maxLength  = 1400;         end
            
            %%
            baseIndex = this.getArcLength;
            disp      = 0;
            
            % fill the mask and get the major axis projections
            MASK = imfill(MASK, 'holes');
            MASK = double(MASK);
            SEG  = this.projectDomain(MASK, baseIndex, maxLength, coreSelect);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% find the width measurements
            lenVec            = diff(SEG, 1, 2);
            midP              = SEG(:,1,:) + 0.5 * lenVec;
            lenVec_normalized = squeeze(lenVec);
            L                 = sum(lenVec_normalized .* ...
                lenVec_normalized, 1) .^ 0.5;
            
            %
            lenVec_normalized = bsxfun(@times, lenVec_normalized, L .^ -1);
            widVec_normalized = [lenVec_normalized(2,:) ; ...
                -lenVec_normalized(1,:)];
            
            %%
            scaleAlong = linspace(-maxLength / 2, maxLength / 2, maxLength + 1);
            halfPoint  = round((numel(scaleAlong) - 1) / 2);
            for e = 1 : size(widVec_normalized, 2)
                lineSEG = squeeze(midP(:,1,e)) + ...
                    widVec_normalized(:,e) * scaleAlong;
                inMask  = ba_interp2(MASK, lineSEG(1,:), lineSEG(2,:)) > 0.7;
                inMask  = imfill(~inMask, halfPoint) == inMask;
                lineSEG = lineSEG(:,inMask);
                
                if ~isempty(lineSEG)
                    wSEG(:,:,e) = [lineSEG(:,1) , lineSEG(:,end)];
                else
                    wSEG(:,:,e) = 0;
                end
                
                %%
                if disp
                    imshow(MASK,[]);
                    hold on;
                    plot(SEG(1,:,e), SEG(2,:,e), 'b');
                    plot(wSEG(1,:,e), wSEG(2,:,e), 'r');
                    hold off;
                    this.zoomTo(0.2);
                    drawnow;
                end
            end
            
            %%
            dL = squeeze(sum(diff(SEG, 1, 2) .^2, 1) .^ 0.5);
            dW = squeeze(sum(diff(wSEG, 1, 2) .^2, 1) .^ 0.5);
            M  = [dL , dW];
            
            SEGblocks = cat(4, SEG, wSEG);
        end
    end
    
    methods (Static)
        %%
        function c = fromEndPoints(startPoint, endPoint)
            %% fromEndPoints
            delta = endPoint - startPoint;
            np    = round(norm(delta));
            
            if np <= 1
                np = 3;
            end
            
            l1 = linspace(startPoint(1), endPoint(1), np);
            l2 = linspace(startPoint(2), endPoint(2), np);
            L  = [l1' , l2'];
            c  = fiberBundle1d(L, 0);
        end
        
        function bundleCore = generateTangentBundle(curveData)
            %% generateTangentBundle
            disp = false;
            if isa(curveData,'sym')
                %%
                syms m al(a);
                d          = diff(curveData);
                m          = eye(2);
                dl         = d * m * d.';
                al(a)      = int(dl, 0, a);
                dd         = diff(d);
                bundleCore = [d , 0 , dd , 0 , curveData , 1];
            else
                %%
                normalMag = 1;
                
                % get tangent space
                T             = gradient(curveData')';
                normalizedTan = sum(T .* T, 2) .^ -0.5;
                S             = normalizedTan .^ -1;
                S             = cumsum(S);
                T             = bsxfun(@times, T, normalizedTan);
                
                % get normal space and make affine
                N = [-T(:,2) , T(:,1)];
                N = normalMag * N;
                T = [T , 0 * ones(size(T,1),1)];
                N = [N , 0 * ones(size(N,1),1)];
                P = [curveData , 1 * ones(size(curveData,1),1)];
                
                if disp
                    plot(curveData(:,1), curveData(:,2), 'r');
                    hold on;
                    myquiver(curveData(:,1), curveData(:,2), ...
                        T(:,1), T(:,2), 10, 'b');
                    myquiver(curveData(:,1), curveData(:,2), ...
                        N(:,1), N(:,2), 10, 'g');
                end
                
                % set the arclength to zero
                S          = S - S(1);
                bundleCore = [S , T , N , P];
            end
        end
        
        function bMap = solveMap(source, target, metric, sourceSpace, mapType, disp, targetRange, solutionDivision)
            %% solveMap
            if nargin < 4; sourceSpace      = '*';          end
            if nargin < 5; mapType          = 'normalized'; end
            if nargin < 6; disp             = false;        end
            if nargin < 7; targetRange      = [0 , 1];      end
            if nargin < 8; solutionDivision = 25;           end
            
            %%
            nullEPS   = 0.05;
            dispDebug = disp;
            
            f = source.mapTo(target, mapType);
            
            if ischar(sourceSpace)
                resolution  = round(source.getLength);
                sourceSpace = linspace(0, 1, 2 * resolution)';
            end
            
            if numel(sourceSpace) == 1
                epsN        = 0.03;
                sourceSpace = linspace( ...
                    sourceSpace - epsN, sourceSpace + epsN, 5);
            end
            
            per      = 0.1;
            strPoint = [0 ; 0 ; 1];
            norTH    = 10;
            minRange = -1;
            maxRange = 2;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% for each source point
            % PARFOR
            parfor e = 1 : numel(sourceSpace)
                e;
                if source == target
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % set range to not allow self solution
                    minRange = sourceSpace(e) + per;
                    maxRange = sourceSpace(e) + 1 - per;
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % set the source
                func      = @(y) f(sourceSpace(e), y);
                objective = @(x) applyMetric(func(x), metric, 1);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % first attempt - does not sub divide and solve
                % second attempt does sub divide
                targetDomainN = 25;
                solutionDivision;
                
                lDomain  = linspace( ...
                    targetRange(1), targetRange(2), solutionDivision);
                solution = zeros(numel(lDomain) - 1, 1);
                value    = zeros(numel(lDomain) - 1, 1);
                Dvalue   = zeros(numel(lDomain) - 1, 1);
                lDomain  = sort(lDomain, 'ascend');
                
                %%
                sourceP = source.evalCurve(sourceSpace(e), 'normalized');
                for l = 1:(numel(lDomain)-1)
                    [solution(l) , value(l) , a , b] = ...
                        fminbnd(objective, lDomain(l), lDomain(l+1));
                    
                    targetP   = target.evalCurve(solution(l), 'normalized');
                    deltaP    = norm(sourceP - targetP);
                    Dvalue(l) = norm(sourceP - targetP);
                    
                    % why not set the Dvalue?
                    % because I am seeking to min value - thats why
                    if deltaP < 1; value(l) = inf; end
                    
                    %%
                    if dispDebug
                        source.plot('r');
                        hold on;
                        
                        % view the solution scatter
                        tmpS = source.evalCurve(sourceSpace(e), 'normalized');
                        tmpT = target.evalCurve(solution(l), 'normalized');
                        
                        plot(tmpS(1), tmpS(2), 'g.');
                        plot(tmpT(1), tmpT(2), 'r*');
                        text(tmpT(1) + 5, tmpT(2) + 5, num2str(l));
                        axis equal;
                    end
                end
                
                %%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % This assumes that all solutions < threshod = 1
                % are amoung the potential solutions
                % and that we should select the one with the greatest
                % distance from the source point
                % however I am trying another with norm(dx) - corr
                %%%%%
                % why do i set some to inf?
                % because only solution were I strike the line count.
                % those are where value < some small number
                % these are all solutions
                % lets pick the nearest
                % vs find the max distance point after > thresh = 0;
                if ~all(value > 0)
                    vidx               = find(value > 0);
                    Dvalue(vidx)       = -inf;
                    [svalue(e) , midx] = max(Dvalue);
                    targetSpace(e)     = solution(midx);
                else
                    [svalue(e) , midx] = min(value);
                    targetSpace(e)     = solution(midx);
                end
                
                %%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % get the end point solution
                %p = f(sourceSpace(e),targetSpace(e));
                
                % the start point is the constant [0,0]
                %majorBundle = fiberBundle1d.fromEndPoints(strPoint,p);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Solution points
                p       = f(sourceSpace(e), targetSpace(e));
                tmpLine = [strPoint , p];
                
                if disp
                    %                     c = f(sourceSpace(e),sourceSpace);
                    %                     plot(c(1,:),c(2,:),'k');hold on
                    %                     plot(p(1),p(2),'r.')
                    %                     plot([0,0],[500,0],'b')
                    
                    lineBundle = source.outof( ...
                        sourceSpace(e), tmpLine, mapType)';
                    
                    source.plot('r');
                    hold on;
                    target.plot('b');
                    plot(lineBundle(1,:), lineBundle(2,:), 'g')
                    plot(lineBundle(1,1), lineBundle(2,1), 'g.')
                    plot(lineBundle(1,2), lineBundle(2,2), 'r.')
                    
                    hold off
                    axis equal
                    title(num2str(e))
                    drawnow
                    %pause(.2)
                end
            end
            targetSpace = targetSpace';
            targetSpace = unwrap(targetSpace,.9,1,1);
            
            map  = @(x)interp1(sourceSpace, targetSpace, x);
            bMap = bundleMap(map, source, target);
        end
        
        function maxMapPoints = maxMap(source, target, metric, mapType, initX)
            %% maxMap
            f            = source.mapTo(target, mapType);
            objective    = @(x) applyMetric(f(x(1), x(2)), metric, 1);
            maxMapPoints = fminsearch(objective, initX);
        end
    end
end

