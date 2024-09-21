classdef oidmm < handle & matlab.mixin.Copyable
    
    properties
        uuid;
        type;
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [obj] = oidmm(type,uuid)
            if nargin == 0;type = class(obj);end
            %if nargin < 2;[~,uuid] = system('uuidgen');end
            if nargin <= 1;uuid = char(java.util.UUID.randomUUID);end
            obj.uuid = strtrim(uuid);
            obj.type = type;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [hash] = hash(obj)
            tmp = oid.proj(obj);
            id = jsonencode(tmp);
            cmd = ['echo -n ''' id ''' | sha256sum'];
            [~,hash] = system(cmd);
            hash = hash(1:end-4);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % detach the object from other objects
        % replace the connections with pointers (dptr)
        % loop over the properties of the object
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = detach(obj)
            % get the properties of the object
            prop = properties(obj);
            % for each property
            for p = 1:numel(prop)
                
                
                % if the object is a oid or greater
                if isa(obj.(prop{p}),'oid')
                    % loop over the oid array and convert to ptr
                    for e = 1:numel(obj.(prop{p}))
                        if ~isa(obj.(prop{p})(e),'dptr')
                            obj.(prop{p})(e) = dptr(obj.(prop{p})(e));
                        end
                    end
                end
                
                
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [muuid] = genmuuid(obj)
            muuid = ['m' strrep(obj.uuid,'-','_')];
        end
        
        function [cthis] = cupy(this)
            cthis = copy(this);
            [~,cthis.uuid] = system('uuidgen');
            cthis.uuid = strtrim(cthis.uuid);
        end
    end
    
    methods(Access = protected)
        function [cthis] = copyElement(this)
            cthis = copyElement@matlab.mixin.Copyable(this);
        end
    end
    
    methods (Static)
         function [obj] = proj(oin)
            obj = oid(oin.type,oin.uuid);
         end
         
         function [newObject] = fromStruct(object)
            
            %%%%%%%%%%%%%%%%
            % build the constructor with no inputs
            constructor = str2func(['@()' object.type]);
            % run the constructor to get the new object
            newObject = constructor();
            claz = metaclass(newObject);
            %%%%%%%%%%%%%%%%
            %flds = fields(object);
            % when we use the newObject to generate the list of properties
            % then it could be that the ref field of a ptr does not have
            % them instead using the fields in the object and pushing to
            % the new object is better..but wait, when the refs field is 
            % the field to be converted, we do not want the whole object
            % but only a projectedID version
            props = properties(newObject);
            
            
            
            if isa(newObject,'dptr')
                % handle the refs
                % changed to more "fully" transform the struct to oid
                %newObject.refs = object.refs;
                newObject.refs = oid(object.refs.type,object.refs.uuid);
                % remove the refs property from the props list
                props = setdiff(props,'refs');
            end
            
           
            % loop over the props
            for p = 1:numel(props)
                k = find(strcmp({claz.PropertyList.Name},props{p}));
                if ~(claz.PropertyList(k).Constant)
                    % if the property is a struct then render it to an object
                    % UNLESS the object isa dptr (pointer) and the prop/field
                    % is refs
                    if isa(object.(props{p}),'struct')
                        % preallocate
                        array(numel(object.(props{p}))) = oid;
                        for e = 1:numel(object.(props{p}))
                            array(e) = oid.fromStruct(object.(props{p})(e));
                        end
                        newObject.(props{p}) = array;
                    else
                        try
                            newObject.(props{p}) = object.(props{p});
                        catch ME
                            ME;
                        end
                    end
                end
            end
         end
         
         function [newObject] = fromJSON(json)
            object = jsondecode(json);
            newObject = oid.fromStruct(object);
         end
    end
    
end
    