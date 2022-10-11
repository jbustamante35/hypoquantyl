function genotype = initializeGenotype(varargin)
%% initializeGenotype: create a Genotype object from flexible input
% This function parses through input and determines what Genotype object to
% create from that input. The resulting Genotype object will be prepped for
% using it's own methods to load and process data.
%
% Usage:
%   genotype = initializeGenotype(gName, 'Parent', P, ...
%        'image_extension', ext, 'sort_method', sMethod)
%
% Input:
%   gName: name for Genotype object
%   Ein: parent Experiment object
%   image_extension: file type to analyze
%   sort_method: attribute to sort image by (date, name, etc)
%
% Output:
%   genotype: resulting Genotype object with various properties set
%
%% Parse Inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Initialize with parent Experiment object
ex                      = Parent;
genotype                = Genotype('GenotypeName', gName, 'Parent', ex);
genotype.ExperimentName = ex.ExperimentName;
genotype.ExperimentPath = ex.ExperimentPath;

%% Create image data store from path to images
Imgs = imageDatastore([ex.ExperimentPath , filesep,  gName], ...
    'IncludeSubfolders', add_sub_dirs, 'FileExtensions', image_extension);
genotype.storeImages(Imgs);

% Set Segmentation Defaults
genotype.setSegDefaults;
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method

p = inputParser;
p.addRequired('gName');
p.addOptional('Parent', Experiment);
p.addOptional('image_extension', '.TIF');
p.addOptional('sort_method', 'name');
p.addOptional('add_sub_dirs', 0);

p.parse(varargin{1}{:});
args = p.Results;

end
