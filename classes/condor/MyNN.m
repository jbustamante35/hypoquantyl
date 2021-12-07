classdef MyNN < handle

    properties
        script
        fnc
    end

    methods
        function obj = MyNN(nn, script)
            %%
            if nargin < 2
                %                 script = ['m' , strrep(char(java.util.UUID.randomUUID), '-', '')];
                script = sprintf('m%s', ...
                    strrep(char(java.util.UUID.randomUUID), '-', ''));
            end

            obj.script = script;
            obj.Compile(nn);
            obj.fnc = str2func(['@(varargin)' obj.script '(varargin{:})']);

            %             fprintf('\nCurrent Directory: %s\n', pwd);
            %             fprintf('DirectoryContents:\n%s\n', ls(pwd));

        end

        function Compile(obj, nn)
            %%
            %             cmpdir = 'compiled';
            %             if isfolder(cmpdir)
            %                 mkdir(cmpdir);
            %             end
            % Compile in separate directory
            %             s = sprintf('%s/%s', cmpdir, obj.script);
            %             genFunction(nn, s, 'ShowLinks', 'no');
            %             cstr = sprintf('mcc -m -v -R -singleCompThread -a %s.m -d %s', ...
            %                 s, cmpdir);

            % Compile in current directory
            genFunction(nn, obj.script, 'ShowLinks', 'no');
            %             cstr = sprintf('mcc -m -v -R -singleCompThread -a %s.m -d %s', ...
            %                 obj.script, cmpdir);

            %             eval(cstr);

        end

        function out = predict(obj, varargin)
            %%
            out = obj.fnc(varargin{:});
        end

        function varargout = subsref(obj, s)
            %%
            switch s.type
                case '()'
                    [varargout{1:nargout}] = obj.predict(s.subs{:});
                case '{}'
                    [varargout{1:nargout}] = builtin('subsref', obj, s);
                case '.'
                    [varargout{1:nargout}] = builtin('subsref', obj, s);
            end
        end
    end

    methods (Static)
        %%
        function out = fromStruct(in)
            %%
            flds = fieldnames(in);
            for f = 1 : numel(flds)
                fld       = flds{f};
                out.(fld) = MyNN(in.(fld), fld);
            end
        end
    end
end