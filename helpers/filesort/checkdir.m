function chk = checkdir(dnm, p)
%% checkdir: check for directory and create it if needed
%
% Usage:
%   chk = checkdir(dnm, p)
%
% Input:
%   dnm: directory name
%   p: pause before creating directory [default 1]
%
% Output:
%   chk: 0 if directory was created; 1 if directory existed
%

if nargin < 2; p = 1; end

chk = 0;
if ~isfolder(dnm)
    mkdir(dnm);
    chk = 1;

    if p; pause(0.5); end
end
end
