classdef fiberBundle < handle & hasAframe
    %%
    properties
        %%
        % core data for [frame,point] - total space
        % map of parameterized functions
        % map : string -> function
        % function : base -> total
        % the first set of index [0 N] goes along the base
        % 0 - simple non parameterized base
        % 1 - curve in space - N space - fiber of tensor algebra
        bundleCore
        
        % now I am wanting another parameterization for the base
        % the "first" slots [0 N] are the same as before
        % but the "second" slots are for the parameters NOT of the fiber
        % but rather for the flex of the base
        %%% example - radius for the circle for the base
        %%% example scores for/from pca
        
        % linear transformationon base
        baseT
        
        % section data - section data for expressing information in the bundle
        sectionCore
        
        % base dim and order
        baseDim
        
        % embedded dim - scalar
        embeddedDim
        
        % base dim and order
        fiberDim
        
        % forward in inverse projector
        proj
        inv_proj
    end
    
    methods
        %%
        function this = fiberBundle(baseDim, embeddedDim, fiberDim)
            %% fiberBundle            
            this@hasAframe;
            
            % init linear T on base
            this.baseT = eye(baseDim + 1);
            this.baseT = this.baseT(:,1);
            
            % init the bundle core container
            this.bundleCore = containers.Map( ...
                'KeyType', 'char', 'ValueType', 'any');
            
            % init the section core container
            this.sectionCore = containers.Map( ...
                'KeyType', 'char', 'ValueType', 'any');
            
            this.baseDim     = baseDim;     % set the base dim
            this.embeddedDim = embeddedDim; % set the embedded dim
            this.fiberDim    = fiberDim;    % set the fiber dim
            
            % attach default projector
            f         = @(x) reshape(x, this.fiberDim);
            g         = @(x) reshape(x, ...
                [this.fiberDim(2) , numel(x)/this.fiberDim(2)]);
            h         = @(x,y) mtimesx(x,y);
            this.proj = nilnonlin(f, g, h);
            
            % attach default inv-projector
            f = @(x) inv(reshape(x, this.fiberDim));
            g = @(x) reshape(x, [this.fiberDim(2) , numel(x)/this.fiberDim(2)]);
            h = @(x,y) mtimesx(x,y);
            
            this.inv_proj = nilnonlin(f,g,h);
        end
        
        function x = b(this, x)
            %% b
            try
                x = [x , ones(size(x))] * this.baseT;
            catch ME
                ME
            end
        end
        
        function y = eval(this, x, type)
            %% eval
            if nargin < 2; x    = 0;         end
            if nargin < 3; type = 'default'; end
            
            if size(x,2) > size(x,1)
                x = x';
            end
            
            x = this.b(x);
            
            %
            f = this.bundleCore(type);
            y = f(x);
            
            % coupled projector
            if ~isempty(this.expressFrame)
                [y , i]  = this.flatten(y);
                newFrame = this.expressFrame.eval(0);
                newFrame = this.expressFrame.flatten(newFrame);
                
                f = @(x)reshape(x, this.expressFrame.fiberDim);
                g = @(x)reshape(x, ...
                    [this.fiberDim(2) , numel(x) / this.fiberDim(2)]);
                h = @(x,y)mtimesx(x,y);
                T = nilnonlin(f, g, h);
                y = T.F(newFrame', y');
            end
        end
        
        function y = evalCurve(this, x, type)
            %% evalCurve
            try
                if nargin < 2; x    = 0;         end
                if nargin < 3; type = 'default'; end
                
                % column vector
                if size(x,2) > size(x,1)
                    x = x';
                end
                
                x = this.b(x);
                f = this.bundleCore(type);
                y = f(x);
                
                % coupled projector
                if ~isempty(this.expressFrame)
                    [y , i]  = this.flatten(y);
                    newFrame = this.expressFrame.eval(0);
                    newFrame = this.expressFrame.flatten(newFrame);
                    
                    f = @(x)reshape(x, this.expressFrame.fiberDim);
                    g = @(x)reshape(x, ...
                        [this.fiberDim(2) , numel(x) / this.fiberDim(2)]);
                    h = @(x,y)mtimesx(x,y);
                    T = nilnonlin(f, g, h);
                    y = T.F(newFrame', y');
                end
                
                y = y(:, 1:2, 3);
            catch ME
                ME
            end
        end
        
        function [X , i] = inflate(this, X, i)
            %% inflate
            [X , i] = iflattenTensor(X, i);
        end
        
        function [X , i] = flatten(this, X)
            %% flatten
            totalSpaceIndex = 1 : (this.baseDim + numel(this.fiberDim));
            baseSpaceIndex  = totalSpaceIndex(1 : this.baseDim);
            fiberSpaceIndex = totalSpaceIndex((this.baseDim + 1) : end);
            
            [X , i] = flattenTensor(X, {baseSpaceIndex , fiberSpaceIndex});
        end
        
        function data = outof(this, si, data, type)
            %% outof
            % here vectors are expected along [1] in data
            % sequences of vectors are expanded along [2] in data
            try
                if nargin < 4; type = 'default';   end
                if nargin < 3; data = [0 ; 0 ; 1]; end
                
                if ischar(data)
                    type = data;
                    data = [0 ; 0 ; 1];
                end
                
                if size(data,1) <= 2
                    data = cat(1, data, ones(1, size(data,2)));
                end
                
                f       = this.eval(si,type); % eval to get the total space = base + fiber
                [f , i] = this.flatten(f);    % flatten fiber along base
                
                % use default projector
                data = this.proj(f',data);
            catch ME
                ME
            end
        end
        
        function data = into(this, si, data, type)
            %% into
            if nargin < 4; type = 'default';   end
            if nargin < 3; data = [0 ; 0 ; 1]; end
            
            if ischar(data)
                type = data;
                data = [0 ; 0 ; 1];
            end
            
            if size(data,1) <= 2
                data = cat(1, data, ones(1, size(data,2)));
            end
            
            f    = this.eval(si,type);    % eval to get the total space = base + fiber
            f    = this.flatten(f)';      % flatten fiber along base
            data = this.inv_proj(f,data); % use default projector
        end
    end
end
