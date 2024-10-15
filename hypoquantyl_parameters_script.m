%% HypoQuantyl Parmeters Script
% 1) Select sample data to run. Uncomment as needed.
tset = 'single'; % [single_seedling.zip]   1 cry1 mutant grown for 8h in darkness
% tset = 'multiple'; % [multiple_seedling.zip] 5 wt seedlings grown for 2h in darkness then 6h blue light

% 2) File path to where you downloaded and unzipped the sample images
path_to_data = '/home/username/Downloads/testimages';

% 3) General options
vrb   = 1;     % Verbosity [ 0 none | 1 verbose ]
sav   = 1;     % Save results into .mat files
par   = 1;     % Use parallel processing [0 | 1]
odir  = pwd;   % Directory path to store results [default pwd]
edate = tdate; % Date of analysis [format string as 'YYMMDD' to set manually]

% Advanced parameters are below, but not recommended to toggle unless you know
% how they are implemented in this pipeline

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% Advanced Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Camera to Pixel Settings
pix_per_mm  = 184.5;   % Pixels per mm
frm_per_hr  = 0.08333; % Frames per hour
fblu        = 24;      % Frame of blue light on

% Pre-Processor Parameters
toExclude = [];           % Image stacks to exclude
fidxs     = 0;            % Figure indices to show progress
mth       = 'new';        % Image processing method
vmth      = 'Hypocotyls'; % Pre-Processing method
hlng      = 250;          % Distance for hypocotyl clipping

% Segmentation Parameters
ncores    = feature('numcores'); % Total cores available
fidx      = 0;        % Figure index to show progress
hqnm      = 'HQ.mat'; % Filename of models and data
nopts     = 0;        % Iterations for optimizer
flp       = [];       % Image flip ([] detects direction)
keepBoth  = 1;        % Store flipped segmentation result (fix flipping issues)
path2subs = 2;        % Keeps as Network object (run locally, no parallel)

% Segmentation on Lower Region Parameters
dsz  = 5;   % Mask smoothing disk radius
smth = 5;   % Mask smoothing value
npts = 151; % Coordinates per contour

% Set starting segmentation index [debug specific seedlings]
isdl  = 1; % Segmentation starting seedling index
ihyp  = 1; % Segmentation starting frame

% Set starting tracking index [debug tracking]
ifrm  = 1;  % Tracking starting frame
ffrm  = []; % Tracking final frame
dbug  = 1;  % HTCondor not smoothly implemented for users [else debug = 0]

% Tracking Parameters
npcts = 61;   % Number of patches per midline
skp   = 1;    % Frame skip
dsk   = 12;   % Patch matching disk radius
dres  = 130;  % Patch matching disk resolution
symin = 1.0;  % Patch matching minimum stretch
symax = 1.3;  % Patch matching max stretch
itrs  = 500;  % Patch matching iterations
ttolf = 1e-8; % Patch matching tolerance function
ttolx = 1e-8; % Patch matching x tolerance
dlt   = 20;   % Max tracking distance lower bound
eul   = 1;    % Use Eulerian tracking

% Post-Processing Tracking Parameters
nlc   = 1;                         % Non-Linear Constraints
lb    = [0 , 0    , -500  , 0];    % Lower bound settings
ub    = [6 , 0.05 , 200    , 0.5]; % Upper bound settings
tol   = [1e-12 , 1e-12];           % Patch matching tolerance
tsmth = 3;                         % REGR map smoothing
ltrp  = 1000;                      % REGR Map interpolation
othr  = 2.5;                       % FLF fit outlier removal percentage
vrng  = 10;                        % FLF fit max velocity
fmax  = 20;                        % FLF fit Fmax
ki    = 0.02;                      % FLF fit initial k
ni    = 0.3;                       % FLF fit initial n

% Exclude slow-growing seedling [for multiple_seedling.zip]
if strcmp(tset, 'multiple'); iex  = 5; else iex = []; end

% ---------------------------------------------------------------------------- %
%% Export inputs
if endsWith(path_to_data, filesep); path_to_data = path_to_data(1 : end-1); end

% Save parameters into .mat file
ostr     = {'hqinputs' ; sprintf('%s_hqinputs', edate)};
hqinputs = cellfun(@(x) sprintf('%s%s%s', odir, filesep, x), ...
    ostr, 'UniformOutput', 0);
save(hqinputs{1}, '-v7.3');
save(hqinputs{2}, '-v7.3');
pause(2);
