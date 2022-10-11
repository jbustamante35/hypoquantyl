function [icnvs , hmeans , chists , cimgs] = histogramNormalizationHQ(imgs, nbins, inrms, smth, v)
%% histogramNormalizationHQ: histogram normalization method for HypoQuantyl
% Averaged histogram normalization
% i)   Take histograms of all N images
% ii)  Iterative normalization of N images to each N image
% iii) Covert all NxN images to histograms
% iv)  Row-mean of all histograms to obtain N averaged histograms
% v)   Convert averaged histograms to images
% vi)  Repeat from step ii using N averaged histograms obtained from step iv
%      instead of the original histograms [repeat recursively r times]
%
% Usage:
%   [icnvs , hmeans , chists , cimgs] = ...
%       histogramNormalizationHQ(imgs, nbins, inrms, smth, v)
%
% Input:
%   imgs: grayscale images of dataset
%   nbins: number of bins for histograms [default 256]
%   inrms: base images to normalize to (for recursive iterations)
%   smth: disk size to smooth before taking mean [default 0]
%   v: level of verbosity (0 none, 1 some, 2 full) [default 1]
%
% Output:
%   icnvs: normalized averaged histograms converted to images
%   hmeans: normalized averaged histograms
%   chists: histograms from iteratively normalized images
%   cimgs: iteratively normalized images
%

%%
if nargin < 2; nbins = 256; end
if nargin < 3; inrms = [];  end
if nargin < 4; smth  = 0;   end
if nargin < 5; v     = 2;   end

%%
[~ , sprA , sprB] = jprintf(' ', 0, 0, 80);

tHist = tic;
fprintf('\n\n%s\n\n\t\t\t\tHistogram Normalization\n\n%s\n', sprA, sprA);

nimgs = numel(imgs);
wbins = 0 : nbins;

to = tic;
n  = fprintf('Normalizing %d images with histograms of %d bins', ...
    nimgs, nbins);

% Function Handles
% fx  = @(x) arrayfun(@(y) sum(x == y, 'all'), 1 : nbins); % Counts for each bin
% ff  = @(x) fx(x) / sum(fx(x));                           % Probability of histogram
ff  = @(x)   histcounts(x, 1 : nbins + 1, 'Normalization', 'probability'); % Probability of histogram
fg  = @(x,r) imhistmatch(x, r, 'Method', 'polynomial');                    % Normalize to histogram
h2i = @(x)   hist2image(x, wbins);                                         % Convert histogram to image

jprintf('', toc(to), 1, 80 - n);

%% ii)  Iterative normalization of N images to each N image
ti    = tic;
n     = fprintf('Starting Iterative normalization');

cimgs = cell(nimgs,nimgs);

jprintf('', toc(ti), 1, 80 - n);

% Reference with original images (default) or normalized averaged images
ti = tic;
if isempty(inrms)
    n     = fprintf('Referencing with original images');
    inrms = imgs;
else
    n = fprintf('Referencing with pre-normalized images');
end
jprintf('', toc(ti), 1, 80 - n);

% Iteratively normalize all images with each reference image
tcmp = tic;
fprintf('%s\n\n\t\tIterative normalization of %d images\n', sprA, nimgs);
for n = 1 : nimgs
    tn = tic;
    if v == 2
        fprintf('\n%s\n\t\t\t\t\t%03d of %03d\n%s\n', sprB, n, nimgs, sprB);
    end

    iref = uint8(inrms{n});
    for nn = 1 : nimgs
        icmp        = imgs{nn};
        cimgs{n,nn} = fg(icmp,iref);
        if v == 2; fprintf('%03d | ', nn); end
    end
    
    switch v
        case 0
        case 1
            if mod(n,10) == 0; fprintf('|'); else; fprintf('.'); end
        case 2
            fprintf('DONE! [%.03f sec]', toc(tn));
    end
end

ncmgs = numel(cimgs);

fprintf('\n%s\nDone normalizing %d histograms to %d images [%.03f sec]\n', ...
    sprA, nimgs, ncmgs, toc(tcmp));

%% iii) Covert all NxN images to histograms
ti     = tic;
n      = fprintf('Generating histograms for %d normalized images', ncmgs);
chists = cell(size(cimgs));

jprintf('', toc(ti), 1, 80 - n);

tcmp = tic;
fprintf('%s\n\n\t\tNormalizing %d images to histograms\n', sprA, nimgs);
for n = 1 : nimgs
    tn = tic;
    if v == 2
        fprintf('\n%s\n\t\t\t\t\t%03d of %03d\n%s\n', sprB, n, nimgs, sprB);
    end

    for nn = 1 : nimgs
        cimg         = cimgs{n,nn};
        chists{n,nn} = ff(cimg);
        if v == 2; fprintf('%03d | ', nn); end
    end

    switch v
        case 0
        case 1
            if mod(n,10) == 0; fprintf('|'); else; fprintf('.'); end
        case 2
            fprintf('DONE! [%.03f sec]', toc(tn));
    end
end

nhists = numel(chists);

fprintf('\n%s\nDone normalizing %d images to %d histograms [%.03f sec]\n', ...
    sprA, nimgs, ncmgs, toc(tcmp));

% ---------------- Vizualize with showHistogramNormalization ----------------- %

%% iv)  Row-mean of all histograms to obtain N averaged histograms
ti = tic;
n  = fprintf('Getting mean histogram of %d images [smooth = %d]', nhists, smth);

% Smooth before taking mean
hcat = arrayfun(@(x) cat(1,  chists{x,:}), ...
    1 : nimgs, 'UniformOutput', 0)';
if smth
    dsk  = fspecial('disk', smth);
    hcat = cellfun(@(x) imfilter(x, dsk), ...
        hcat, 'UniformOutput', 0);
end

hmeans = cellfun(@mean, hcat, 'UniformOutput', 0);
nmeans = numel(hmeans);

jprintf('', toc(ti), 1, 80 - n);

% ----------------------- Vizualize with showRowMeans ------------------------ %

%% v) Convert averaged histograms to images
ti = tic;
n  = fprintf('Converting %d histograms to images', nmeans);

icnvs = cellfun(@(x) uint8(h2i(x)), hmeans, 'UniformOutput', 0);

jprintf('', toc(ti), 1, 80 - n);

fprintf('%s\n\n\t\t\t\t\tFINSHED NORMALIZING %d IMAGES [%.03f sec]\n\n%s\n\n', ...
    sprA, nimgs, toc(tHist), sprA);
end