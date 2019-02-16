function I  = makeToyData(N)
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
RAD = 20 : 40; % range for randomly chosen circle radii
XC  = 45 : 55; % range for x-coordinate centers of circle
YC  = 45 : 55; % range for y-coordinate centers of circle
ZC  = 20; % resolution of circle edge
CSZ = 21; % coordinates for contour

%% Function handles to get random index
m = @(x) randi([1 length(x)], 1); 
M = @(x) x(m(x));

%% Generate the CircuitJB array
C = repmat(CircuitJB, 1, N);
for n = 1 : N
    r = M(RAD);
    x = M(XC);
    y = M(YC);
    cnm  = sprintf('FakeCircle_c%d_r%d_x%d_y%d', n, r, x, y);
    C(n) = makeFakeCircle(cnm, ISZ, BG, FG, r, x, y, ZC, CSZ);
end

%% Process contours to generate Curve array [may take a long time]
arrayfun(@(x) x.CreateCurves(0), C, 'UniformOutput', 0);
D = arrayfun(@(x) x.Curves, C, 'UniformOutput', 0);
D = cat(1, D{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Show randomly-generated circle's grayscale and mask images
set(0, 'CurrentFigure', figs(1));
cla;clf;

c = M(C);
img = c.getImage.gray;
msk = c.getImage.bw;

subplot(211);
imshow(img,[]);

subplot(212);
imshow(msk,[]);

%% Show 25 random CircuitJB contours with their outlines
set(0, 'CurrentFigure', figs(2));
cla;clf;

q    = 1;
cIdx = sort(randperm(N, 25));
for c = cIdx    
    subplot(5, 5, q);
    hold on;    
    imagesc(C(c).getImage.gray);
    colormap gray;
    axis image;
    axis ij;
    plt(C(c).FullOutline, 'y-', 3);
    
    ttl = sprintf('%s', C(c).Origin);
    title(fixtitle(ttl));
    
    q = q + 1;
end

%% Run through a single contour's segments and patches
set(0, 'CurrentFigure', figs(3));
cla;clf;

c = M(C);
c.CreateCurves(1);
d = c.Curves;

subplot(122);
imagesc(c.getImage.gray);
hold on;

for p = 1 : d.NumberOfSegments
    subplot(121);
    imagesc(d.ImagePatches{p});
    axis image;
    axis ij;
    colormap gray;
    
    subplot(122);
    plt(d.RawSmooth(:,:,p), '-', 3);
    
    pause(0.01);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run contours through PCA pipelines [x-/y-/z-coordinates]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run PCA through CNN


end

function c = makeFakeCircle(cnm, isz, bg, fg, r, x, y, z, csz)
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
    I = 0*I;
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
cjb        = extractContour(imcomplement(msk), csz);
ctr        = cjb.InterpOutline;
ctr(end,:) = [];
c          = CircuitJB('Origin', cnm, 'RawOutline', ctr);
c.setImage(1, 'gray', img);
c.setImage(1, 'bw', msk);
c.ConvertRawOutlines;
c.ReconfigInterpOutline;

end