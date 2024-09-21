classdef cFlow < doidmm & handle
    % model:    each job hasa submit file
    %           each dag hasa job/node
    %           each dag hasa description file (d-file)
    %           each job hasa list of files it can draw in
    %           each dag d-file has a list of var
    %           var canbe a list of xfer files

    %%%%%%%%%%%%%%%%%%%%%%%%
    % files are vectors
    % needed: a list of vectors to transfer into the job
    %           - data/vectors can be xfered via
    %                       1: condor file transfer
    %                       2: pre script
    %                       3: job-exe
    %                       4: post script
    %%%%%%%%%%%%%%%%%%%%%%%%
    %                       y <- f(x).
    % this models the execution of a function (f) on a
    % number (x) to produce a number (y).

    properties (Constant)
        stageLocation = 'htpheno/dagdata/';
    end

    properties (Access = public)
        %
        listPtr = 1;
        jobList;
        jobFunction;
        outputLocation;
        uniqueTimeRandStamp;
        dateString;
        retryValue = 3;
        maxidle    = [];
        maxjobs    = [];
        maxpost    = [];

        stagePreScriptFile  = '/home/jbustamante/Dropbox/EdgarSpalding/projects/nate_code/code_for_condor/stageData.sh';
        stagePostScriptFile = '/home/jbustamante/Dropbox/EdgarSpalding/projects/nate_code/code_for_condor/unstageData.sh';
        prescriptFile       = '/home/jbustamante/Dropbox/EdgarSpalding/projects/nate_code/code_for_condor/waitFileTrigger.sh';

        subMemFunc = '';
        tmpFilesLocation;
        submitNodeLocation;

        dirMappingsString = {};

        % post script untar line
        mainline0 = '#!/bin/sh';
        utarLine  = 'tar xvf "$#N1#" -C "$#N2#';
        rmtarLine = 'rm "$#N1#"';

        % file dependency lists
        localD = {};
        squidD = {};

        % connection to valueDatabase
        valueDatabase = [];

        % n route
        n_route_to_shell = 0;

        % MCR version
        %MCR_version = 'v717';
        %         MCR_version = 'v980';
%         MCR_version = 'v911';
        MCR_version = 'v913';

        % memory use
        memUse = '';

        % algo name and ver
        algoName = '';
        algoVer  = '';

        % function version and hash
        fVer;
        fHash;
        fClass;

        % key value pairs for the job
        kvp;

        % is staged
        isStaged;

        % is GPU
        isGPU = 0;
    end

    properties (Constant)
        spaceCHAR               = '#SPACE#';
        defaultCompileDirectory = '/mnt/myCompile/';
        % defaultCompileDirectory = '/home/jbustamante/condorFunctions/';
        % defaultCompileDirectory = '/mnt/scratch1/junkCompile/';
        % defaultCompileDirectory = '/mnt/spaldingdata/nate/inMemCondor/compiledFunctions/';
        % defaultCompileDirectory = '/mnt/snapper/nate/inMemCondor/compiledFunctions/'
        % defaultCompileDirectory = '/mnt/scratch1/nate/inMemCondor/compiledFunctions/';
    end

    properties (Access = private)
        dagline_headNode              = 'JOB headnode headnode.nothing NOOP';
        dagline_submitfile            = 'JOB #jobName# #jobSubmitfile#';
        dagline_vars_filetransferlist = 'VARS #jobName# FileTransferList = "#FileTransferList#"';

        dagline_vars_input_line  = 'VARS #jobName# argNumber#N# = "#argValue#"';
        dagline_vars_output_line = 'VARS #jobName# argNumber#N# = "#jobName#"';
        dagline_retry            = 'RETRY #jobName# #numberRetries#';
        %dagline_prescript = 'SCRIPT PRE #jobName# waitFileTrigger.sh #preScriptCommand#';
        dagline_prescript        = 'SCRIPT PRE #jobName# stageData.sh #preScriptCommand#';
        datline_tar_output       = 'SCRIPT POST #jobName# post.sh #jobName#.tar #outputLocation#';
        datline_tar_output_mod   = 'SCRIPT POST #jobName# post.sh ';
        dagline_graph_dec        = 'PARENT headnode CHILD ';
    end

    methods
        function obj = cFlow(func, algoName, algoVer, dirMappings, jobN, valueDatabase)
            if nargin >= 1
                % generate unique time-rand stamp
                obj.uniqueTimeRandStamp = strrep([num2str(now) , num2str(rand(1, 1))] , '.' , '');
                obj.dateString          = datestr(now);
                obj.subMemFunc          = func;

                % set the function name as a string
                setFunctionName(obj, 'cFlow_execute');

                % call compile - has built in compile logic
                uniqueDAG = cFlow.compileFunction(func, obj.uniqueTimeRandStamp);

                % set the dag launch directory
                setTempFilesLocation(obj, uniqueDAG);

                % make output location
                obj.outputLocation = cFlow.generateUniqueOutputLocation(func, obj.uniqueTimeRandStamp);
                CMD = ['mkdir -p ' , obj.outputLocation];
                system(CMD);

                % make default mapping available for the memory
                obj.addDirectoryMap([cJob.deployed_ouput_vars_location , '>' , obj.outputLocation]);

                % make code backup and hashed version
                % not here now

                % init kvp as container
                obj.kvp = containers.Map;
            end

            if nargin == 3
                obj.n_route_to_shell = 1;
                obj.algoName         = algoName;
                obj.algoVer          = algoVer;
            end

            if nargin == 6
                % if the arg is passed in as a string only and not a cell
                if ~iscell(dirMappings)
                    dirMappings = {dirMappings};
                end

                % add all the directory mappings to the dag
                for e = 1 : numel(dirMappings)
                    obj.addDirectoryMap(dirMappings{e});
                end
            end

            obj.jobList = cJob.empty(0,1);
            if nargin >= 4
                obj.jobList = cJob.empty(0,N);
            end

            if nargin == 5
                obj.valueDatabase = valueDatabase;
            end

            %             dagTable = table('Size',[0 1],'VariableNames',{'uuid'},'VariableTypes',{'string'});
            %             dagTable.uuid(end+1) = obj.uuid;
            %             conn = database('dagDatabase','','');
            %             sqlwrite(conn,'dag',dagTable);
            %             conn.close();
        end

        %{
        function translateKeys(obj)
            obj.kvp = containers.Map;
            keys = obj.kvp.keys();
            for e = 1:numel(keys)
                value = ['$(' keys{e} ')'];
                obj.kvpVarVersion(keys{e}) = value;
            end
        end
        %}

        function [] = initJobQueue(obj, N)
            obj.jobList = cJob.empty(0, N);
        end

        function [] = addDirectoryMap(obj, dirMapString)
            obj.dirMappingsString{end+1} = dirMapString;
        end

        function [] = addJob(obj, job)
            obj.jobList(obj.listPtr) = job;
            obj.listPtr              = obj.listPtr + 1;
        end

        function [] = addLocalD(obj, dFile)
            obj.localD{end+1} = dFile;
        end

        function [] = addSquidD(obj, dFile)
            obj.squidD{end+1} = dFile;
        end

        function [] = setMCRversion(obj, ver)
            obj.MCR_version = ver;
        end

        function [] = setFunctionName(obj, jobFunction)
            obj.jobFunction = jobFunction;
        end

        function [] = setOutputLocation(obj, outputLocation)
            obj.outputLocation = outputLocation;
        end

        function [] = setTempFilesLocation(obj, tmpLocation)
            obj.tmpFilesLocation = tmpLocation;
        end

        function [] = setSubmitNodeLocation(obj, submitNodeLocation)
            obj.submitNodeLocation = submitNodeLocation;
        end

        function [] = setMemory(obj, mem)
            obj.memUse = mem;
        end

        function [] = setGPU(obj, numGPU)
            obj.isGPU = numGPU;
        end

        % this function will render a local copy of the dag files
        function [] = renderDagFile(obj, oFilePath)
            %% renderDagFile
            if nargin == 1; oFilePath = obj.tmpFilesLocation; end

            fileID = fopen([oFilePath , obj.generate_dagName], 'w');

            % setup for headnode
            fprintf(fileID, '%s\n', obj.dagline_headNode);
            tmp_dagline_graph_dec = obj.dagline_graph_dec;

            % renderjobs
            for jb = 1 : numel(obj.jobList)
                % assign job name var
                jobName = ['job' , num2str(jb)];

                % build up graph dec
                tmp_dagline_graph_dec = [tmp_dagline_graph_dec , jobName , ' '];

                % assign submitfile var - homogenous waste for now
                submitFileName = obj.jobList(jb).generate_submitName;

                % setup job name and submit file
                tmp = strrep(obj.dagline_submitfile, '#jobName#', jobName);
                tmp = strrep(tmp,'#jobSubmitfile#', submitFileName);
                fprintf(fileID, '%s\n', tmp);

                % setup file transferlist
                tmp = strrep(obj.dagline_vars_filetransferlist, '#jobName#', jobName);
                tmp = strrep(tmp, '#FileTransferList#', obj.jobList(jb).getTransferFileList());
                fprintf(fileID, '%s\n', tmp);

                % setup for arguments in
                nargs = obj.jobList(jb).jobNargin;
                for arg = 1 : nargs
                    argValue = obj.jobList(jb).getArgument(arg);
                    tmp      = strrep(obj.dagline_vars_input_line, '#jobName#', jobName);
                    tmp      = strrep(tmp, '#N#', num2str(arg));
                    tmp      = strrep(tmp, '#argValue#', argValue);
                    fprintf(fileID, '%s\n', tmp);
                end

                keys            = obj.jobList(jb).kvp.keys;
                keyVAR_TEMPLATE = 'VARS #jobName# #key# = "#value#"';
                for e = 1 : numel(keys)
                    keyVAR = strrep(keyVAR_TEMPLATE, '#jobName#', jobName);
                    keyVAR = strrep(keyVAR, '#key#', keys{e});
                    keyVAR = strrep(keyVAR, '#value#', obj.jobList(jb).kvp(keys{e}));
                    fprintf(fileID, '%s\n', keyVAR);
                end

                %if isempty(obj.dirMappingsString)
                % setup for output tar via job name
                tmp = strrep(obj.dagline_vars_output_line, '#jobName#', jobName);
                tmp = strrep(tmp, '#N#', num2str(nargs+1));
                fprintf(fileID, '%s\n', tmp);
                %else
                for e = 1 : numel(obj.dirMappingsString)
                    % setup for output tar via job name
                    tmp = strrep(obj.dagline_vars_input_line, '#jobName#', jobName);
                    tmp = strrep(tmp, '#N#', num2str(nargs + 1 + (e)));
                    tmp = strrep(tmp, '#argValue#', [jobName , '_dirMapping' , num2str(e)]);
                    fprintf(fileID, '%s\n', tmp);
                end
                %end

                % setup for retry
                tmp = strrep(obj.dagline_retry, '#jobName#', jobName);
                tmp = strrep(tmp, '#numberRetries#', num2str(obj.retryValue));
                fprintf(fileID, '%s\n', tmp);


                % if pre script
                if ~isempty(obj.jobList(jb).stageCommand)
                    if ~isempty(obj.prescriptFile)
                        tmp = strrep(obj.dagline_prescript,'#jobName#',jobName);
                        tmp = strrep(tmp,'#preScriptCommand#',[obj.jobList(jb).stageCommand]);
                        fprintf(fileID,'%s\n',tmp);
                    end
                end

                %%% THIS IS OLD - YET WORKS FOR MOD CASE?
                if isempty(obj.dirMappingsString)
                    % setup for untar output in post script
                    tmp = strrep(obj.datline_tar_output, '#jobName#', jobName);
                    tmp = strrep(tmp, '#outputLocation#', obj.outputLocation);
                    fprintf(fileID, '%s\n', tmp);
                else
                    tmpTarName = strrep(obj.datline_tar_output_mod,'#jobName#',jobName);
                    for e = 1 : numel(obj.dirMappingsString)
                        fidx        = strfind(obj.dirMappingsString{e}, '>');
                        tmpFilePath = obj.dirMappingsString{e}(fidx(1) + 1 : end);
                        tmpFilePath = strrep(tmpFilePath, ' ', cFlow.spaceCHAR);
                        tmpTarName  = [tmpTarName , jobName , '_dirMapping' , num2str(e) , '.tar ' , tmpFilePath , ' '];
                    end

                    %
                    if obj.isStaged
                        tmpTarName = [tmpTarName , ' ' , obj.jobList(jb).uuid];
                        %tmpTarName = [tmpTarName '
                    end
                    %tmpTarName = strrep(tmpTarName,' ',cFlow.spaceCHAR);

                    fprintf(fileID, '%s\n', tmpTarName);
                end
            end

            if ~isempty(obj.maxidle)
                fprintf(fileID, '%s\n', ['maxidle=' , num2str(obj.maxidle)]);
            end

            if ~isempty(obj.maxjobs)
                fprintf(fileID, '%s\n', ['maxjobs=' , num2str(obj.maxjobs)]);
            end

            if ~isempty(obj.maxpost)
                fprintf(fileID, '%s\n', ['maxpost=' , num2str(obj.maxpost)]);
            end

            fprintf(fileID, '%s\n', tmp_dagline_graph_dec);
            fclose(fileID);
        end

        function dagName = generate_dagName(obj)
            dagName = [obj.jobFunction , '.dag'];
        end

        function scpFileList = generate_scpFileList(obj)
            scpFileList{1} = [obj.tmpFilesLocation , obj.generate_dagName()];
            scpFileList{2} = [obj.tmpFilesLocation , obj.jobList(1).generate_submitName()];
            scpFileList{3} = [obj.tmpFilesLocation , obj.jobList(1).generate_exeName()];
            scpFileList{4} = [obj.tmpFilesLocation , obj.jobFunction];
            scpFileList{5} = [obj.tmpFilesLocation , 'run_' obj.jobFunction , '.sh'];

            CMD = ['sed -i ''s/LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}\/runtime\/glnxa64:${MCRROOT}\/sys\/opengl\/lib\/glnxa64;/LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}\/sys\/opengl\/lib\/glnxa64:${PWD}\/SS:${PWD}\/lcms\/lib;/g'' ' , scpFileList{5}];
            system(CMD);

            scpFileList{6} = [obj.defaultCompileDirectory 'clear.sh'];
            scpFileList{7} = [obj.tmpFilesLocation 'post.sh'];
            if ~isempty(obj.stagePreScriptFile)
                %scpFileList{8} = [obj.tmpFilesLocation obj.prescriptFile];
                scpFileList{8} = [obj.stagePreScriptFile];
                scpFileList{9} = [obj.stagePostScriptFile];
            end
        end

        function submitDag(obj,icommands_auth,varargin)
            if nargin >= 3; maxidle = varargin{1}; end
            if nargin >= 4; maxpost = varargin{2}; end
            if nargin < 5
                %                 sshLocation = 'nate@128.104.98.63';
                sshLocation = 'jbustamante@128.104.98.63';
            else
                sshLocation = varargin{3};
            end

            remote_DAG_location = [obj.jobFunction , filesep , obj.uniqueTimeRandStamp];

            %
            if isempty(obj.dirMappingsString)
                obj.jobList(1).generate_submitFilesForDag(icommands_auth);
            else
                obj.jobList(1).generate_submitFilesForDag(icommands_auth,obj.dirMappingsString);
            end

            obj.renderDagFile();
            obj.generatePostScript();
            obj.generatePreScript();

            scpList         = obj.generate_scpFileList();
            dirCMD_logs_out = ['ssh ' , sshLocation , ' ''' , 'mkdir -p /home/jbustamante/condorFunctions/#directory#/logs/stdout/'''];
            dirCMD_logs_err = ['ssh ' , sshLocation , ' ''' , 'mkdir -p /home/jbustamante/condorFunctions/#directory#/logs/stderr/'''];
            dirCMD_output   = ['ssh ' , sshLocation , ' ''' , 'mkdir -p /home/jbustamante/condorFunctions/#directory#/output/'''];

            [status , result] = system(strrep(dirCMD_logs_out,'#directory#',remote_DAG_location));
            [status , result] = system(strrep(dirCMD_logs_err,'#directory#',remote_DAG_location));
            [status , result] = system(strrep(dirCMD_output,'#directory#',remote_DAG_location));

            dirCMD            = ['ssh ' , sshLocation , '  ''' , 'mkdir /home/jbustamante/condorFunctions/#directory#/'''];
            [status , result] = system(strrep(dirCMD, '#directory#', remote_DAG_location));

            CMD = ['scp #srcfile# ' , sshLocation , ':/home/jbustamante/condorFunctions/#directory#/#desfile#'];
            CMD = strrep(CMD, '#directory#', remote_DAG_location);
            for f = 1:numel(scpList)
                [pth , nm , ext]  = fileparts(scpList{f});
                tCMD              = strrep(CMD, '#desfile#', [nm , ext]);
                tCMD              = strrep(tCMD, '#srcfile#', scpList{f});
                [status , result] = system(tCMD);
            end

            % submit the job dag
            dagName = obj.generate_dagName();
            CMD     = ['ssh ' , sshLocation , ' ''' , 'cd /home/jbustamante/condorFunctions/#directory#/; condor_submit_dag -maxidle ' num2str(maxidle) ' -maxpost ' num2str(maxpost) ' ' dagName ''''];
            CMD     = strrep(CMD,'#directory#',remote_DAG_location);
            system(CMD,'-echo');

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % condor launch - END
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end

        function setClassInputsData(this, classIn)
            %% setClassInputsData
            this.fClass = classIn;
        end

        function generateSleepScript(obj, sleepTime, units)
            %% generateSleepScript
            sleepFile = [obj.tmpFilesLocation 'sleepScript.sh'];
            fileID = fopen(sleepFile,'w');
            fprintf(fileID,'%s\n',['sleep ' num2str(sleepTime) units]);
            fclose(fileID);
            obj.prescriptFile = 'sleepScript.sh';
        end

        function varargout = subsref(obj, s)
            %% subsref
            if strcmp(s(1).type,'()')
                % create list of staged files
                tic;
                stageList      = struct('fileUUID', {}, 'sourceName', {});
                stageTableList = table('Size', [0 , 4], ...
                    'VariableNames', ...
                    {'fileUUID' , 'jobUUID' , 'sourceName' , 'targetName'},...
                    'VariableTypes', ...
                    {'string' , 'string' , 'string' , 'string'});
                stor(['create file staging table:          ' , num2str(toc)]);

                % create a job for the call
                tic;
                tmpJob = cJob();

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % make a cJob which will wrap the cJob - why?
                %wrapJob = cJob();
                wrapJob = cJob(obj.algoName, obj.algoVer);

                % set GPU
                tmpJob.setAsMemoryJob(obj.uniqueTimeRandStamp, obj.subMemFunc);
                tmpJob.setNumberofArgs(numel(s.subs) - obj.n_route_to_shell);
                tmpJob.setNumberofOArgs(nargout);
                stor(['spun up inner job:                   ' , num2str(toc)]);

                %[obj] = fargList(s.subs,obj.valueDatabase,tmpJob.fullMatLocation);

                %tmpJob.fullMatLocation
                tic;
                depFile  = {};
                toUseKVP = obj.kvp;
                for e = 1 : (numel(s.subs) - obj.n_route_to_shell)
                    arg = s.subs{e + obj.n_route_to_shell};

                    %{
                    % check if is a file object
                    if isa(arg,'file')
                        if arg.isCOLD
                            [~,cmdString,enableString,stagedName] = arg.generateStagingCommand(tmpJob.uuid);
                            depFile{end+1} = ['https://s3dev.chtc.wisc.edu' xformFile('xform','flat',stagedName)];
                            [~,localName,localExt] = fileparts(depFile{end});
                            s.subs{e+obj.n_route_to_shell} = ['./' localName localExt];
                            stagedName = xformFile('xform','flat',stagedName);
                            stagedName = stagedName(2:end);
                        end
                    end
                    %}

                    if isa(arg, 'pmImageFile') || isa(arg, 'pmDefImageStack')
                        if ~(arg.isIRODS)
                            if isa(arg,'pmImageFile')
                                stageList(end + 1).fileUUID = arg.uuid;
                                stageList(end).sourceName   = arg.fullName();
                            elseif isa(arg,'pmDefImageStack')
                                for w = 1 : numel(arg.FileList)
                                    stageList(end + 1).fileUUID = arg.FileList(w).uuid;
                                    stageList(end).sourceName   = arg.FileList(w).fullName();
                                end
                            end

                            % set the argument for the image
                            arg.setToStageName('minio>', [cFlow.stageLocation , ...
                                obj.uuid , filesep , wrapJob.uuid]);
                            % set as staged
                            obj.isStaged = true;
                        end
                    end

                    if isa(arg,'pmImageFile')
                        toUseKVP('imageHash') = arg.fullHash;
                    end

                    argInputString{e} = tmpJob.setArg(arg,e);
                end

                stor(['done routing file data:              ' , num2str(toc)]);

                % add the output directory to the string for var name
                tic;
                for e = 1 : nargout
                    %varargout{e} = [obj.outputLocation 'output' filesep tmpJob.matFileName '@out' num2str(e)];
                    varargout{e} = [obj.outputLocation , tmpJob.matFileName , ...
                        '@out' , num2str(e)];
                end

                stor(['handling outputs to IDE:             ' , num2str(toc)]);

                tic;
                save(tmpJob.fullMatLocation, 'tmpJob', '-v7.3', '-append');
                stor(['saving inner job:                    ' , num2str(toc)]);

                tic; % start clock for spin up wrapper job

                % attach the files to wrap job
                for w = 1:numel(stageList)
                    stageTableList.fileUUID(end + 1) = stageList(w).fileUUID;
                    stageTableList.jobUUID(end)      = wrapJob.uuid;
                    stageTableList.sourceName(end)   = stageList(w).sourceName;

                    [p , nm , ext] = fileparts(stageList(w).sourceName);
                    targetName     = [cFlow.stageLocation , obj.uuid , filesep ...
                        wrapJob.uuid , filesep , nm , ext];

                    stageTableList.targetName(end) = targetName;
                end

                % add key/value pairs with $ for dag file
                wrapJob.kvp = toUseKVP;

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%% add deps
                % this was for arbitary files in staging
                % as of Feb 22, 2021.
                %{
                for e = 1:numel(depFile)
                    wrapJob.addFile(depFile{e});
                    %wrapJob.stageCommand = [enableString '|' stagedName];
                    wrapJob.stageCommand = wrapJob.uuid;
                end
                %}

                if ~isempty(stageTableList)
                    wrapJob.stageCommand = wrapJob.uuid;
                end

                wrapJob.isGPU = obj.isGPU;
                if ~isempty(obj.memUse)
                    wrapJob.setMemoryUse(obj.memUse);
                end

                wrapJob.changeMCRfile(obj.MCR_version);
                for e = 1 : numel(obj.localD)
                    wrapJob.addFile(obj.localD{e});
                end

                for e = 1 : numel(obj.squidD)
                    wrapJob.addSquidFile(obj.squidD{e});
                end

                wrapJob.setTempFilesLocation(obj.tmpFilesLocation);
                wrapJob.addFile(tmpJob.fullMatLocation);
                wrapJob.setFunctionName('cFlow_execute');
                wrapJob.setNumberofArgs(1 + obj.n_route_to_shell);
                wrapJob.setArgument(tmpJob.matFileName, 1);

                % direct value vs pointer
                if obj.n_route_to_shell ~= 0
                    pointerValue = s.subs{1};
                    wrapJob.setArgument(pointerValue, 2);

                    % added for miron
                    %wrapJob.addFile(s.subs{1});
                end

                stor(['spun up wrapper job:                 ' , num2str(toc)]);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                %{
                if isempty(obj.dirMappingsString)
                    wrapJob.generate_submitFilesForDag(icommands_auth);
                else
                    wrapJob.generate_submitFilesForDag(icommands_auth,obj.dirMappingsString);
                end
                %}

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %
                tic

                % add job to DAG
                obj.addJob(wrapJob);
                stor(['added wrapper job to DAG:            ' , num2str(toc)]);

                %                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %                 %
                %                 tic
                %                 % connect to the database
                %                 conn = database('dagDatabase','','');
                %                 % stack the attach the job to the dag
                %                 jobTable = table('Size',[0 2],'VariableNames',{'uuid','dagUUID'},...
                %                     'VariableTypes',{'string','string'});
                %                 jobTable.uuid(end+1) = wrapJob.uuid;
                %                 jobTable.dagUUID(end) = obj.uuid;
                %                 sqlwrite(conn,'job',jobTable);
                %                 stor(['wrote wrapper job to DAG table:      ' num2str(toc)]);

                tic

                % if there are files to stage
                if ~isempty(stageTableList)
                    sqlwrite(conn, 'stage', stageTableList);
                    conn.close();
                end

                stor(['wrote staging requests to database:  ' , num2str(toc)]);
            else
                %                 if ~nargout; varargout = cell(1); nargout = 1; end
                %                 varargout{1 : nargout} = builtin('subsref', obj, s);
                builtin('subsref', obj, s);
            end

            here = 1;
        end

        function generatePostScript(obj)
            remote_DAG_location = [obj.jobFunction , ...
                filesep , obj.uniqueTimeRandStamp];
            fileID              = ...
                fopen([obj.tmpFilesLocation , 'post.sh'], 'w');

            fprintf(fileID,'%s\n','#!/bin/bash');

            %SPACELINE = ['$(echo $#ARGNUM# | sed s/' cFlow.spaceCHAR '/ /g)'];
            SPACELINE = ['a#ARG#=${#ARG#//' , cFlow.spaceCHAR , '/ }'];
            setLine   = 'set ';
            for e = 1 : 4
                sl = strrep(SPACELINE, '#ARG#', num2str(e));
                setLine = [setLine , '"$a' , num2str(e) , '" '];
                fprintf(fileID, '%s\n', sl);
            end

            % Ensure post.sh is executable
            system(sprintf('chmod +x %s', [obj.tmpFilesLocation , 'post.sh']));

            % setup for post
            fprintf(fileID, '%s\n', setLine);

            % loop over each mapping for the post script
            for e = 1 : numel(obj.dirMappingsString)
                fidx = strfind(obj.dirMappingsString{e}, '>');
                s1   = num2str((e - 1) * 2 + 1);
                s2   = num2str((e - 1) * 2 + 2);

                utarLine = strrep(obj.utarLine,'#N1#', s1);
                utarLine = strrep(utarLine, '#N2#', [s2 , '" ' , ...
                    obj.dirMappingsString{e}(1:(fidx(1)-1)) , ...
                    '/* --strip-components=1']);

                % setup for untarline
                fprintf(fileID, '%s\n', utarLine);
                utarLine = strrep(utarLine, '#N2#', s2);

                % setup for rmtarline
                rmtarLine = strrep(obj.rmtarLine, '#N1#', s1);
                fprintf(fileID, '%s\n', rmtarLine);
            end

            if obj.isStaged
                fprintf(fileID, '%s\n', 'unstageData.sh $5');
            end
        end

        function generatePreScript(obj)
            copyfile(obj.stagePreScriptFile, obj.tmpFilesLocation);
            copyfile(obj.stagePostScriptFile, obj.tmpFilesLocation);
        end
    end

    methods (Static)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % compile
        % inputs: func: string that will need to be compiled
        %         uniqueTimeRandStamp: the dag for this evaluation of the function
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function uniqueEvalDirectory = compileFunction(func, uniqueTimeRandStamp)
            tmpCompileDirectory = '/home/jbustamante/condorFunctions/';
            warning off;

            % get the location of the function that is being used
            pathToFunction = which(func);

            % get the default compile directory
            compile_directory = cFlow.defaultCompileDirectory;

            % make the function compile directory
            functionDirectory = [compile_directory , func , filesep];
            mkdir(functionDirectory);

            % make the uniqueTimeRandStamp directory
            uniqueEvalDirectory = [functionDirectory , 'DAG' , filesep , ...
                uniqueTimeRandStamp , filesep];
            CMD                 = ['mkdir -p ' , uniqueEvalDirectory];
            system(CMD);

            % make the backup directory
            functionBackupDirectory = [functionDirectory , 'backUp' , filesep];
            mkdir(functionBackupDirectory);

            % make the function file
            functionFile = [functionDirectory , func , '.m'];

            % set the default compile flat to false
            compileFlag = true;

            % check to see if the functionFile already is present
            if exist(functionFile)
                % if the current version in the cFlow repo is different
                % from the known version, then backup the current, and compile
                CMD = ['diff ' , functionFile , ' ' , pathToFunction];

                [status , result] = system(CMD);
                if ~isempty(result)
                    % make backup of function
                    dateStamp = datestr(now);
                    dateStamp = strrep(dateStamp, ':', '_');
                    dateStamp = strrep(dateStamp, '-', '_');
                    dateStamp = strrep(dateStamp, ' ', '_');

                    [p , n , e] = fileparts(functionFile);
                    CMD = ['cp ' , functionFile , ' ' , ...
                        functionBackupDirectory , n , '_' , dateStamp , '.m'];
                    system(CMD);

                    % copy in new function
                    CMD = ['cp ' , pathToFunction , ' ' , functionFile];
                    system(CMD);
                    compileFlag = 1;
                end
            else
                CMD = ['cp ' , pathToFunction , ' ' , functionFile];
                system(CMD);
                compileFlag = 1;
            end

            if compileFlag
                tmpCompileDirectory = [tmpCompileDirectory , filesep , ...
                    uniqueTimeRandStamp , filesep];
                CMD                 = sprintf('mkdir -p %s', ...
                    tmpCompileDirectory);
                system(CMD);
                fprintf('Ran Command ''%s\n''', CMD);
                % CMD = ['mcc -d ' tmpCompileDirectory ' -m -v -R -singleCompThread -a cJob.m -m -v -R -singleCompThread cFlow_execute.m'];
                CMD = ['mcc -d ' tmpCompileDirectory ' '                        ...
                    '-m -v -R -singleCompThread  -a trackingFull.m '            ...
                    '-a trackingWhole.m          -a trackingProcessor.m '       ...
                    '-a segmentFullHypocotyl.m   -a segmentUpperHypocotyl.m '   ...
                    '-a segmentLowerHypocotyl.m  -a N1.m  -a N2.m  -a N3.m '    ...
                    '-a N4.m   -a N5.m  -a N6.m  -a N7.m  -a N8.m  -a N9.m '    ...
                    '-a N10.m  -a N11.m -a N12.m -a N13.m -a N14.m -a N15.m '   ...
                    '-a N16.m  -a N17.m -a N18.m -a N19.m -a N20.m '            ...
                    '-a MyNN.m -a genFunction.m  -a SeriesNetwork.m -a cJob.m ' ...
                    '-m -v -R -singleCompThread cFlow_execute.m'];
                eval(CMD);

                % copy the compiled function and its nessary scripts into the
                % evalution directory
                filesToCopy = dir(tmpCompileDirectory);
                filesToCopy(arrayfun(@(x) x.isdir, filesToCopy)) = [];
                for e = 1 : numel(filesToCopy)
                    sourceFile = [tmpCompileDirectory , filesToCopy(e).name];
                    targetFile = [functionDirectory , filesToCopy(e).name];
                    CMD        = ['cp ' , sourceFile , ' ' , targetFile];
                    system(CMD);
                end
            end

            % copy the compiled function and its nessary scripts into the
            % evalution directory
            filesToCopy = dir(functionDirectory);
            %             filesToCopy(filesToCopy.isdir) = [];
            filesToCopy(arrayfun(@(x) x.isdir, filesToCopy)) = [];

            for e = 1 : numel(filesToCopy)
                sourceFile = [functionDirectory , filesToCopy(e).name];
                targetFile = [uniqueEvalDirectory , filesToCopy(e).name];
                CMD        = ['cp ' , sourceFile , ' ' , targetFile];
                system(CMD);
            end
        end

        function uniqueEvalDirectory = generateUniqueCompileLocation(func, uniqueTimeRandStamp)
            % get the default compile directory
            compile_directory = cFlow.defaultCompileDirectory;

            % make the function compile directory
            functionDirectory = [compile_directory , func , filesep];

            % make the uniqueTimeRandStamp directory
            uniqueEvalDirectory = [functionDirectory 'DAG' filesep uniqueTimeRandStamp filesep];
        end

        function uniqueOutputLocation = generateUniqueOutputLocation(func, uniqueTimeRandStamp)
            uniqueEvalDirectory  = cFlow.generateUniqueCompileLocation( ...
                func, uniqueTimeRandStamp);
            uniqueOutputLocation = ...
                [uniqueEvalDirectory , 'functionOutputs' , filesep];
        end

        function persistFunctionCall()
        end
    end
end

%{
CFLO = cFlow('testCondorFunction');
res  = CFLO(1,2);
CFLO.submitDag(50,50);
o    = cFlowLoader(res);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % simple test - many-inputs > one-output
    func = cFlow('testCondorFunction');
    res = func(1,2);
    func.submitDag(50,50);
    o = cFlowLoader(res);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % simple test - many-inputs > many-outputs
    func = cFlow('testCondorFunction');
    [res1,res2] = func(1,2);
    func.submitDag(50,50);
    [o1,o2] = cFlowLoader(res1,res2);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % simple test - loop over inputs
    func = cFlow('testCondorFunction');
    for e = 1:10
        [resM1{e} resM2{e}] = func(e,e+1);
    end
    auth = readtext('/mnt/spaldingdata/nate/auth.iplant');
    auth = auth{1};
    func.submitDag(auth,50,50);
    for e = 1:10
        [o1M{e} o2M{e}] = cFlowLoader(resM1{e},resM2{e});
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % test directory mapping(s)
    func = cFlow('testCondorFunction',{'saveTo>/mnt/spaldingdata/nate/saveTo/','saveTo2>/mnt/spaldingdata/nate/saveTo2/'});
    res = func(1,2,'./saveTo/','./saveTo2/');
    func.submitDag(50,50);
    o = cFlowLoader(res);
 
    func.setMCRversion('v930');   
%}