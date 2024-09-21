function [varargout] = cFlowLoader(varargin)   
varargout = {};    
try
    
    for e = 1:numel(varargin)
        fidx = strfind(varargin{e},'@');
        loadFile = varargin{e}(1:fidx-1);
        varName = varargin{e}(fidx+1:end);
%        loadFile = strrep(loadFile,'/functionOutputs/','/functionOutputs/output/');
        if exist(loadFile)
            load(loadFile,varName);
            eval(['varargout{e} = ' varName ';']);
            fprintf(['loaded \n']);
        else
            for e = 1:nargout
                varargout{e} = [];
            end
            fprintf(['Not ready to load \n']);
        end
    end
catch ME
    ME
        for e = 1:nargout
            varargout{e} = [];
        end
        fprintf(['Error loading \n']);
    end
end