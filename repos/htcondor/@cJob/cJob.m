classdef cJob < oid & handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % this is a list of constants that are needed to generate the
    % condor scripts
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Access = private) % for shell file
        
        
        
       %%%% header lines for shell script
       % lines for mainX.sh
       mainline0 = '#!/bin/sh';
       mainline01 = 'uname -m';
       
       
       blankStar = 'echo ''*********************************************''';
       mainline020 = 'echo ''<PATH>''';
       mainline02 = 'echo $PATH';
       
       mainline030 = 'echo ''<PWD>''';
       mainline03 = 'echo $PWD';
       
       mainline041 = 'export HOME=$PWD';
       mainline042 = 'echo ''<HOME>''';
       mainline043 = 'echo $HOME';
       
       
       
       mainline001 = 'export IRODS_ENVIRONMENT_FILE=$PWD/irods_environment.json';
       mainline002 = 'export ENVIRONMENT_VAR_HOME=$PWD';
       mainline003 = 'export IRODS_AUTHENTICATION_FILE=$PWD/pwfile';
 
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       %%%% unzip the MCR, export os-vars and make mcr cache root
       % unzip the mcr
       %mainline1 = 'unzip -q v#MCRARG_VERSION#.zip';
       mainline1 = 'tar -xf v#MCRARG_VERSION#.tar.gz';
       % set the mrc cache root to location which we can write to
       mainline2 = 'export MCR_CACHE_ROOT=$PWD/mcr_cache';
       mainline21 = 'mkdir -p $MCR_CACHE_ROOT';
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       %%%% Added by Joe Gage to ensure proper libraries for MCR are
       % downloaded
       mainline211 = 'curl -H "Pragma:" --speed-limit 1024 --speed-time 30 --retry 3 --retry-delay 6 -o SLIBS.tar.gz http://proxy.chtc.wisc.edu/SQUID/SLIBS.tar.gz';
       %mainline212 = 'tar -xvf SLIBS.tar.gz -C ./MATLAB_Compiler_Runtime/v#MCRARG_VERSION#/runtime/glnxa64 --strip-components=1';
       mainline212 = 'tar -xf SLIBS.tar.gz';
       mainline213 = 'LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/SS/';
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       %%%% jar files for QR code reading
       mainline221 = 'curl -H "Pragma:" --speed-limit 1024 --speed-time 30 --retry 3 --retry-delay 6 -o core-3.2.1.jar http://proxy.chtc.wisc.edu/SQUID/ndmiller/core-3.2.1.jar';
       mainline222 = 'curl -H "Pragma:" --speed-limit 1024 --speed-time 30 --retry 3 --retry-delay 6 -o javase-3.2.1.jar http://proxy.chtc.wisc.edu/SQUID/ndmiller/javase-3.2.1.jar';
       
       % sqlline - was over writing the jar file - thanks to Jason Patten -
       % fixed on April, 28 2020
       mainline223 = 'curl -H "Pragma:" --speed-limit 1024 --speed-time 30 --retry 3 --retry-delay 6 -o mksqlite.mexa64 http://proxy.chtc.wisc.edu/SQUID/ndmiller/mksqlite.mexa64';
       

       
       
       %%%% unset the display
       % unset the display - not sure if i need this
       mainline3 = 'unset DISPLAY';
       %{
       %%%% for icommands - old version
       % untar the icommands if i want them
       mainline4 = 'tar xvfj icommands.x86_64.tar.bz2 -C $PWD';
       % add the icommands to the path
       mainline5 = 'export PATH=$PATH:$PWD/icommands/';
       % add the environment var for icommands
       mainline6 = 'export irodsEnvFile=$PWD/.irodsEnv';
       % add the environment var for icommands
       mainline9 = 'export irodsAuthFileName=$PWD/.irodsA';
       %}
       
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       %%%%% for icommands new version - init in shell script
       %mainline4 = 'curl -H "Pragma:" --retry 30 --retry-delay 6 -o SLIBS.tar.gz http://proxy.chtc.wisc.edu/SQUID/ndmiller/irods-icommands-4.1.9-centos-6.installer';
       mainline311 = 'curl -H "Pragma:" --speed-limit 1024 --speed-time 30 --retry 3 --retry-delay 6 -o dcraw http://proxy.chtc.wisc.edu/SQUID/ndmiller/dcraw';
       mainline312 = 'chmod +x dcraw';
       
       
       mainline4 = 'chmod +x irods-icommands-4.1.9-centos-6.installer';
       mainline5 = 'sh irods-icommands-4.1.9-centos-6.installer $PWD/';
       mainline6 = 'export IRODS_PLUGINS_HOME=$PWD/icommands/plugins/';
       % add the pwd to the path for other commands like dcraw
       mainlineN0 = 'export PATH=$PATH:$PWD/';       
       mainline9 = 'export PATH=$PATH:$PWD/icommands/';
       mainline88 = 'export IRODS_ENVIRONMENT_FILE=$PWD/irods_environment.json';
       mainlineIINIT = 'echo -e "#auth#" | iinit';
       
       
       
       %mainlineDB1 = 'imeta mod -d #dataObject# #key# #value# #nvalue#';
       mainlineDCR1 = 'curl -H "Pragma:" --speed-limit 1024 --speed-time 30 --retry 3 --retry-delay 6 -o lcms_lib.tar.gz http://proxy.chtc.wisc.edu/SQUID/ndmiller/lcms_lib.tar.gz';
       mainlineDCR2 = 'tar xvf lcms_lib.tar.gz';
       mainlineDCR3 = 'LD_LIBRARY_PATH=$PWD/lcms/lib/:$LD_LIBRARY_PATH';
       mainlineDCR4 = 'echo $LD_LIBRARY_PATH';
       mainlineDCR5 = 'cp ./lcms/lib/* ./MATLAB_Compiler_Runtime/v#MCRARG_VERSION#/sys/os/glnxa64/';
       % add the command to run and point to MCR
       mainline7 = './run_#function#.sh "MATLAB_Compiler_Runtime/v#MCRARG_VERSION#/"';
       
       
       
       % tar the results
       %mainline8 = 'tar zcvf #outputTAR#.tar output';
       mainline8 = 'tar cvf #outputTAR#.tar output';
       mainline10 = 'tar cvf #outputTAR#.tar #mappingSource#';
       % remove the squid and pack-in files
       mainline11 = 'rm #rmfile#';
       % squid location
       %squidURL = 'http://proxy.chtc.wisc.edu/SQUID/ndmiller/myJobData/';  
       squidURL = 'http://proxy.chtc.wisc.edu/SQUID/ndmiller/jobFiles/';  
       
       
       
       % flock command
       flockCommand = '+WantFlocking = true';
       % osg command
       osgCommand = '+WantGlideIn = true';
       
       % input delimter
       delimiter = '**';
       
       
       % default remote save location
       outLocation = './output';
       
       % 
       MCR_version = 'v717';
       
       % 
       algoName = '';
       algoVersion = '';
       
       
    end
    
    properties (Access = private)% for submitfile
        % re universe
        universe = 'vanilla';
        
        % re transfer
        should_transfer_files = 'YES';
        when_to_transfer_output = 'ON_EXIT';        
    end
    
    
    properties (Constant)
        deployed_ouput_vars_location = 'inMemVarsOut';
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % this is a list of varaibles that need to be "filled out"
    % to generate the condor submit files
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        
        
        stageCommand = '';
        
        % requirements needed for condor matching to machine
        requirements;
        % unique time stamp needed for creating mat file
        uniqueTimeRandStamp;
        %
        jobFunction;
        jobNargin;
        jobNargout;
        jobArguments;
        xferFileList;
        xferFileList_squid;
        toFlock = 1;
        toOsg = 1;
        
        tmpFileLocation = '/mnt/spaldingdata/nate/inMemCondor/';
        matFileName;
        fullMatLocation;
        outMatFileLocation;
        
        % key/value pairs
        kvp;


        isGPU = 0;
    end
    
    methods
    
        % constructor
        function [obj] = cJob(varargin)
            % generate a unique key for handling the mat file
            obj.uniqueTimeRandStamp = strrep([num2str(now) num2str(rand(1,1))],'.','');
            obj.matFileName = [obj.uniqueTimeRandStamp '.mat'];
            obj.initDefaultRequirements();
            obj.initDefaultTransferList();
            if nargin == 2
                obj.algoName = varargin{1};
                obj.algoVersion = varargin{2};
            end
            obj.kvp = containers.Map();
            
        end
        
        % set the to flock variable 
        function [] = setFlock(obj,value)
            obj.toFlock = value;
        end
        
        function [] = tag(this,key,value)
            this.kvp(key) = value;
        end

        function [] = bulkTag(this,kvp)
            this.kvp = kvp;
        end


        % set the OSG variable
        function [] = setOSG(obj,value)
            obj.toOsg = value;
        end
        
        function [] = initDefaultRequirements(obj)
%             obj.requirements.('disk') = {'=' '16000000'};
            % obj.requirements.('memory') = {'=' '8000'};
            obj.requirements.('disk') = {'=' '20000000'};
            obj.requirements.('memory') = {'=' '12000'};
            obj.requirements.('cpus') = {'=' '1'};
        end
        
        function [] = setTempFilesLocation(obj,tmpFileLocation)
            obj.tmpFileLocation = tmpFileLocation;
        end
        
        function [] = setMemoryUse(obj,mem)
            if ~ischar(mem)
                mem = num2str(mem);
            end
            obj.requirements.('memory') = {'=' mem};
        end
        
        function [] = initDefaultTransferList(obj)
            % attach any default files
            % listed below are the mcr and icommands attached via the squid
            % server
            obj.addSquidFile('v840.tar.gz');
            obj.addSquidFile('icommands.x86_64.tar.bz2');
            obj.addSquidFile('irods-icommands-4.1.9-centos-6.installer');
            obj.addSquidFile('phytoMorphTK_config.json');
            
            
            %obj.addFile('https://s3dev.chtc.wisc.edu/chtc/resources/mc');
            %obj.addFile('https://s3dev.chtc.wisc.edu/chtc/resources/configure.json');
            obj.addFile('/mnt/spaldingdata/nate/resources/mc');
            obj.addFile('/mnt/spaldingdata/nate/resources/config.json');
            %obj.addSquidFile('dcraw');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % change the MCR from the default version
        % note that the MCR must be on the squid server
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = changeMCRfile(obj,mcrFileName)
            obj.xferFileList_squid{1} =  [mcrFileName '.tar.gz'];
            obj.MCR_version = mcrFileName;
            %{
            [p,n,ex] = fileparts(obj.xferFileList{1});
            obj.xferFileList{1} = [p mcrFileName];
        %}
        end
        
        
        function [] = setFunctionName(obj,functionName)
            obj.jobFunction = functionName;
            obj.addFile(obj.jobFunction);
            obj.addFile(['run_' obj.jobFunction '.sh']);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % call if the vars are loaded from memory
        % therefore the mat file will be generated
        % and the function will be called
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = setAsMemoryJob(obj,uniqueDAGKey,func)
            % set the job function
            obj.setFunctionName(func);
            % construct the eval location
            uniqueEvalDirectory = cFlow.generateUniqueCompileLocation(func,uniqueDAGKey);
            % construct the full location for the mat file
            matFileLocation = obj.generateVariableFileLocation(uniqueEvalDirectory);
            % construct output file
            out_matFileLocation = strrep(matFileLocation,'functionInputs','functionOutputs');
            % set output file location
            obj.outMatFileLocation = out_matFileLocation;
            % add the input file
            obj.addFile(matFileLocation);
            % set in memory mat file location
            obj.fullMatLocation = matFileLocation;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % argument implementations
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [] = setNumberofArgs(obj,jobNargin)
            obj.jobNargin = jobNargin;
        end
        
        function [] = setNumberofOArgs(obj,jobNargout)
            obj.jobNargout = jobNargout;
        end
        
        function [] = setArgument(obj,argument,number)
            obj.jobArguments{number} = argument;
        end
        
        function [arg] = getArgument(obj,number)
            arg = obj.jobArguments{number};
        end
        
        function [inputString] = setArg(obj,argument,number)
            matLoc = obj.fullMatLocation;
            inputString = generateInput(argument,number,matLoc);
            obj.jobArguments{number} = inputString;
        end
        
        function [arg] = getArg(obj,number)
            arg = obj.jobArguments{number};
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % generate the mat file which will contain the input variables
        % actions:  make the directory for the dag
        %           make the functionInputs directory
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [matLoc] = generateVariableFileLocation(obj,launchDirectory)
            inputsDirectory = [launchDirectory 'functionInputs' filesep];
            CMD = ['mkdir -p ' inputsDirectory];
            system(CMD);
            matLoc =  [inputsDirectory obj.matFileName];
        end
        
        % call function to execute the cJob
        function [] = localExecute(obj)
            varargout = {};
            matFile = obj.fullMatLocation();
            
            % if is deplayed then matFile output becomes the file name only
            if isdeployed
                [~,matFile] = fileparts(matFile); 
            end
            func = str2func(obj.jobFunction);
            inputString = '(';
            % load argments from cJob on disk and make anonymous func-call
            for input = 1:obj.jobNargin
                tmp = obj.jobArguments{input};
                fprintf(['starting load argName:' tmp ':' matFile '\n']);
                load(matFile,tmp);
                fprintf(['ending load argName:' tmp ':' matFile '\n']);
                inputString = [inputString tmp ','];
            end
            inputString(end) = ')';
            CMD = ['[OUT{1:obj.jobNargout}] = ' obj.jobFunction inputString ';'];
            eval(CMD);
            
            
            if isdeployed
                varsLoc = ['.' filesep cJob.deployed_ouput_vars_location filesep];
                mkdir(varsLoc);
                matFile = [varsLoc matFile '.mat'];
                fprintf(['Saving output(s) from function to disk.\n']);
                for e = 1:numel(OUT)
                    varName = ['out' num2str(e)];
                    CMD = [varName '= OUT{e};'];
                    eval(CMD);
                    if exist(matFile)
                        save(matFile,varName,'-v7.3','-append');
                    else
                        save(matFile,varName,'-v7.3');
                    end
                end
            else
                for e = 1:numel(OUT)
                    varName = ['out' num2str(e)];
                    CMD = [varName '= OUT{e};'];
                    eval(CMD);
                    if exist(obj.outMatFileLocation)
                        save(obj.outMatFileLocation,varName,'-v7.3','-append');
                    else
                        save(obj.outMatFileLocation,varName,'-v7.3');
                    end
                    varargout{e} = [obj.outMatFileLocation '@' varName];
                end
            end
            fprintf(['Exiting from cJob /n']);
            close all
        end
        
        function [] = addFile(obj,file)
            obj.xferFileList{end+1} = file;
        end
        
        function [] = addSquidFile(obj,file)
            obj.xferFileList_squid{end+1} = file;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % generate functions
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % generate submit file to call shell command
        function [] = generate_submitFile(obj, oFilePath, asVar, numberOfDirectoryMappings)
            if nargin < 4; numberOfDirectoryMappings = 1; end
            fileID = fopen([oFilePath , obj.generate_submitName] , 'w');
            
            % setup for universe
            fprintf(fileID,'%s\n',['universe = ' , obj.universe]);
            
            % setup for executable
            fprintf(fileID,'%s\n',['executable = ' , obj.generate_exeName]);
            
            % setup for transferfiles
            fprintf(fileID,'%s\n',['should_transfer_files = ' , obj.should_transfer_files]);
            fprintf(fileID,'%s\n',['when_to_transfer_output = ' , obj.when_to_transfer_output]);
            
            % setup for xfer files
            obj.renderFileTransferList(fileID,asVar);
            
            
            if obj.isGPU > 0
                fprintf(fileID,'%s\n',['request_gpus = ' , num2str(obj.isGPU)]);
                %fprintf(fileID,'%s\n',['requirements = (CUDARuntimeVersion > 3.0)']);
            end            
            
            % setup for requirements
            obj.renderRequirements(fileID);
            
            % Force using CentOS 7 [most nodes run CentOS 8]
            fprintf(fileID, '%s\n', 'requirements = (OpSysMajorVer == 7)');

            % setup for arguments
            obj.renderArguments(fileID,asVar,numberOfDirectoryMappings);
            
            % setup for logging
            obj.renderLogFiles(fileID);
          
            % setup for spalding nodes
            fprintf(fileID,'%s\n','+AccountingGroup = "spalding"');
            fprintf(fileID,'%s\n','priority = 9');
            fprintf(fileID,'%s\n','+Group = "spalding"');
            
            keys = obj.kvp.keys;
            for e = 1:numel(keys)
                %str = ['+' keys{e} ' = "' char(obj.kvp(keys{e})) '"'];
                str = ['+' keys{e} ' = "$(' keys{e} ')"'];
                fprintf(fileID,'%s\n',str);
            end

            % render flock and osg commands if needed
            obj.renderFlockandOsg(fileID);
            
            % setup for queue
            fprintf(fileID,'%s\n','queue');
            
            % close file
            fclose(fileID);
        end

        % generate shell command for compiled code
        function [] = generate_shellCommand(obj,MCR_VER,icommands_auth,oFilePath,directoryMappings)
            fileID = fopen([oFilePath obj.generate_exeName],'w');
            
            % setup for shell script            
            fprintf(fileID,'%s\n',obj.mainline0);
            
            % setup reporting out information on machine which is computing           
            fprintf(fileID,'%s\n','echo "nodeArchType:"');
            fprintf(fileID,'%s\n',obj.mainline01);
            
            fprintf(fileID,'%s\n',obj.blankStar);
            fprintf(fileID,'%s\n',obj.mainline020);
            fprintf(fileID,'%s\n',obj.mainline02);
            fprintf(fileID,'%s\n',obj.blankStar);
            
            fprintf(fileID,'%s\n',obj.blankStar);
            fprintf(fileID,'%s\n',obj.mainline030);
            fprintf(fileID,'%s\n',obj.mainline03);
            fprintf(fileID,'%s\n',obj.blankStar);
            
            fprintf(fileID,'%s\n',obj.blankStar);
            fprintf(fileID,'%s\n',obj.mainline041);
            fprintf(fileID,'%s\n',obj.mainline042);
            fprintf(fileID,'%s\n',obj.mainline043);
            fprintf(fileID,'%s\n',obj.blankStar);
            
            
            fprintf(fileID,'%s\n','echo "nodeIP:"');
            fprintf(fileID,'%s\n','dig +short myip.opendns.com @resolver1.opendns.com');        
            fprintf(fileID,'%s\n','echo "OS:"');
            fprintf(fileID,'%s\n','cat /etc/lsb-release');
            
            % render squid files
            % take out my own curl commands - October 12, 2017 - office hrs
            %obj.renderSquidXfer(fileID);
            
            % setup for MCR
            fprintf(fileID,'%s\n',strrep(obj.mainline1,'#MCRARG_VERSION#',MCR_VER));
            fprintf(fileID,'%s\n',obj.mainline2);
            fprintf(fileID,'%s\n',obj.mainline21);
            fprintf(fileID,'%s\n',obj.mainline211);
            %fprintf(fileID,'%s\n',strrep(obj.mainline212,'#MCRARG_VERSION#',MCR_VER));
            fprintf(fileID,'%s\n',obj.mainline212);
            fprintf(fileID,'%s\n',obj.mainline213);
            
            fprintf(fileID,'%s\n',obj.mainline221);
            fprintf(fileID,'%s\n',obj.mainline222);
            fprintf(fileID,'%s\n',obj.mainline223);
            
            fprintf(fileID,'%s\n',obj.mainline3);
            fprintf(fileID,'%s\n',obj.mainline311);
            fprintf(fileID,'%s\n',obj.mainline312);
            
            
            fprintf(fileID,'%s\n',obj.mainlineDCR1);
            fprintf(fileID,'%s\n',obj.mainlineDCR2);
            fprintf(fileID,'%s\n',obj.mainlineDCR3);
            fprintf(fileID,'%s\n',obj.mainlineDCR4);
            fprintf(fileID,'%s\n',strrep(obj.mainlineDCR5,'#MCRARG_VERSION#',MCR_VER));
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % if icommands flag is set then perform setup for icommands
            %if icommands
                fprintf(fileID,'%s\n',obj.mainline4);
                fprintf(fileID,'%s\n',obj.mainline5);
                fprintf(fileID,'%s\n',obj.mainlineN0);
                fprintf(fileID,'%s\n',obj.mainline6);
                fprintf(fileID,'%s\n',obj.mainline9);
                fprintf(fileID,'%s\n',obj.mainline88);
            %end
            fprintf(fileID,'%s\n',obj.mainline001);
            fprintf(fileID,'%s\n',obj.mainline002);
            fprintf(fileID,'%s\n',obj.mainline003);
            fprintf(fileID,'%s\n',strrep(obj.mainlineIINIT,'#auth#',icommands_auth));
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % first reporting stage
            if ~isempty(obj.algoName)
                fprintf(fileID,'%s\n','NOW=$(date +%s)');
                fprintf(fileID,'%s\n','TZ='':America/Chicago''');
                CMD = uncLog(['ph:l:'],{'$2'},'set',obj.algoName,obj.algoVersion,{'1'},{'1:$NOW'},0);
                fprintf(fileID,'%s\n',CMD{1});
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % setup for main function call
            mainCMD = strrep(obj.mainline7,'#function#',obj.jobFunction);
            mainCMD = strrep(mainCMD,'#MCRARG_VERSION#',MCR_VER);
            
            if ~isempty(obj.algoVersion)
                lessToMatlab = 1;
            else
                lessToMatlab = 0;
            end
            
            
            
            for i = 1:(obj.jobNargin-lessToMatlab)
                %argVAL = ['"${' num2str(i) '}"'];
                %argVAL = ['"""${' num2str(i) '}"""'];
                argVAL = ['${' num2str(i) '}'];
                mainCMD = [mainCMD ' ' argVAL];
            end    
            fprintf(fileID,'%s\n','echo STARTMAIN');
            fprintf(fileID,'%s\n',mainCMD);
            fprintf(fileID,'%s\n','echo ENDMAIN');
            
            
            
            if nargin ~= 5
                % setup for tar output            
                fprintf(fileID,'%s\n',strrep(obj.mainline8,'#outputTAR#',['${' num2str(obj.jobNargin+1) '}']));
            else
                % multiple non-default directory mappings
                for e = 1:numel(directoryMappings)
                    % search for the source string
                    fidx = strfind(directoryMappings{e},'>');
                    % extract the source string
                    source = directoryMappings{e}(1:fidx(1)-1);
                    
                    tarMappingString = strrep(obj.mainline10,'#outputTAR#',['${' num2str(obj.jobNargin+1+(e)) '}']);
                    tarMappingString = strrep(tarMappingString,'#mappingSource#',source);
                    fprintf(fileID,'%s\n',tarMappingString);
                end
            end
            
            
            
            
            % add remove file for squid file list
            for e = 1:numel(obj.xferFileList_squid)
                [p,n,ext] = fileparts(obj.xferFileList_squid{e});
                fprintf(fileID,'%s\n',strrep(obj.mainline11,'#rmfile#',[n ext]));
            end
            
            
            % add remove file for local transfer file list
            for e = 1:numel(obj.xferFileList)
                [p,n,ext] = fileparts(obj.xferFileList{e});
                fprintf(fileID,'%s\n',strrep(obj.mainline11,'#rmfile#',[n ext]));
            end
            
            
            % remove the .irods directory and other files
            fprintf(fileID,'%s\n',strrep(obj.mainline11,'#rmfile#','.irodsA'));
            fprintf(fileID,'%s\n',strrep(obj.mainline11,'#rmfile#','.irodsEnv'));
            fprintf(fileID,'%s\n',strrep(obj.mainline11,'#rmfile#','-r output'));
            fprintf(fileID,'%s\n',strrep(obj.mainline11,'#rmfile#','SLIBS.tar.gz'));
            
            
            if ~isempty(obj.algoName)
                fprintf(fileID,'%s\n','NOW=$(date +%s)');
                fprintf(fileID,'%s\n','TZ='':America/Chicago''');
                CMD = uncLog(['ph:l:'],{'$2'},'set',obj.algoName,obj.algoVersion,{'7'},{'1:$NOW'},0);
                fprintf(fileID,'%s\n',CMD{1});
            end
            
            
            % close File
            fclose(fileID);
        end
        % generate submit package
        function [] = generate_submitFilesForDag(obj,icommands_auth,directoryMappings,oFilePath)
            if nargin <= 3
                oFilePath = obj.tmpFileLocation;
            end
            if nargin == 2
                obj.generate_submitFile(oFilePath,1);
                obj.generate_shellCommand(obj.MCR_version(2:end),icommands_auth,oFilePath);
            else
                obj.generate_submitFile(oFilePath,1,numel(directoryMappings));
                obj.generate_shellCommand(obj.MCR_version(2:end),icommands_auth,oFilePath,directoryMappings);
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % helper functions
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % generate exe name
        function [exeName] = generate_exeName(obj)
            exeName = ['main_' obj.jobFunction '.sh'];
        end
        % gererate submit name
        function [submitName] = generate_submitName(obj)
            submitName = [obj.jobFunction '.submit'];
        end
        % generate file list
        function [xferList] = getTransferFileList(obj)
            xferList = '';
            for e = 1:numel(obj.xferFileList)
                tmp = [obj.xferFileList{e} ','];
                xferList = [xferList tmp];
            end
            
            % added squid to this list October 12, 2017
            squidList = renderSQUIDfiles(obj);
            for e = 1:numel(squidList)
                tmp = [squidList{e} ','];
                xferList = [xferList tmp];
            end
            xferList(end) = [];
        end
    end
    
    methods (Access = private)
        
        function [] = renderRequirements(obj,fileID)
            % old style
            %{
            req = 'requirements = ';
            flds = fieldnames(obj.requirements);
            for e = 1:numel(flds)
                tmp = ['(' flds{e} obj.requirements.(flds{e}){1} obj.requirements.(flds{e}){2} ') && '];
                req = [req tmp];
            end
            req(end-2:end) = [];
            fprintf(fileID,'%s\n',req);
            %}
            
            % new style
            flds = fieldnames(obj.requirements);
            for e = 1:numel(flds)
                tmp = ['request_' flds{e} obj.requirements.(flds{e}){1} obj.requirements.(flds{e}){2}];
                fprintf(fileID,'%s\n',tmp);
            end
            
            
            
        end

        function [] = renderArguments(obj,fileID,asVar,extraArgs)
            if nargin == 3
                extraArgs = 1;
            end
            arg = 'arguments = "';
            for e = 1:(obj.jobNargin+extraArgs+1)
                if asVar
                    tmp = ['$(argNumber' num2str(e) ')'];                    
                else
                    tmp = [obj.jobArguments{e}];
                end
                %arg = [arg '''' tmp '''' ' '];
                %arg = [arg '''""' tmp '""''' ' '];
                arg = [arg '''' tmp '''' ' '];
                %arg = [arg tmp ' '];
            end
            arg(end) = [];
            arg = [arg '"'];
            fprintf(fileID,'%s\n',arg);
        end
        
        
        % render the list of files for condor to transfer in
        % added SQUID list on October 12, 2017
        function [] = renderFileTransferList(obj,fileID,asVar)
            xferList = 'transfer_input_files = ';
            fileList = obj.getTransferFileList();
            if asVar
                fileList = '$(FileTransferList)';
            end
            xferList = [xferList fileList];
            
           
            
            
            fprintf(fileID,'%s\n',xferList);
        end        
        
        function [] = renderLogFiles(obj,fileID)
            outLOG = ['output = logs/stdout/maizeEar.output$(argNumber' num2str(obj.jobNargin+1) ')'];
            fprintf(fileID,'%s\n',outLOG);
            outERR = ['error = logs/stderr/maizeEar.output$(argNumber' num2str(obj.jobNargin+1) ')'];
            fprintf(fileID,'%s\n',outERR);
        end
        
        function [] = renderSquidXfer(obj,fileID)
            baseLine = 'curl -H "Pragma:" --retry 30 --retry-delay 6 -o ';
            for e = 1:numel(obj.xferFileList_squid)
                curlLine = [baseLine obj.xferFileList_squid{e} ' ' obj.squidURL obj.xferFileList_squid{e}];
                fprintf(fileID,'%s\n',curlLine);
            end
        end
        
        
        % added October 12, 2017
        function [SQUIDfileList] = renderSQUIDfiles(obj)
             for e = 1:numel(obj.xferFileList_squid)
                SQUIDfileList{e} =  [obj.squidURL obj.xferFileList_squid{e}];
            end
        end
        
        
        function [] = renderFlockandOsg(obj,fileID)
            if obj.toFlock
                fprintf(fileID,'%s\n',obj.flockCommand);
            end
            if obj.toOsg
                fprintf(fileID,'%s\n',obj.osgCommand);
            end
        end
    end
    
    methods (Static)
        
        function [func] = getFunctionWrapper(func)
            cJob.compileFunction(func);
            func = @(varargin)cJob.callFunction(func,varargin(:));
        end
        
        function [varargout] = callFunction(func,varargin)
            tmpJob = cJob();
            tmpJob.setAsMemoryJob();
            job.setTempFilesLocation(tmpFileLocation);
            job.setFunctionName(func);    
            for e = 1:numel(varargin)
                tmpJob.setArg(varargin{e},e);
            end
            
        end
    end
end

%{
    func = cJob.getFunctionWrapper('testCondorFunction');
%}