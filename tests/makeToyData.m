function [C, D] = makeToyData(N, sav, par)
%% makeToyData: generate fake dataset for HypoQuantyl pipeline
% description
%
% From a really quick check of pixel intensities, I got a general idea of some
% background and foreground values to use for the fake images:
%   Background: 90
%   Foreground: 42
%
%
% Usage:
%
%
% Input:
%
%
% Output:
%
%

%% Constants
ISZ = [101 101];
BG  = 90; % average background intensity
FG  = 42; % average foreground intensity
RAD = 15 : 35; % range for randomly chosen circle radii
XC  = 45 : 55; % range for x-coordinate centers of circle
YC  = 45 : 55; % range for y-coordinate centers of circle
ZC  = 20; % resolution of circle edge
CSZ = 21; % coordinates for contour

% Function handles to get random indices
m = @(x) randi([1 length(x)], 1);
M = @(x) x(m(x));

% Misc
sprA = repmat('=', 1, 80);
sprB = repmat('-', 1, 80);

tAll = tic;
fprintf('\n%s\nGenerating simulated dataset of %d circles\n%s\n', sprA, N, sprB);

%% Generate the CircuitJB array
t = tic;
fprintf('Generating CircuitJB array [ RAD(%d, %d) | XC(%d, %d) | YC(%d, %d) ]...\n', ...
    min(RAD), max(RAD), min(XC), max(XC), min(YC), max(YC));

D = repmat(CircuitJB, 1, N);
if par
    % Run with parallel-processing
    D = num2cell(D);
    parfor n = 1 : N
        r = M(RAD);
        x = M(XC);
        y = M(YC);
        cnm  = sprintf('HardCircle_c%d_r%d_x%d_y%d', n, r, x, y);
        fprintf('Circle %03d | Radius %d | x %d | y %d\n', n, r, x, y);
        D{n} = makeFakeCircle(cnm, ISZ, BG, FG, r, x, y, ZC, CSZ);
    end
    D = cat(1, D{:});
else
    % Run on single-thread    
    for n = 1 : N
        r = M(RAD);
        x = M(XC);
        y = M(YC);
        cnm  = sprintf('HardCircle_c%d_r%d_x%d_y%d', n, r, x, y);
        fprintf('Circle %03d | Radius %d | x %d | y %d\n', n, r, x, y);
        D(n) = makeFakeCircle(cnm, ISZ, BG, FG, r, x, y, ZC, CSZ);
    end
end

fprintf('DONE! [%.02f sec]\n', toc(t));

%% Process contours to generate Curve array [may take a long time]
t = tic;
fprintf('Creating %d Curve objects from CircuitJB parents...', N);

arrayfun(@(x) x.CreateCurves('redo', par), D, 'UniformOutput', 0);
C = arrayfun(@(x) x.Curves, D, 'UniformOutput', 0);
C = cat(1, C{:});

fprintf('\nDONE! [%.02f sec]\n', toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save data
if sav
    t = tic;
    fprintf('Saving data for %d Curves...', N);
    fnm = sprintf('%s_HardCircles_%03dCurves', tdate, N);
    save(fnm, '-v7.3', 'C');
    fprintf('DONE! [%.02f sec]\n', toc(t));
end

%
fprintf('%s\nFinished generating %d circles [%.02f sec]\n%s\n', ...
    sprB, N, toc(tAll), sprA);

end

function d = makeFakeCircle(cnm, isz, bg, fg, r, x, y, z, csz)
%% makeFakeCircle: generate fake CircuitJB object
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

% Threshold image - global threshold
bw = imbinarize(I);

% Create masked image.
maskedImage      = I;
maskedImage(~bw) = 0;
msk              = maskedImage;

%% Make CircuitJB and Curve objects from contours
cjb              = extractContour(imcomplement(msk), csz);
ctr              = cjb.InterpOutline;
ctr(end,:)       = [];
d                = CircuitJB('Origin', cnm, 'RawOutline', ctr);
d.ExperimentName = 'HardCircles';
d.setImage(1, 'gray', img);
% d.setImage(1, 'bw', msk);
d.ConvertRawOutlines;
d.ReconfigInterpOutline;

end
