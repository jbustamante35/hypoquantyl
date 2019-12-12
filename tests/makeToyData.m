function [C, D, figs] = makeToyData(N, vis, sav)
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
fprintf('Generating CircuitJB array [ RAD(%d, %d) | XC(%d, %d) | YC(%d, %d) ]...', ...
    min(RAD), max(RAD), min(XC), max(XC), min(YC), max(YC));

C = repmat(CircuitJB, 1, N);
for n = 1 : N
    r = M(RAD);
    x = M(XC);
    y = M(YC);
    cnm  = sprintf('FakeCircle_c%d_r%d_x%d_y%d', n, r, x, y);
    C(n) = makeFakeCircle(cnm, ISZ, BG, FG, r, x, y, ZC, CSZ);
end

fprintf('DONE! [%.02f sec]\n', toc(t));

%% Process contours to generate Curve array [may take a long time]
t = tic;
fprintf('Creating %d Curve objects from CircuitJB parents...', N);

arrayfun(@(x) x.CreateCurves('redo', 0), C, 'UniformOutput', 0);
D = arrayfun(@(x) x.Curves, C, 'UniformOutput', 0);
D = cat(1, D{:});

fprintf('\nDONE! [%.02f sec]\n', toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Visualize data
if vis
    t = tic;
    fprintf('Visualizing dataset...');
    
    nf   = 3;
    figs = 1 : nf;
    fnms = cell(1, nf);
    
    for n = 1 : nf
        figs(n) = figure(n);
        fnms{n} = sprintf('%s_blank', tdate('s'));
    end
    
    %% Show randomly-generated circle's grayscale and overlay with contour
    set(0, 'CurrentFigure', figs(1));
    cla;clf;
    
    cIdx = m(C);
    c    = C(cIdx);
    img  = c.getHardImage('gray');
    crds = c.FullOutline;
    
    hold on;
    myimagesc(img);
    plt(crds, 'g-', 2);
    
    ttl = sprintf('Circle %03d of %03d (image)', cIdx, N);
    title(ttl, 'FontSize', 8);
    
    fnms{1} = sprintf('%s_CircleData_ContourOnMask%03d', tdate, cIdx);
    
    %% Show contours with their outlines
    set(0, 'CurrentFigure', figs(2));
    cla;clf;
    
    try
        cIdxs = sort(randperm(N, 25));
    catch
        cIdxs = 1 : N;
    end
    
    q    = 1;
    rows = ceil(numel(cIdxs) / 5);
    cols = ceil(numel(cIdxs) / rows);
    
    for ci = cIdxs
        
        subplot(rows, cols, q);
        hold on;
        myimagesc(C(ci).getHardImage('gray'));
        plt(C(ci).FullOutline, 'y-', 3);
        
        ttl = sprintf('%s', C(ci).Origin);
        title(fixtitle(ttl), 'FontSize', 8);
        
        q = q + 1;
    end
    
    fnms{2} = sprintf('%s_CircleData_%dCircleGallery', tdate, N);
    
    %% Run through a single contour's segments and patches
    if isempty(c.Curves)
        c.CreateCurves('redo', 0);
    end
    
    % Curve data
    d    = c.Curves;
    segs = d.getSegmentedOutline;
    zp   = d.getZPatch;
    z    = d.getZVector;
    
    % Plotting properties
    scl   = 8;
    mid   = z(:,1:2);
    tng   = scl * z(:,3:4) + mid;
    nrm   = scl * z(:,5:6) + mid;
    nSegs = d.NumberOfSegments;
    skp   = 3;
    
    for p = 1 : skp : nSegs
        set(0, 'CurrentFigure', figs(3));
        cla;clf;
        
        subplot(121);
        myimagesc(zp{p});
        ttl = sprintf('Z-Patch Image %03d of %03d\nSegment %03d of %03d', ...
            cIdx, N, p, nSegs);
        title(ttl);
        
        subplot(122);
        hold on;
        myimagesc(c.getHardImage('gray'));
        plt(segs(:,:,p), 'g-', 3);
        plt(mid(p,:), 'y.', 8);
        plt([mid(p,:) ; tng(p,:)], 'r-', 2);
        plt([mid(p,:) ; nrm(p,:)], 'b-', 2);
        
        ttl = sprintf('Z-Patch Overlay %03d of %03d\nSegment %03d of %03d', ...
            cIdx, N, p, nSegs);
        title(ttl);
        
        drawnow;
        
    end
    
    fnms{3} = sprintf('%s_CircleData_PatchesAndSegments%03d', tdate, cIdx);
    
    %% Save figures as .tiff images
    if sav
        for fig = figs
            saveas(figs(fig), fnms{fig}, 'tiffn');
        end
    end
    
    fprintf('DONE! [%.02f sec]\n', toc(t));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save data
if sav
    t = tic;
    fprintf('Saving data for %d Curves...', N);
    fnm = sprintf('%s_FakeCircles_%03dCurves', tdate, N);
    save(fnm, '-v7.3', 'C');
    fprintf('DONE! [%.02f sec]\n', toc(t));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run contours through PCA pipelines [x-/y-/z-coordinates]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run PCA through CNN

%
fprintf('%s\nFinished generating %d circles [%.02f sec]\n%s\n', ...
    sprB, N, toc(tAll), sprA);

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
cjb        = extractContour(imcomplement(msk), csz);
ctr        = cjb.InterpOutline;
ctr(end,:) = [];
c          = CircuitJB('Origin', cnm, 'RawOutline', ctr);
c.setImage(1, 'gray', img);
c.setImage(1, 'bw', msk);
c.ConvertRawOutlines;
c.ReconfigInterpOutline;

end
