function [flist , plist] = getRequiredFiles(fin, opt)
%% getRequiredFiles: list dependencies of program files
% This is just a wrapper for matlab.codetools.requiredFilesAndProducts since
% that is a pain to type.
%
% Usage:
%   [flist , plist] = getRequiredFiles(fin, opt)
%
% Input:
%   fin: file to assess
%   opt: options to run with function (default [])
%
% Output:
%   flist: MATLAB program files required to run program
%   plist: MATLAB products required to run program
%

if nargin < 2; opt = []; end

if isempty(opt)
    [flist , plist] = matlab.codetools.requiredFilesAndProducts(fin);
else
    [flist , plist] = matlab.codetools.requiredFilesAndProducts(fin, opt);
end

flist = flist';
plist = plist';
end

