classdef hasReporting < handle
    
    properties
        
        initTime = containers.Map;
        msgMap = containers.Map;
        verboseReporting = true;
        msgCount = 0;
        indentChar = '      ';
    end
    
    
    methods
        
        function [this] = hasReporting(verbose)
            if nargin < 1;verbose = true;end
            this.verboseReporting = verbose;
        end
        
        function [this] = startReport(this,type,msg)
            if this.verboseReporting
                % handle zero block
                this.handleZeroBlock();
                % init start time for the type
                this.initTime(type) = clock;
                % store the msg for the type
                this.msgMap(type) = msg;
                % make message
                strMsg = this.makeStartMsgs(msg);
                % increment tab level
                this.msgCount = this.msgCount + 1;
                % report msg
                stor(strMsg);
            end
        end
        
        function [this] = endReport(this,type,extraMsg)
            try
                if this.verboseReporting
                    % get the elapsed time
                    deltaT = etime(clock,this.initTime(type));
                    % get msg
                    msg = this.msgMap(type);
                    if nargin == 3
                        msg = this.appendMsg(msg,extraMsg);
                    end
                    % build end msg
                    msg = this.makeEndMsg(msg,deltaT);
                    % report msg
                    stor(msg);
                    % delete 
                    this.msgMap(type) = [];
                    this.initTime(type) = [];
                    % decrement tab level
                    this.msgCount = this.msgCount - 1;
                    
                    
                    this.handleZeroBlock();
                    
                    
                end
            catch ME
                ME
            end
        end
        
        function [] = handleZeroBlock(this)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % handle zero block
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if this.msgCount == 0
                stor(['|---------------------------------------']);
            end
        end
        
        function [] = report(this,msg,toIndent)
            try
                if nargin < 3;toIndent = true;end
                if this.verboseReporting
                    if toIndent
                        n = this.getIndentLevel();
                        value = this.indentChar;
                        msg = ['|-msg: ' msg];
                        msg = hasReporting.prependMsg(msg,value,n);
                    end
                    stor(msg);
                end
            catch ME
                ME
            end
        end
        
        
        function [msg] = makeStartMsgs(this,msg)
            msg = ['|-start: ' msg ];
            level = this.getIndentLevel();
            msg = hasReporting.prependMsg(msg,this.indentChar,level);
        end
        
        function [n] = getIndentLevel(this)
            n = this.msgCount;
        end
        
        function [msg] = makeEndMsg(this,msg,deltaT)
            
            %{
            msg = ['|---end: ' msg ' : @TOC'];
            if nargin == 3
                msg = strrep(msg,'@TOC',num2str(deltaT));
            end
            %}
            msg = ['|---end: ' msg];
            deltaT_msg = ['deltaT=' num2str(deltaT)];
            msg = this.appendMsg(msg,deltaT_msg);
            level = this.getIndentLevel() - 1;
            msg = hasReporting.prependMsg(msg,this.indentChar,level);
            
        end
        
        function [msg] = handleIndent(this,msg)
            n = this.getindentLevel();
            indent = this.indentChar;
            msg = hasReporting.prependMsg(msg,indent,n);
        end
        
        function [msg] = appendMsg(this,msg,extra)
            level = this.getIndentLevel();
            indent = repmat(this.indentChar,[1 level]);
            msg = [msg char(10) indent '|--> ' extra];
        end
        
    end
    
    methods (Static)
    
        
        
        function [msg] = prependMsg(msg,value,n)
            msg = [repmat(value,[1 n]) msg];
        end
        
        
        
        %{
        function [msg] = makeStartMsgs(msg)
            msg = ['start: ' msg ];
        end
        
        
        function [msg] = appendMsg(msg,extra)
            msg = [msg ':' extra];
        end
        
        function [msg] = makeEndMsg(msg,deltaT)
            msg = ['end: ' msg ' : @TOC'];
            
            if nargin == 2
                msg = strrep(msg,'@TOC',num2str(deltaT));
            end
        end
        %}
        
        
    end
    
    
end