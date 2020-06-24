function obj = classInputParser(obj, prps, deflts, varargin)
%% classInputParser: input parser for my custom classes
% All of my classes have the same general structure, and the Constructor method
% for each of them are exactly the same. Each has a unique list of properties
% that a new object can be instanced with, otherwise they are simply blank
% arrays.
%
% So instead of having this function in every class, I just decided to make a
% single function that each will share.
%
% Usage:
%   obj = classInputParser(varargin)
%
% Input:
%   obj: class to construct
%   prps: public properties of the Class [obtain with properties('<class>')]
%   dflts: defaults for any properties (defaults to empty array [])
%   varargin: any range of <property>,<value> tuples
%
% Output:
%   obj: class set with parameters from varargin
%

% Parse inputs to obtain property values
args = parseConstructorInput(prps, deflts, varargin);

% Set properties to values from arguments structure
fn = fieldnames(args);
for k = fn'
    obj.(cell2mat(k)) = args.(cell2mat(k));
end

end

function args = parseConstructorInput(prps, deflts, vargs)
%% Parse input parameters for Constructor method
p = inputParser;

% Replace empty argument with default value
emptyprps = cell(numel(prps), 1);
if ~isempty(deflts)
    matchIdxs            = cell2mat(cellfun(@(x) find(strcmp(prps, x)), ...
        deflts(:,1), 'UniformOutput', 0));
    emptyprps(matchIdxs) = deflts(:,2);
end

% Add all properties as empty
cellfun(@(x,d) p.addOptional(x, d), prps, emptyprps, 'UniformOutput', 0);

% Parse arguments and output into structure
p.parse(vargs{1}{:});
args = p.Results;
end
