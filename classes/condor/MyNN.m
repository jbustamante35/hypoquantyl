classdef MyNN < handle

    properties
        script
        fnc
    end

    methods
        function obj = MyNN(nn, script)
            %%
            if nargin < 2
                script = sprintf('m%s', ...
                    strrep(char(java.util.UUID.randomUUID), '-', ''));
            end

            obj.script = script;
            obj.Compile(nn);
            obj.fnc = str2func(['@(varargin)' obj.script '(varargin{:})']);
        end

        function Compile(obj, nn)
            %%
            % Compile in current directory
            genFunction(nn, obj.script, 'ShowLinks', 'no');
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