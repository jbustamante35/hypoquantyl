function obj = classInputParser(obj, prps, varargin)
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
%   varargin: any range of <property>,<value> tuples
%
% Output:
%   obj: class set with parameters from varargin
%
% TODO:
%   [02.24.2020] Set default properties for empty object (i.e. structs)
%

% Parse inputs to obtain property values
args = parseConstructorInput(prps, varargin);

% Set properties to values from arguments structure
fn   = fieldnames(args);
for k = fn'
    obj.(cell2mat(k)) = args.(cell2mat(k));
end

end

function args = parseConstructorInput(prps, vargs)
%% Parse input parameters for Constructor method
p = inputParser;

% Add all properties as empty
cellfun(@(x) p.addOptional(x, []), prps, 'UniformOutput', 0);

% Parse arguments and output into structure
p.parse(vargs{1}{:});
args = p.Results;
end
