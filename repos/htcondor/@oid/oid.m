classdef (Description='{#:*,ez-json:configurable}') oid < matlab.mixin.Heterogeneous & matlab.mixin.Copyable & matlab.mixin.SetGet & dynamicprops & hasReporting
    
    
    properties (Description='{#:*,ez-sql:traitTable,ez-sql:pipeLine,ez-json:configurable}')
        
        uuid char;
        
        type char;
        
    end
    
    properties
        
        % not sure where the cuuid should be
        % if I leave it as configurable then
        % the .mat version will be overwritten when loaded and configured
        cuuid = '#CODEID#';
        
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [obj] = oid(type,uuid)
            if nargin == 0;type = class(obj);end
            %if nargin <= 1;[~,uuid] = system('uuidgen');end
            if nargin <= 1;uuid = char(java.util.UUID.randomUUID);end
            obj.uuid = strtrim(uuid);
            obj.type = type;
        end
        
        function [] = updateType(this)
            this.type = class(this);
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
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [returnTable] = toTable(this,variableFilter)
            if nargin < 2;variableFilter = {'*'};end
            
            % assuming homogenous list of types
            classModel = meta.class.fromName(class(this));
            
            % number of properties to extract
            M = numel(variableFilter);
            
            % assign filter to all if *
            if strcmp(variableFilter,'*')
                M = numel(classModel.PropertyList);
                variableFilter = {classModel.PropertyList.Name};
            end
            
            % number of objects in list
            N = numel(this);
            
            % preallocate the data
            VariableName = cell(1,M);
            VariableType = cell(1,M);
             
             % data cell array
            VariableValue = cell(1,M);
           
            % if oid
            isOID = ones(1,M);
            
            % filter
            propertiesToExtract = intersect({classModel.PropertyList.Name},variableFilter);
            % LOOK HERE FOR SPEED UP FILTER LIST FIRST?
            
            
            % assign names
            VariableName = propertiesToExtract;
            
            % if juice to squeeze then do it
            if ~isempty(this)

                % for each column/variable
                for e = 1:numel(propertiesToExtract)

                    % name
                    tmpName = propertiesToExtract{e};

                    % get the data
                    VariableValue{e} = this.get(tmpName);

                    % class of datasd
                    VariableType{e} = class(this(1).get(tmpName));
                    
                    % if oid
                    isOID(e) = isa(this(1).get(tmpName),'oid');


                    try
                        % if var type is char then convert all data to strings
                        if strcmp(VariableType{e},'char')
                            VariableValue{e} = cellfun(@(x)string(x),VariableValue{e});
                            %VariableValue{cnt} = string(VariableValue{cnt});
                        end
                    catch ME
                        ME;
                    end

                    % if char then make string for table
                    VariableType{e} = strrep(VariableType{e},'char','string');

                    % force value to linking uuid for oid
                    if isOID(e)
                        tmpArray = [VariableValue{e}{:}];
                        VariableValue{e} = {tmpArray.uuid};
                        VariableType{e} = 'string';
                    end

                    % handle empty
                    for loop = 1:numel(VariableValue{e})
                        if isempty(VariableValue{e}{loop})
                            if strcmp(VariableType{e},'string')
                                VariableValue{e}{loop} = '';
                            elseif strcmp(VariableType{e},'char')
                                VariableValue{e}{loop} = '';
                            elseif strcmp(VariableType{e},'cell')
                                VariableValue{e}{loop} = jsonenode_pm(VariableValue{e}{loop});
                                VariableType{e} = 'string';
                            else
                                VariableValue{e}{loop} = nan;
                            end
                        end
                    end

                    %{
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    % NOT SURE WHAT THI DOES
                    if isa(VariableValue{e},'char')
                        if ndims(VariableValue{cnt}) > 1 && (size(VariableValue{cnt},1) > 1)
                            VariableValue{cnt} = jsonenode_pm(VariableValue{cnt});
                            VariableType{cnt} = 'string';
                        end
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    %}


                    %{
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    % yuck function handles
                    if isa(VariableValue{cnt},'function_handle')
                        VariableValue{cnt} = 'function_handle';
                        VariableType{cnt} = 'string';
                    end
                    %}


                end


            end
            
            
            for e = 1:numel(VariableValue)
                if size(VariableValue{e},2) > size(VariableValue{e},1)
                    VariableValue{e} = VariableValue{e}';
                end
                if strcmp(VariableType{e},'double')
                    VariableValue{e} = cell2mat(VariableValue{e});
                end
            end
            
            returnTable = table(VariableValue{:},'VariableNames',VariableName);



        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [oidObjects] = oidLinks(this)
            try
                oidObjects = [];
                oidObjects = {};
                classModel = meta.class.fromName(class(this));

                if ~isempty(this)
                    for e = 1:numel(classModel.PropertyList)
                        VariableName = classModel.PropertyList(e).Name;
                        VariableValue = this(1).get(VariableName);
                        isOID = isa(VariableValue,'oid');
                        if isOID
                            data = this.get(VariableName);
                            data = [data{:}];
                            data = oid.columnVector(data);
                            %oidObjects = [oidObjects,data];
                            oidObjects{end+1} = data;
                        end
                    end
                end
            catch ME
                ME;
            end
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
                value = obj.(prop{p});
                % if the object is a oid or greater
                if isa(value,'oid')
                    % loop over the oid array and convert to ptr
                    for e = 1:numel(value)
                        if ~isa(value(e),'dptr')
                            % make a dptr to the object
                            obj.(prop{p})(e) = dptr(obj.(prop{p})(e));
                        end
                    end
                elseif isa(value,'cell')
                    here = 1;
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


        function [C] = eqUUID(A,B)
            for e = 1:numel(A)
                C(e) = strcmp(A(e).uuid,B.uuid);
            end
            here = 1;
        end
        
        
    end
    
    methods(Access = protected)
        function [cthis] = copyElement(this)
            cthis = copyElement@matlab.mixin.Copyable(this);
        end
       
    end
    
    
    methods (Static)
         
        function [uuidList,objectList] = traverse(X,uuidList,objectList)
            
            if nargin == 1;uuidList = {};end
            if nargin == 1;objectList = oid.empty(0,0);end
            
            for e = 1:numel(X)
                if isa(X,'oid')
                    % if the uuidList does not have record of a visit here
                    % then record visit and move on
                    if isempty(uuidList)
                        toCheck = true;
                    else
                        toCheck = ~contains(uuidList,X(e).uuid);
                    end
                    if toCheck
                            objectList{end+1} = X(e);
                            uuidList{end+1} = X(e).uuid;
                            % get the propties of this
                            prop = properties(X(e));
                            for p = 1:numel(prop)
                                % get the prop value
                                value = X(e).(prop{p});
                                % call traverse
                                [uuidList,objectList] = oid.traverse(value,uuidList,objectList);
                            end
                        
                    end
                elseif isa(X,'cell')
                    [uuidList,objectList] = oid.traverse(X{e},uuidList,objectList);
                else
                    
                end
            end
        end
        
        function [obj] = proj(oin)
            obj = oid(oin.type,oin.uuid);
        end
         
        function [newObject] = fromStruct(object)
            try
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
                                try
                                    array(e) = oid.fromStruct(object.(props{p})(e));
                                catch ME
                                    here = 1;
                                end
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
            catch ME
                here = 1;
            end
        end
         
        function [newObject] = fromJSON(json)
            object = jsondecode(json);
            newObject = oid.fromStruct(object);
        end


    end
    
    
    methods (Static)
        
        function [d] = generateDate()
            d = datestr(now,'YYYYmmddHHMMSS');
        end
        
        function [objects] = columnVector(objects)
            sz = size(objects);
            if sz(2) > sz(1)
                objects = objects';
            end
        end
        
        function [bool] = checkCodeBase(object)
            stor(['start:checking object against code context']);
            tmpObject = oid;
            bool = strcmp(tmpObject.cuuid,object.cuuid);
            stor(['object cuuid: ' object.cuuid]);
            stor(['tmpObject cuuid: ' tmpObject.cuuid]);
            stor(['check: ' num2str(bool)]);
            stor(['stop: checking object against code context']);
        end
        
        function [versionID] = findDeployVersion(file,codehash)
            cmd = ['mc -no-color -json tag list --versions ' ...
                   'htpheno/deploy/' file];
            
            [r,result] = system(cmd);
            result = strtrim(result);
            result = strrep(result,['}' char(10) '{'],'},{');
            result = ['[' result ']'];
            result = jsondecode(result);
            
            versionID = '';
            for e = 1:numel(result)
                if strcmp(result(e).tagset.codehash,codehash)
                    versionID = result(e).versionID;
                end
            end
            
            
        end
        
    end
    
end
    