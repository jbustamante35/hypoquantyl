%% main test

classdef Main < handle
    properties (Access = public)
        MainName
        TotalChildren
        TotalGrandchildren
    end
    
    properties (Access = private)
        Children
    end
    
    methods (Access = public)
        
        function obj = Main(varargin)
            if ~isempty(varargin)
                args = obj.parseConstructorInput(varargin);
                
                fn = fieldnames(args);
                for k = fn'
                    obj.(cell2mat(k)) = args.(cell2mat(k));
                end
                
            else
                obj.MainName = 'hellow';
            end
        end
        
        function obj = AddChild(obj, child)
            try
%                 child.setParent(obj);
                if obj.TotalChildren == 0
                    obj.Children = child;
                else
                    nxt               = obj.TotalChildren + 1;
                    obj.Children(nxt) = child;
                end
                
                obj.TotalChildren = obj.TotalChildren + 1;
            catch e
                e.getReport;
            end
        end
        
        function children = getChildren(obj)
            children = obj.Children;
        end

        function grandchildren = getGrandchildren(obj)
            grandchildren = arrayfun(@(x) x.getSubs, ...
                obj.Children, 'UniformOutput', 0);
            grandchildren = cat(1, grandchildren{:});
            obj.TotalGrandchildren = numel(grandchildren);
        end
    end
    
    methods (Access = private)
        function args = parseConstructorInput(varargin)
            p = inputParser;
            p.addRequired('MainName');
            p.addOptional('TotalChildren', 0);
            p.addOptional('TotalGrandchildren', 0);
            p.addOptional('Children', []);
            
            p.parse(varargin{2}{:});
            args = p.Results;
        end
    end
end

