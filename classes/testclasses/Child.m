%% child test

classdef Child < Main
    properties (Access = public)
        ChildName
        TotalSubs
        %Parent
    end
    
    properties (Access = private)
        Subs
    end
    
    methods (Access = public)
        
        function obj = Child(varargin)
            if ~isempty(varargin)
                args = obj.parseConstructorInput(varargin);
                
                fn = fieldnames(args);
                for k = fn'
                    obj.(cell2mat(k)) = args.(cell2mat(k));
                end
                
            else
                obj.ChildName = 'hellow';
            end
        end
        
        function obj = AddSub(obj, sub)
            try
%                 sub.setParent(obj);
                if obj.TotalSubs == 0
                    obj.Subs = sub;
                else
                    nxt = obj.TotalSubs + 1;
                    obj.Subs(nxt) = sub;
                end
                
                obj.TotalSubs = obj.TotalSubs + 1;
            catch e
                e.getReport;
            end
        end
        
        function obj = setParent(obj, p)
            obj.Parent = p;
        end
        
        function p = getParent(obj)
            p = obj.Parent;
        end        
        
        function subs = getSubs(obj)
            subs = obj.Subs;
        end
    end
    
    methods (Access = private)
        function args = parseConstructorInput(varargin)
            p = inputParser;
            p.addRequired('ChildName');
            p.addOptional('TotalSubs', 0);
            p.addOptional('Subs', []);
            
            p.parse(varargin{2}{:});
            args = p.Results;
        end
    end
end

