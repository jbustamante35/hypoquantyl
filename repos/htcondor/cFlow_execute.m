function [] = cFlow_execute(matFile)
    if isdeployed()
        fprintf(['******************************************\n']);
        fprintf(['start: Setting phytoMorph Tool Kit Location.\n']);
        phytoMorphTK_config = './phytoMorphTK_config.json';
        setenv('phytoMorphTK_config',phytoMorphTK_config);
        fprintf(['end: Setting phytoMorph Tool Kit Location.\n']);
        fprintf(['******************************************\n']);
    end
    
    fprintf(['job called with string:' matFile '\n'])
    if isdeployed
        [p,matFile,ext] = fileparts(matFile);
    end
    matFile = ['.' filesep matFile ext];
    matFile = strrep(matFile,'"','');
    fprintf(['Loading anonymous cJob from file:' matFile '\n']);
    load(matFile,'tmpJob');
    tmpJob.localExecute();
    stor(['END!']);
end