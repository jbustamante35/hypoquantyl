%% subchild test

classdef Subchild < Child
    properties (Access = public)
        SubName
       % Parent
       % Grandparent
    end
    
    properties (Access = private)
        Message
    end
    
    methods (Access = public)
        
        function obj = Subchild(varargin)
            if ~isempty(varargin)
                args = obj.parseConstructorInput(varargin);
                
                fn = fieldnames(args);
                for k = fn'
                    obj.(cell2mat(k)) = args.(cell2mat(k));
                end
                
            else
                obj.SubName = 'hellow';
            end
        end
        
        function obj = sayWassup(obj)
            fprintf('%s\n', obj.Message);
        end
        
        function obj = setParent(obj, p)
            obj.Parent      = p;
            obj.Grandparent = p.getParent;
        end
                
        function p = getParent(obj)
            p = obj.Parent;
        end
        
        function g = getGrandParent(obj)
            g = obj.Grandparent;
        end
    end
    
    methods (Access = private)
        function args = parseConstructorInput(varargin)
            p = inputParser;
            p.addRequired('SubName');
            p.addOptional('Message', 'wassup');
            
            p.parse(varargin{2}{:});
            args = p.Results;
        end
    end
end

