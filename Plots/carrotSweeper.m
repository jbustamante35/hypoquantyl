function [SweepData, TableData] = carrotSweeper(varargin)
%% carrotSweeper: run full pipeline for PCA analysis, PC sweeper, and saving data
% This function runs the full pipeline for extracting BW images from the inputted directory
% (including subdirectories), and runs these images through PCA analysis of x-/y-coordinates with
% the desired number of Principal Components (PC).
%
% The algorithm then sweeps through the PCs by iteratively adding or subtracting each PC by a
% standard deviation, with the number of sweeps defined by the stps parameter.
%
% Lastly, the x/y PC scores are matched with their corresponding UID, which are extracted from the
% filename of each image. This is stored as a table and exported as a csv file.
%
% Need to make this more generalizable, so you could ask for any identifier (default is UID)
%
% Usage:
%   [SweepData, TableData] = carrotSweeper(dPath, 'numX', n, 'numY, m, 'SaveData', sv)
%
% Input:
%   dPath: full path to image directory (can have subdirectories of images)
%   FileExtension: string filename extension of images (default is 'png')
%   numX: number of Principal Components for x-coordinates
%   numY: number of Principal Componennts for y-coordinates
%   Steps: standard deviation steps up and down to sweep through PCs (default is 5)
%   Vis: visualize outputs
%   SaveData: save figures in .fig and .tif, and save data in .mat file
%
% Output:
%   SweepData: output from runSweepAnalysis containing data from PCA and PC sweep
%   TableData: table format of requested ID and corresponding PC scores
%
% Example:
%   sb = '/home/jbustamante/LabData/scott_brainard';
%   dPath = sprintf('%s/scott_masks/180918/cal2018', sb);
% 
%   [swpData, uidTable] = carrotSweeper(dPath);                     % Outputs UID-Xscores-Yscores
%   [swpData, uidTable] = carrotSweeper(dPath, 'SaveData', true);   % Also outputs table in csv file
%   [swpData, crvTable] = carrotSweeper(dPath, 'ID', 'Curvature', 'SaveData', true);  % Outputs Curvature-Xscores-Yscores and saves table in csv file
%
%   *See getToken function below to see which ID tags you can use
%

%% Parse Inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    % MATLAB's assignin function only assigns variables for the caller of the function calling
    % assignin, rather than in the function it is being called from. This neat little trick creates
    % a temporary anonymous function to assign variables to this local workspace.
    % See Alec Jacobson's blog post at (http://www.alecjacobson.com/weblog/?p=3792)
    
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Load path and create data store
I      = imageDatastore(dPath, 'IncludeSubfolders', 1, 'FileExtensions', FileExtension);
fnames = I.Files;

%% Search through file strings
try
    tok  = getToken(ID);
    expr = sprintf('{%s_(%s)}', ID, tok);
    ids  = regexpi(fnames, expr, 'tokens');
    str  = cellfun(@(x) char(x{1}), ids, 'UniformOutput', 0);
catch
    % Default to UID if error
    tok  = getToken('UID');
    expr = sprintf('{%s_(%s)}', 'UID', tok);
    ids  = regexpi(fnames, expr, 'tokens');
    str  = cellfun(@(x) char(x{1}), ids, 'UniformOutput', 0);
end

uid = char(str);

%% Run PCA analysis and PC sweep
BW        = I.readall;
SweepData = runSweepAnalysis(BW, numX, numY, Steps, Vis, SaveData);
pX        = SweepData.pcaX.PCAscores;
pY        = SweepData.pcaY.PCAscores;

%% Store data as table and save as csv
stc_data  = struct(ID, uid, 'X_scores', pX, 'Y_scores', pY);
TableData = struct2table(stc_data);
tbl_name  = sprintf('%s_%s-PCscores_%droots.csv', datestr(now, 'yymmdd'), ID, length(TableData.UID));

%% Save table as csv
if SaveData
    writetable(TableData, tbl_name);
end

end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method

p = inputParser;
p.addRequired('dPath', @ischar);
p.addParameter('FileExtension', '.png');
p.addParameter('numX', 3); % Sets number of PCs to extract from x-coordinates
p.addParameter('numY', 2); % Sets number of PCs to extract from y-coordinates
p.addOptional('Steps', 5);
p.addOptional('ID', 'UID');
p.addOptional('Vis', 0);
p.addOptional('SaveData', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

function val = getToken(key)
%% returns regex string for token
% As of now, a full file path string name is as follows:
% /path/{Row_9599}{Root_10}{UID_186-2018}{Source_B2566A}{Scale_466}{Location_California}{Curvature_168}.png'
%
% An image name consists of the {key_value} pattern
% This could be more generalized by setting the keys cell string to all the names found in the
% filename with the {key_val} structure [do this later]

keys = {'Row', 'Root', 'UID',    'Source',    'Scale', 'Location', 'Curvature', 'Photo', 'Genotype'};
vals = {'\d+', '\d+', '\d+-\d+', '\w+\d+\w+', '\d+',    '\w+',      '\d+',       '\d+',      '*'};

if ismember(key, keys)
    val = vals{cellfun('length', regexp(keys, key)) == 1};
else
    fprintf('ID %s not found\n', key);
    val = '';
end

end

