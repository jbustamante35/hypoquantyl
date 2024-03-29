function [T , lout] = trackingProcessor(finn, winn, npcts, varargin)
%% trackingProcessor: process tracking data
%
% Usage:
%   [T , lout] = trackingProcessor(ptrg, winn, ipcts, varargin)
%
% Input:
%   finn:
%   winn:
%   npcts:
%   varargin: various options
%       Parameter Options
%           smth: [default 1]
%           ltrp: [default 1000]
%           othr: [default 3]
%           vrng: [default 10]
%           fmax: [default 20]
%           ki: [default 0.007]
%           ni: [default 0.06]
%
%       Information Options
%           ExperimentName: [default 'experiment']
%           GenotypeName: [default 'genotype']
%           GenotypeIndex: [default 0]
%           SeedlingIndex: [default 0]
%
%       Visualization Options
%           kdir: [default 'tracking_results']
%           fidx: [default 0]
%           sav: [default 0]
%
% Output:
%   T: output structure containing processed and analyzed tracking data
%   lout: outliers from velocity percentages

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Split Percentages and Stretches and Coordinates
ptrg = cellfun(@(x) x(1), finn)';
strg = cellfun(@(x) x(2), finn)';
mcrd = cellfun(@(x) x(3:4), finn, 'UniformOutput', false)';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get source percentages from spots and convert to lengths along midline
nfrms = numel(winn) - 1;
ipcts = 0 : 1 / (npcts - 1) : 1;
psrc  = repmat(ipcts', 1, nfrms);
lsrc  = arrayfun(@(y) arrayfun(@(x) winn(y).calculatelength(psrc(x,y), 1), ...
    (1 : npcts)'), 1 : nfrms, 'UniformOutput', 0);
lsrc  = flipud(cat(2, lsrc{:}));
lsrc  = interpolateGrid(lsrc, 'fsmth', smth);

% Get target percentages from spots and convert to lengths along midline
% ptrg = interpolateGrid(ptrg, 'fsmth', smth);
% ptrg = [ipcts' , ptrg];
% ptrg = [zeros(1, nfrms + 1) ; ptrg(2 : end - 1, :) ; ones(1, nfrms + 1)];
ptrg = [zeros(1, nfrms) ; ptrg(2 : end - 1, :) ; ones(1, nfrms)];
ltrg = arrayfun(@(y) arrayfun(@(x) winn(y).calculatelength(ptrg(x,y-1), 1), ...
    (1 : npcts)'), 2 : nfrms + 1, 'UniformOutput', 0);
ltrg = flipud(cat(2, ltrg{:}));
ltrg = interpolateGrid(ltrg, 'fsmth', smth);

% Remove Outliers
[lsrc , osrc] = removePercentageOutliers(lsrc, ptrg, psrc, othr);
[ltrg , otrg] = removePercentageOutliers(ltrg, ptrg, psrc, othr);
lout          = {osrc , otrg};

% ---------------------------------------------------------------------------- %
%% Compute Velocity
ldif = ltrg - lsrc;
vels = arrayfun(@(t) [ltrg(:,t) , ldif(:,t)], 1 : nfrms, 'UniformOutput', 0);
vcat = arrayfun(@(x) [repmat(x, npcts, 1) , vels{x}], ...
    1 : nfrms, 'UniformOutput', 0)';
vcat = cat(1, vcat{:});

% ---------------------------------------------------------------------------- %
% Prep frame ranges and parameters
fshft = arrayfun(@(x) circshift(1 : nfrms, -x), 1 : nfrms, 'UniformOutput', 0)';
fshft = cellfun(@(x) x(1 : vrng), fshft, 'UniformOutput', 0);
fshft = [fshft(end) ; fshft(1:end-1)];

% Deal with problem of looping around back to start
ffix  = nfrms - vrng + 2 : nfrms;
% idxs  = cell2mat(cellfun(@(x) x < vrng, fshft(ffix), 'UniformOutput', 0));
% for i = 1 : numel(ffix); fshft{ffix(i)}(idxs(i,:)) = nfrms; end
fshft(ffix) = [];

% Positions, Velocities, and FLF Parameters
xpos = cellfun(@(y) cell2mat(arrayfun(@(x) vcat(vcat(:,1) == x, 2), ...
    y, 'UniformOutput', 0)'), fshft, 'UniformOutput', 0);
vpos = cellfun(@(y) cell2mat(arrayfun(@(x) vcat(vcat(:,1) == x, 3), ...
    y, 'UniformOutput', 0)'), fshft, 'UniformOutput', 0);
ppos = cellfun(@(v,x) [mean(v(end - fmax + 1 : end)) , ki , mean(x) , ni], ...
    vpos, xpos, 'UniformOutput', 0);
pbak = ppos;

% ---------------------------------------------------------------------------- %
%% Fit ranges of arclengths and velocities to FLF function
fout  = cell(numel(xpos), 1);
plist = zeros(numel(xpos), 4);

if fidx; figclr(fidx); end
for frm = 1 : numel(xpos)
    xv     = [xpos{frm} , vpos{frm}];
    tinn.X = xv(:,1);
    tinn.V = xv(:,2);

    ip           = ppos{frm};
    fout{frm}    = fitFLF(tinn, ip, vrb, nlc, lb, ub, tol);
    oparams      = fout{frm}.kiniPara;
    plist(frm,:) = oparams;

    if frm < numel(xpos); ppos{frm+1}([2 , 4]) = oparams([2 , 4]); end

    if fidx
        frms = fshft{frm};
        xfrm = linspace(0, max(xv(:,1)), max(xv(:,1)));
        vfrm = flf(xfrm, fout{frm}.kiniPara);
        ttl  = sprintf('%d [%d to %d]', frm, frms(1), frms(end));

        figclr(fidx,1);
        plt(xv, 'k.', 5);
        hold on;
        plt(vfrm, 'r-', 3);

        title(ttl, 'FontSize', 10);
        xlabel('L (arclength)', 'FontWeight', 'b');
        ylabel('V (aL/frm)', 'FontWeight', 'b');
        hold off;
        drawnow;
    end
end

% ---------------------------------------------------------------------------- %
%% Compute REGR and concatenate Velocities
X = cellfun(@(x) x.X, fout, 'UniformOutput', 0);
U = cellfun(@(x) x.kiniPara, fout, 'UniformOutput', 0);
F = cellfun(@(x,p) flf(linspace(0, max(x), ltrp), p), X, U, 'UniformOutput', 0);
V = cat(1, F{:})';
R = cellfun(@gradient, F, 'UniformOutput', 0);
R = cat(1, R{:})';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Store and save results
pstat.Experiment  = ExperimentName;
pstat.Genotype    = GenotypeName;
pstat.GenoIndex   = GenotypeIndex;
pstat.SeedIndex   = SeedlingIndex;
pstat.Frames      = nfrms;
pstat.Tracks      = npcts;

% Inputs and Parameters
pinn.Percentages = ipcts;
pinn.Window      = vrng;
pinn.Fmax        = fmax;
pinn.K           = ki;
pinn.N           = ni;
pinn.Pthresh     = othr;

% Output
pout.Misc.stretch  = strg; % Tracked Stretches
pout.Misc.coords   = mcrd; % Tracked Coordinates
pout.Percent.src   = psrc; % Source Percentages
pout.Percent.trg   = ptrg; % Tracked Percentages
pout.Arclength.src = lsrc; % Source Arclengths
pout.Arclength.trg = ltrg; % Tracked Arclengths
pout.Params        = U;    % Fit parameters to flf
pout.Profile       = vels; % Velocity per Arclength
pout.Velocity      = V;    % Velocity
pout.REGR          = R;    % REGR

T = struct('Data', pstat, 'Input', pinn, 'Output', pout);
if sav
    hdir = sprintf('%s/%s/%s', kdir, ExperimentName, GenotypeName);
    if ~isfolder(hdir); mkdir(hdir); end
    tnm  = sprintf(['%s/%s_trackingresults_%s_genotype%02d_%02dseedlings_' ...
        '%02dframes_%03dpoints_processed'], hdir, tdate, ...
        ExperimentName, GenotypeIndex, SeedlingIndex, nfrms, npcts);
    save(tnm, '-v7.3', 'T');
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% FLF Options
p.addOptional('nlc', 0);
p.addOptional('lb', [0 , 0    , -500  , 0]);
p.addOptional('ub', [6 , 0.05 , 200    , 0.5]);
p.addOptional('tol', [1e-12 , 1e-12]);

% Parameter Options
p.addOptional('smth', 1);
p.addOptional('ltrp', 1000);
p.addOptional('othr', 3);
p.addOptional('vrng', 10);
p.addOptional('fmax', 20);
p.addOptional('ki', 0.02);
p.addOptional('ni', 0.3);

% Information Options
p.addOptional('ExperimentName', 'experiment');
p.addOptional('GenotypeName', 'genotype');
p.addOptional('GenotypeIndex', 0);
p.addOptional('SeedlingIndex', 0);

% Visualization Options
p.addOptional('kdir', 'tracking_results');
p.addOptional('fidx', 0);
p.addOptional('vrb', 0);
p.addOptional('sav', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

function [ltrg , lout] = removePercentageOutliers(ltrg, ptrg, psrc, othr)
%% removePercentageOutliers: identify outliers from velocity percentages
if nargin < 3; othr = 3; end % Threshold for percentage outliers

pdif = ptrg - psrc;
lout = isoutlier(pdif(:), 'mean', 'ThresholdFactor', othr);
lout = reshape(lout, size(pdif));

ltrg(lout) = NaN;
ltrg       = fillmissing(ltrg, 'spline');
end
