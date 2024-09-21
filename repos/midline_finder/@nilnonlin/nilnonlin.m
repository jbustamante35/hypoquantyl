classdef nilnonlin
    %%
    properties
        %% ok but wtf are these variables
        f
        g
        h
        ex
        ey
        x
        y
    end
    
    methods
        %%
        function this = nilnonlin(f, g, h)
            %% nilnonlin
            this.f = f;
            this.g = g;
            this.h = h;
            this.x = [];
            this.y = [];
        end
        
        function z = F(this, x, y)
            %% F
            nextStop = false;
            atEnd    = false;
            ix       = 1;
            iy       = 1;
            iz       = 1;
            
            % run one test of the h-function and get the size of the h(f,g)
            testZ = this.h(this.f(x(:,1)), this.g(y(:,1)));
            szZ   = size(testZ);
            
            z = zeros(numel(testZ), max(size(x,2), size(y,2)));
            if (ix == size(x,2)) && (iy == size(y,2))
                nextStop = true;
            end
            
            while ~atEnd
                if nextStop
                    atEnd = true;
                end
                
                tmpResult = this.h(this.f(x(:,ix)), this.g(y(:,iy)));
                
                z(:,iz) = tmpResult(:);
                if (ix ~= size(x,2))
                    ix = ix +1;
                end
                
                if (iy ~= size(y,2))
                    iy = iy +1;
                end
                
                if (ix == size(x,2)) && (iy == size(y,2))
                    nextStop = true;
                end
                
                iz = iz + 1;
            end
            
            % remake the objects in the front of z-vector and move it to the bac
            z = reshape(z, [szZ , size(z,2)]);
            z = permute(z,[numel(szZ) + 1 , 1 : numel(szZ)]);
        end
        
        function z = lt(this, x)
            %% lt
            x.ex = this;
            z    = x;
        end
        
        function z = or(this, x)
            %% or
            if isa(this, 'nilnonlin')
                this.y = x;
                z      = this;
            elseif isa(x, 'nilnonlin')
                x.x = this;
                z   = x;
            end
        end
        
        function z = gt(this, x)
            %% gt
            this.ey = x;
            z       = this.F(this.x, this.y);
        end
        
        function varargout = subsref(this, S)
            %% subsref
            switch S(1).type
                case '()'
                    varargout{1} = this.F(S(1).subs{1}, S(1).subs{2});
                case '{}'
                    [varargout{1:nargout}] = builtin('subsref', this, S);
                case '.'
                    [varargout{1:nargout}] = builtin('subsref', this, S);
            end
        end
    end
end
