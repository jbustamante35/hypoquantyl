function ex = makeToyExperiment(din, N, sav)
%% makeToyExperiment: generate fake dataset for HypoQuantyl pipeline
% description
%
% From a really quick check of pixel intensities, I got a general idea of some
% background and foreground values to use for the fake images:
%   Background: 90
%   Foreground: 42
%
%
% Usage:
%   ex = makeToyExperiment(din, N, sav)
%
% Input:
%
%
% Output:
%
%

%% Constants
% ISZ = [101 101];
ISZ = [200 500];
BG  = 90; % average background intensity
FG  = 42; % average foreground intensity
RAD = (5 : 40) + (0.1 * ISZ(2)); % range for randomly chosen circle radii
YC  = (0 : 20) + (0.5 * ISZ(1)); % range for y-coordinate centers of circle
XC  = (0 : 20) + (0.5 * ISZ(2)); % range for x-coordinate centers of circle
ZC  = 20; % resolution of circle edge
CSZ = 30; % roundness of circle

% Function handles to get random indices
m = @(x) randi([1 length(x)], 1);
M = @(x) x(m(x));

% Misc
sprA = repmat('=', 1, 80);
sprB = repmat('-', 1, 80);

tAll = tic;
fprintf('\n%s\nGenerating simulated dataset of %d circles\n%s\n', sprA, N, sprB);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Create Experiment object in directory
t = tic;
fprintf('Generating Experiment object[ RAD(%d, %d) | XC(%d, %d) | YC(%d, %d) ]...', ...
    min(RAD), max(RAD), min(XC), max(XC), min(YC), max(YC));

% Experiment object with 1 Genotype with 1 Seedling of N frames
%ex      = Experiment(din);
ex      = Experiment('ExperimentPath', din);
genodir = sprintf('%s/%03dcircles', din, N);
mkdir(genodir);

% Create images and store in Genotype directory
cmd  = digitString(N, 'i');
ext  = 'tiff';

if ~any(size(dir([genodir sprintf('/*.%s', ext)]), 1))
    for i = 1 : N
        % Determine parameters for the circle
        r = M(RAD);
        x = M(XC);
        y = M(YC);

        % Generate the circle and save as a tiff image
        img = makeCircleImage(ISZ, BG, FG, r, x, y, CSZ);
        inm = sprintf('%s/%s.%s', genodir, eval(cmd), ext);
        imwrite(img, inm, 'tiff');


        fprintf('%s | Size: [%d , %d] | Radius: %d | X: %d | Y: %d\n', ...
            eval(cmd), ISZ, r, x, y);
    end
else
    [~, ddir] = fileparts(din);
    [~, gdir] = fileparts(genodir);
    fprintf('%d Images already written in %s...', N, [ddir , '/' , gdir]);
end

fprintf('DONE! [%.02f sec]\n', toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Continue HypoQuantyl pipeline go generate sub-classes
ex.AddGenotypes(sprintf('.%s', ext));

% Customized algorithm to get Seedling child objects
g = ex.combineGenotypes;
arrayfun(@(x) x.setAutoSeedlings, g, 'UniformOutput', 0);

% Customized algorithm to get Hypocotyl child objects
s = ex.combineSeedlings;
arrayfun(@(x) x.setAutoHypocotyls, s, 'UniformOutput', 0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Put through automated training algorithm
fIdx = 1 : 2;

ht  = arrayfun(@(x) 1 : x.Lifetime, s, 'UniformOutput', 0);
cin = arrayfun(@(x) [repmat(x, size(ht{x},2), 1) , ones(size(ht{x},2),1) , ...
    ht{x}'], 1 : ex.NumberOfGenotypes, 'UniformOutput', 0);
cin = cat(1, cin{:});
D   = trainCircuits_automated(ex, cin, fIdx, sav, 0);

% Generate Curve objects
arrayfun(@(x) x.ReconfigInterpOutline, D, 'UniformOutput', 0);
arrayfun(@(x) x.CreateCurves('redo', 0), D, 'UniformOutput', 0);
C       = arrayfun(@(x) x.Curves, D, 'UniformOutput', 0);
C       = cat(1, C{:});
numCrvs = numel(C);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save data
if sav
    t = tic;
    fprintf('Saving data for %d Curves...', numCrvs);
    fnm = sprintf('%s_FakeCircles_%03dCurves', tdate, numCrvs);
    save(fnm, '-v7.3', 'C');
    fprintf('DONE! [%.02f sec]\n', toc(t));
end

%
fprintf('%s\nFinished generating %d circles [%.02f sec]\n%s\n', ...
    sprB, N, toc(tAll), sprA);

end

function I = makeCircleImage(isz, bg, fg, r, x, y, z)
%% makeCircleImage: generate fake CircuitJB object
% asdf
%% Make circles on images
% Make image
im    = zeros(isz);
im(:) = bg;

th   = 0 : pi/z : 2*pi;
xcrd = r * cos(th) + x;
ycrd = r * sin(th) + y;
crc  = round([xcrd ; ycrd]');

% Extract circle
idx     = sub2ind(size(im), crc(:,2), crc(:,1));
im(idx) = fg;

% Fill circle
img            = regionfill(im, crc(:,1), crc(:,2));
img(img ~= bg) = fg;

% Normalize input data to range in [0,1].
I    = img;
Xmin = min(I(:));
Xmax = max(I(:));
if isequal(Xmax,Xmin)
    I = 0 * I;
else
    I = (I - Xmin) ./ (Xmax - Xmin);
end

I = double(I);

end

function cmd = digitString(N, str)
%% A little trick to make sure concat has same digits as total
ndigs  = num2str(numel(num2str(N)));
dstr   = sprintf('%%0%sd', sprintf('%s', ndigs));
cmd    = sprintf('sprintf(''%s'', %s)', dstr, str);

end

