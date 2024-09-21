function [] = stor(text, varargin)
    global type;        % type of context
    global state;       % state {'on'|'off'}

    global timerLength;

    global level;       % level to indent text
    global tabK;        % tab charater

    global preambleK;   % char after tabK
    global preambleN;   % length of preamble 
    global preambleC;   % char after repmat

    global bannerK;
    global bannerN;
    global bannerC;

    if isempty(tabK);      tabK     = '-';  end
    if isempty(preambleK); preamble = '';   end
    if isempty(bannerK);   bannerK  = '*';  end
    if isempty(bannerN);   bannerN  = '84'; end

    if ~isempty(text)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % process text command into the printing function
        if strcmp(text(1), '¿')
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % remove command string
            text(1) = [];
            cmd     = [text , '(,'];

            for e = 1 : numel(varargin)
                if e == 1; cmd(end) = []; end

                if isnumeric(varargin{e})
                    arg = num2str(varargin{e});
                else
                    arg = ['''' , varargin{e} , ''''];
                end

                cmd = [cmd , arg , ','];
            end

            cmd(end) = ')';
            cmd      = [cmd ';'];           
            eval(cmd); % eval the command
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        else
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % default end char
            endCap      = '\n';
            usePreamble = '';
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % is the stor is {on|off}
            if state
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %
                if strcmp(type,'timerMode')
                    text = timerReport(text);
                    endCap = '';
                    useTabK = '';
                    useTabN = 0;
                    %text = num2str(text);
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %useTabK = tabK;
                %useTabN = level;
                %usePreamble = preamble;
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % normal print mode
            % [ (0) tabs - preabmble {''} - text - (1) cap {\n} ] 
            else
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
                if nargin < 2; useTabN = 0;    end % tab indent number
                if nargin < 3; useTabK = '\t'; end % tab indent char
                % end cap
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % build string
            text = [repmat(useTabK,[1 useTabN]) usePreamble text endCap];
            % print string
            internalPrint(text);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end

function [] = startTimer(length, message)
    %%%%%%%%%%%%%%%%%%%%
    % init 
    messageBuffer = initTimer(length, message);
    
    %%%%%%%%%%%%%%%%%%%%
    % print header
    header = ['|' , repmat('-', [1 , messageBuffer]) , '|\n'];
    fprintf(header);
    
    %%%%%%%%%%%%%%%%%%%%
    % make a new timer
    newTimer(length, message);    
end

function [] = stopTimer()
    global timerWidth;
    header = ['|' , repmat('-', [1 , timerWidth]) , '|\n'];
    fprintf(header);
    off();
end

function [messageBuffer] = initTimer(length, message)
    global type;
    global state;
    
    global timerLength;
    global reportLength;
    global reportIndex;
    global timerWidth;
    
    reportIndex = 0;
    type        = 'timerMode';
    state       = true;
    timerLength = length;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    default_reportLength = 60;
    maxReportLength      = 100;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    messageBuffer = default_reportLength + numel(message) + 2;
    if messageBuffer < maxReportLength; messageBuffer = maxReportLength; end
    messageBuffer = min(messageBuffer, maxReportLength);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % store the length of the reporting strip
    reportLength = messageBuffer - numel(message) - 3;   
    timerWidth   = messageBuffer;
end

function [] = newTimer(length,message)

    [messageBuffer] = initTimer(length,message);
    
    
    banner = [ '| ' message ': '];
    fprintf(banner);
end

function [strOut] = timerReport(n)
    global timerLength;
    global reportLength;
    global reportIndex;
    
    strOut = '';
    newIndex = floor(reportLength*(n/timerLength));
    if (newIndex > reportIndex)
        %fprintf('.');
        jump = newIndex - reportIndex ;
        strOut = repmat('.',[1 jump]);
        reportIndex = newIndex;
    end
    
    if (n == timerLength)
        strOut = [strOut '|\n'];
    end
end

function [] = off()
    global state;
    state = false;
end

function [] = internalPrint(text)
    fprintf(text);
end

function [] = printBanner(bannerK,bannerN)
    [banner] = generateBanner(bannerK,bannerN);
end

function [] = setBanner(state)    
end

function [banner] = generateBanner(bannerK,bannerN)
    banner = [repmat(bannerK,[1 bannerN]) '\n'];
end

        %{
        fidx1 = strfind(text,'(');
        fidx2 = strfind(text,')');
        cmd = text(1:(fidx1(1)-1));
        args = [',' text((fidx1(1)+1):(fidx2(1)-1)) ','];
        art = numel(strfind(args,',')) - 2 + 1;
        switch cmd
            case 'set'
                
                fidx = strfind(args,',');
                arg1 = args((fidx(1)+1):(fidx(2)-1));
                arg2 = args((fidx(2)+1):(fidx(3)-1));
                cmd = [arg1 ' = ' arg2 ';'];
                eval(cmd);
        end
        %}