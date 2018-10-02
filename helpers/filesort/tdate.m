function dt = tdate(varargin)
%% tdate: shortcut function to get today's date string in the format that I use a lot
% I don't get why nargin being true (there are indeed no arguments) evaluates to 0 (\facepalm)

if ~nargin
    dt = datestr(now, 'yymmdd');
else
    ver = varargin{1};
    switch ver
        case 's'
            dt = datestr(now, 'yymmdd');
        case 'm'
            dt = datestr(now, 1);
        case 'l'
            dt = datestr(now, 'ddd-mmm-dd-yyyy-HHMM');
        otherwise
            dt = datestr(now, 'yymmdd');
    end
end

end