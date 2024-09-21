classdef (Description='{#:*,ez-json:configurable}') doid < oid & matlab.mixin.SetGet

    properties (Description='{#:*,ez-json:configurable}')
        genDate char;
    end

    methods
        
        function [obj] = doid(varargin)
            obj = obj@oid(varargin{:});
            obj.genDate = datestr(now,'SSMMHHddmmYYYY');
        end
        
        function [cthis] = cupy(this)
            cthis = cupy@oid(this);
            cthis.genDate = datestr(now,'SSMMHHddmmYYYY');
        end
        
    end
    
    methods (Sealed)
        function [retTable] = tableProps(this,propList)
            cellTable = {};
            for e = 1:numel(propList)
                varNames{e} = propList{e}{1};
                tmpValue = propList{e}{2}(this);
                if ~iscell(tmpValue);tmpValue = {tmpValue};end
                varValues{e} = tmpValue;
                cellTable = cat(2,cellTable,tmpValue);
            end
            retTable = cell2table(cellTable,...
                 'VariableNames',varNames);
        end
        
        
        function [V] = get(this,K)
            V = get@matlab.mixin.SetGet(this,K);
        end
    end
    
    methods(Access = protected)
        
        
        function [cthis] = copyElement(this,isUnique)
            if nargin == 1;isUnique = false;end
            cthis = copyElement@oid(this);
            if isUnique
                cthis.genDate = datestr(now,'SSMMHHddmmYYYY');
            end
        end
        
    end
    
    methods (Static)
    
        function [S] = date2str(D)
            S = datetime(D,'InputFormat','ssmmHHddMMyyyy');
            S = char(S);
        end
        
        function [d] = getTimeStamp()
             d = datestr(now,'SSMMHHddmmYYYY');
        end
        
        function [d] = toDate(D)
            d = datetime(D,'InputFormat','ssmmHHddMMyyyy');
        end
        
        
       
         
        
    end
    
    
    
end