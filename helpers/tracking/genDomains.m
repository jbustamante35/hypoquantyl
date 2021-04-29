function [para] = genDomains(para)    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % create domains - special - 
    % does nothing but call "createDomain" iteratively
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % INPUT: 
    %           para  = 'feature parameters' = parameters that are needed for
    %               feature extraction and sampling. 
    %               NOTE: With this setting: features = corners!
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % OUTPUT: 
    %          para  = 'feature parameters' = parameters that are needed for
    %               feature extraction and sampling. 
    %               NOTE: With this setting: features = corners!
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for i = 1:numel(para)
        para{i} = createDomain(para{i});
    end
end
