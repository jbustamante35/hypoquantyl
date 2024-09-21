classdef smoothCurve < handle
    %% smoothCurve: class to measure curves
    % 
    % Usage:
    %   this = smoothCurve(curveData, smoothNumber)
    %
    % Input:
    %   curveData: coordinates of a curve
    %   smoothNumber: length to create curve
    
    properties
        %%
        iFunc
        isClosed
        centerOfMass
        length
        isSymbolic
        domainLimits
    end
    
    methods
        %%
        function this = smoothCurve(curveData, smoothNumber)
            %% smoothCurve
            if nargin < 2; smoothNumber = 0; end
            
            % init the map of named functions
            this.iFunc = containers.Map('KeyType', 'char', 'ValueType', 'any');
            if isa(curveData,'sym')
                %%
                this.isSymbolic = true;
                this.isClosed   = false;
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % use the smooth number as the total length of the curve
                totalLength_L     = smoothNumber;
                this.domainLimits = smoothNumber;
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % assign the curve data to the function
                func = @(x)cellfunSym(@double, curveData, x);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % find the x value that is at 100%
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % find the differential
                d = diff(curveData);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % make the metric
                syms m;
                m  = eye(2);
                dl = (d*m*d.')^.5;
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % make the arc length function
                syms len(x0);
                
                % integrate the arc length to a spot x0
                len(x0) = int(dl, 0, x0);
                
                % constrait integration to a fraction of total
                syms lengthCon(x0,h,totalLength);
                
                %
                lengthCon(x0, h, totalLength) = len(x0) == h * totalLength;
                
                %
                this.length = int(dl, smoothNumber(1), smoothNumber(2));
                
                %
                tmpFunc(h,totalLength) = solve(lengthCon, x0);
                
                %
                tmpFunc(h) = subs(tmpFunc, totalLength, totalLength_L);
                tmpFunc(h) = subs(curveData, tmpFunc);
                afunc      = @(x) cellfunSym(@double, tmpFunc, x);
                pfunc      = '';
            elseif isa(curveData,'function_handle')
                %%
                this.isSymbolic = true;
                this.isClosed   = false;
                
                % use the smooth number as the total length of the curve
                totalLength_L     = smoothNumber;
                this.domainLimits = smoothNumber(1:2);
                
                % assign the curve data to the function
                func        = curveData;
                this.length = abs(smoothNumber(2) - smoothNumber(1));
                afunc       = @(x)func(this.length * x);
                pfunc       = '';
            else
                %%
                this.isSymbolic = false;
                
                % determine is closed and remove repeats
                [curveData , this.isClosed , w] = ...
                    smoothCurve.uniqueANDclosed(curveData);
                
                % smooth the base curve
                if smoothNumber ~= 0
                    N          = size(curveData, 1);
                    smoothEndP = 'replicate';
                    if this.isClosed
                        smoothEndP = 'circular';
                    end
                    
                    curveData = imfilter(curveData, ...
                        ones(smoothNumber,1) / smoothNumber,smoothEndP);
                    curveData = arcLength(curveData, 'spec', N);
                end
                
                % get the center of mass
                this.centerOfMass = mean(curveData, 1);
                
                % get the arclength
                T             = gradient(curveData')';
                normalizedTan = sum(T .* T, 2) .^ -0.5;
                S             = normalizedTan .^ -1;
                S             = cumsum(S);
                S             = S - S(1);
                aS            = S / S(end);
                
                % the default function
                func  = @(s) interp1(S, curveData, w(s,S(end)));
                afunc = @(s) interp1(aS, curveData, w(s,S(end)));
                pfunc = @(s) interp1(aS, S, w(s,S(end)));
            end
            
            this.iFunc('default')   = func;
            this.iFunc('arclength') = afunc;
            this.iFunc('percent')   = pfunc;
        end
        
        function x = invPercent(this,y)
            %% invPercent
            pfunc         = this.iFunc('percent');
            objective     = @(x)norm(pfunc(x) - y);
            [x , yapprox] = fminbnd(objective, 0, 1);
        end
        
        function y = eval(this, x, type)
            %% eval
            if nargin < 3; type = 'default'; end
            f = this.iFunc(type);
            y = f(x);
        end
        
        function plot(this,N)
            %% plot
            if nargin < 2; N = 100; end
            
            x = linspace(0, 1, N)';
            y = this.eval(x, 'arclength');
            plot(y(:,1), y(:,2), 'r')
        end
        
        function [S , aS] = getArcLength(this, n)
            %% getArcLength
            if nargin < 2; n = 100; end
            if ~this.isSymbolic
                tmp = functions(this.iFunc('default'));
                tmp = tmp.workspace{1};
                S   = tmp.S;
                aS  = S / S(end);
            else
                S  = linspace(this.domainLimits(1), this.domainLimits(1), n);
                aS = linspace(0, 1, n);
            end
        end
        
        function curveData = getCurveData(this)
            %% getCurveData
            func = this.iFunc('default');
            if isa(func,'sym')
                curveData = func;
            else
                tmp       = functions(func);
                tmp       = tmp.workspace{1};
                curveData = tmp.curveData;
            end
        end
        
        function w = getXwrap(this)
            %% getXwrap
            tmp = functions(this.iFunc('default'));
            tmp = tmp.workspace{1};
            w   = tmp.w;
        end
        
        function length = getLength(this)
            %% getLength
            if ~this.isSymbolic
                S      = this.getArcLength;
                length = S(end);
            else
                length = this.length;
                length = 100;
            end
        end
    end
    
    methods (Static)
        function [curveData , bool , w] = uniqueANDclosed(curveData)
            %% uniqueANDclosed
            try
                endPoint         = curveData(end,:); % get the end point
                curveData(end,:) = [];               % remove the end point
                curveData        = unique(curveData, 'stable', 'rows'); % ensure the points are unique
                
                % re-attach the end point if nessary
                if ~all(curveData(end,:) == endPoint)
                    curveData = [curveData;endPoint];
                end
                
                bool = all(curveData(1,:) == curveData(end,:));
                
                % wrap if closed
                if bool
                    w = @(s,lastValue) arcLengthWrap(s,lastValue);
                else
                    w = @(s,lastValue) s;
                end
            catch ME
                ME;
            end
        end
    end
end