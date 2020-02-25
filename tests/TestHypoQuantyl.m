function e = TestHypoQuantyl(p, r, a, z, l, c, v)
%% TestHypoQuantyl: perform test runs of HypoQuantyl
% This function
%
% Usage:
%   e = TestHypoQuantyl(r, a, z, l, c, v)
%
% Input:
%   p: path to directory of time-lapse data
%   r: number of randomly-selected folders to run
%   a: first frame to add Seedlings
%   z: last frame to add Seedlings
%   l: length for cropping out Hypocotyls from Seedlings
%   c: [2 x 1] array to set rescale size to normalize Hypocotyl images
%   v: visualize data at the end of analysis
%
% Output:
%   e: full Experiment after analysis
%

%% Commands for some set-up parameters [comment out before running]
% d = dir;
% d(1:2) = [];
% r = numel(d);
% a = 1;
% z = 70;
% c = [101 101];
% v = 1;

%% Create Experiment in current directory
%e      = Experiment(p);
e      = Experiment('ExperimentPath', p);
[d, ~] = sortDirectory(p);
d      = table2struct(d);
dIdx   = randperm(numel(d), r);
d      = d(dIdx);

%% Add Genotypes and Seedlings for each subfolder in current directory
for i = 1 : length(d)
    tic;
    fprintf('Analyzing %s...', d(i).name);
    e.AddGenotypes(d(i), '*', 'date', 0);

    g = e.getGenotype(i);
    fprintf('Loading images...');
    if z < g.TotalImages
        g.AddSeedlingsFromRange(a:z, l);
    else
        g.AddSeedlingsFromRange(a:g.TotalImages, l);
    end

    fprintf('Loaded %d images. Aligning Seedlings through each frame...', ...
        g.TotalImages);
    g.SortSeedlings;

    format shortg;
    fprintf('%.02f sec to analyze %d frames from %d Seedlings \n', ...
        toc,                z,              g.NumberOfSeedlings);
end

%% Iterate through all Genotypes and all Seedlings to find Hypocotyls
for i = 1 : e.NumberOfGenotypes
    tic;
    g = e.getGenotype(i);
    fprintf('Finding Hypocotyl from %s=>', g.getGenotypeName);
    for ii = 1 : g.NumberOfSeedlings
        s = g.getSeedling(ii);
        for iii = 1 : s.getLifetime
            s.FindHypocotyl(iii, c);
            s.RemoveBadFrames;
        end
        fprintf('|%s|', s.getSeedlingName);
    end
    fprintf('%.02f sec to find hypocotyls from %d frames \n', ...
        toc,                        s.getLifetime);
end

%% S

%% Visualize various output images to verify data
if v
    %% View all RawImages
    for i = 1 : e.NumberOfGenotypes
        figure;
        g = e.getGenotype(i);
        for ii = 1 : g.TotalImages
            imagesc(g.getImage(ii));
            colormap gray, axis image;
            txt = 'Genotype %d Frame %d';
            title(sprintf(txt, i, ii));

            drawnow;
        end
    end


    %% View all Seedlings
    for i = 1 : e.NumberOfGenotypes
        figure;
        g    = e.getGenotype(i);
        numS = g.NumberOfSeedlings;
        maxL = max(cat(1,g.getSeedling(':').Lifetime));

        for ii = 1 : maxL
            for iii = 1 : numS
                s = g.getSeedling(iii);
                if ii <= s.getLifetime
                    subplot(1, numS, iii);
                    imagesc(s.getImage(ii, 'gray'));
                    colormap gray, axis image;
                    txt = 'Seedling %d Frame %d';
                    title(sprintf(txt, iii, ii));

                    drawnow;
                end
            end
        end
    end

    %% View all hypocotyls with marked AnchorPoints

    figure;
    for i = 1 : e.NumberOfGenotypes
        g = e.getGenotype(i);
        for ii = 1 : g.NumberOfSeedlings
            s = g.getSeedling(ii);
            for iii = 1 : s.getLifetime
                pts = s.getAnchorPoints(iii);
                img = s.getImage(iii, 'gray');
                imagesc(img);
                colormap gray, axis image;
                txt = 'Genotype %d Seedling %d Frame %d';
                title(sprintf(txt, i, ii, iii));

                hold on;

                plot(pts(1,1), pts(1,2), 'bx'); % a
                plot(pts(2,1), pts(2,2), 'rx'); % b
                plot(pts(3,1), pts(3,2), 'gx'); % c
                plot(pts(4,1), pts(4,2), 'mx'); % d

                drawnow;
                hold off;
            end
        end
    end

    %% View All PreHypocotyls
    figure;
    for i = 1 : e.NumberOfGenotypes
        g = e.getGenotype(i);
        for ii = 1 : g.NumberOfSeedlings
            s = g.getSeedling(ii);
            for iii = 1 : s.getLifetime
                h = s.getPreHypocotyl(iii);
                imagesc(h.getImage('gray'));
                colormap gray, axis image;
                txt = 'Genotype %d Seedling %d Frame %d';
                title(sprintf(txt, i, ii, iii));
                drawnow;
            end
        end
    end

end

end


function NotInFunctionA
%% For presentation purposes
n = 2;
m = 1;
t1 = 3;
t2 = 2;

%% Repeat same Seedling
for i = 1 : t1
    TestStuffHere(e, n, m, 0);
end

%% All Seedlings
for i = 1 : t2
    for i = 1 : e.NumberOfGenotypes
        g = e.getGenotype(i);
        for j = 1 : g.NumberOfSeedlings
            s = g.getSeedling(j);
            TestStuffHere(e, i, j, 0);
        end
    end
end

%%
g = e.getGenotype(n);
im = g.getAllImages;
ss = g.getSeedling(':');
crds = {ss.Coordinates};
for i = 1 : t1
    for i = 1 : numel(im)
        imagesc(im{i}), colormap gray, axis image;
        hold on;
        cellfun(@(x) plot(x(:,1), x(:,2), '.'), crds, 'UniformOutput', 0);
        drawnow;
        hold off;
    end
end


end

