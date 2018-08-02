function emoji = getEmoji(request)
%% getEmoji: returns emoji defined by request
% This function returns an emoji of the user's request, efined by request. The default if the emoji
% does not exist or invalid is the idunno emoticon.
%
% Usage:
%   emoji = getEmoji(request)
%
% Input:
%   request: string request of emoji
%
% Output:
%   emoji: requested emoji as a string
% 

switch request
    case 'idunno'
        emoji = sprintf('\\_("/)_/');
        
    otherwise
        emoji = sprintf('\\_("/)_/');
end


end