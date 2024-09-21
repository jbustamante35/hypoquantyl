function [inputString] = generateInput(value,argNumber,matFile)
    warning off
    % generate the string required to flag the function that it needs to
    % load the variable from the attached mat file
    varName = ['arg' num2str(argNumber)];    
    %inputString = [delimiter class(value) delimiter 'matfile:' matFile ',' varName delimiter];  
    inputString = varName;  
    CMD = [varName '=' 'value;'];
    eval(CMD);
    if ~exist(matFile)
        save(matFile,varName,'-v7.3');
    else
        save(matFile,varName,'-v7.3','-append');
    end  
end
