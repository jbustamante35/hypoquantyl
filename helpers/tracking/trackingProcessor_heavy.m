function [pout , pstat , pinn] = trackingProcessor_heavy(fa, tpt, w, ipcts, varargin)
%% trackingProcessor_heavy: heavier alternative to process tracking data
%
%
% Usage:
%   [pout , pstat , pinn] = trackingProcessor_heavy(fa, tpt, w, ipcts, varargin)
%
% Input:
%   fa:
%   tpa:
%   w:
%   ipcts:
%   varargin: various options
%       smth: smoothing parameter for length and velocity profiles
%       pintrp: interpolation size for percentages along midlines
%       fin: cell array of image file paths to images
%       gmids: raw midline inputs
%
% Output:
%   pout: output structure containing processed and analyzed tracking data
%   pstat: metadata and information about tracking inputs
%   pinn: input structure with images and midlines [optional]
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
[nfrms , nsdls] = size(w);
if isempty(ifrm); ifrm = 1; ffrm = nfrms - 1; end
fwin  = ifrm : skp : ffrm;
nwin  = numel(fwin);
npcts = numel(ipcts);

P = repmat(struct(), npcts, nsdls);
for sidx = 1 : nsdls
    for pidx = 1 : npcts
        for hidx = 1 : nwin
            P(pidx,sidx).percent(hidx) = fa{sidx}{hidx,pidx}(1);
            P(pidx,sidx).stretch(hidx) = fa{sidx}{hidx,pidx}(2);
            P(pidx,sidx).tpt(hidx,:)   = tpt{sidx}{hidx,pidx};
        end
    end
end

%% Convert tracked percentages to arclength from tip of midline
ws = w(fwin,:);
wt = w(fwin + skp,:);

% Arclength from initial positions at each time
% p0 = arrayfun(@(y) arrayfun(@(x) ws(1,x).calculatelength(y, 1), ...
%     1 : nsdls, 'UniformOutput', 0), ipcts, 'UniformOutput', 0);
% p0 = cat(1, p0{:});

% Total length of midline per time
L  = arrayfun(@(x) x.calculatelength(0, 1), w);
Ls = arrayfun(@(x) smooth(L(:,x), smth), 1 : nsdls, 'UniformOutput', 0);

% ---------------------------------------------------------------------------- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ArcLengths %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Raw arclength from tip of midline
plen = arrayfun(@(sidx) arrayfun(@(pidx) arrayfun(@(frm) ...
    wt(frm,sidx).calculatelength(P(pidx,sidx).percent(frm), 1), ...
    1 : nwin, 'UniformOutput', 0), ...
    1 : numel(ipcts), 'UniformOutput', 0), ...
    1 : nsdls, 'UniformOutput', 0);
plen = cat(1, plen{:});
plen = cellfun(@(x) cell2mat(x)', plen, 'UniformOutput', 0)';
% plen = cellfun(@(x,y) [x ; y], p0, plen, 'UniformOutput', 0);

% Interpolate arclength
if nintrp
    iints  = 0 : 1 / nintrp : 1;
    pintrp = numel(iints);
    pint   = arrayfun(@(x) cat(2, plen{:,x}), 1 : nsdls, 'UniformOutput', 0);
    pint   = cellfun(@(x) imresize(x, [nwin , pintrp]), pint, 'UniformOutput', 0);
    pint   = cellfun(@(y) arrayfun(@(x) y(:,x), ...
        1 : pintrp, 'UniformOutput', 0)', pint, 'UniformOutput', 0);
    pint   = cat(2, pint{:});
else
    pint = plen;
end

% Smooth original and Interpolated arclengths
psmt = cellfun(@(x) smooth(x, smth), plen, 'UniformOutput', 0);
pism = cellfun(@(x) smooth(x, smth), pint, 'UniformOutput', 0);

% ---------------------------------------------------------------------------- %
%%%%%%%%%%%%%%%%%%%%%%%%%%% Velocity Profile %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Velocities: Raw and Smoothed , Original and Interpolated
% For whole tracking
vlen = arrayfun(@(x) measureVelocity(ws(:,x), cat(2, plen{:,x}), ipcts), ...
    1 : nsdls, 'UniformOutput', 0);
vsmt = arrayfun(@(x) measureVelocity(ws(:,x), cat(2, psmt{:,x}), ipcts), ...
    1 : nsdls, 'UniformOutput', 0);
vint = arrayfun(@(x) measureVelocity(ws(:,x), cat(2, pint{:,x}), iints), ...
    1 : nsdls, 'UniformOutput', 0);
vism = arrayfun(@(x) measureVelocity(ws(:,x), cat(2, pism{:,x}), iints), ...
    1 : nsdls, 'UniformOutput', 0);
vlen = cat(2, vlen{:});
vsmt = cat(2, vsmt{:});
vint = cat(2, vint{:});
vism = cat(2, vism{:});

% For point tracking
% vlen = cellfun(@(x) gradient(x), plen, 'UniformOutput', 0);
% vsmt = cellfun(@(x) gradient(x), psmt, 'UniformOutput', 0);
% vint = cellfun(@(x) gradient(x), pint, 'UniformOutput', 0);
% vism = cellfun(@(x) gradient(x), pism, 'UniformOutput', 0);

% ---------------------------------------------------------------------------- %
%%%%%%%%%%%%%%%%%%%%%%%% Velocity per Time %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% For each frame, show velocity at each location
% Original and Interpolated velocity profiles
vprf = cellfun(@(p,v) [p , v], psmt, vsmt, 'UniformOutput', 0);
vpsm = cellfun(@(p,v) [p , v], pism, vism, 'UniformOutput', 0);

% ---------------------------------------------------------------------------- %
%%%%%%%%%%%%%%%%%%%% Relative Elemental Growth Rate %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% REGR



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Store and save results
pinn.ImagePath = FIN;   % Store paths to images
pinn.Mids      = GMIDS; % Store raw midlines

pstat.Experiment  = ExperimentName;
pstat.Genotype    = GenotypeName;
pstat.GenoIndex   = GenotypeIndex;
pstat.Seedlings   = nsdls;
pstat.Frames      = nfrms;
pstat.Window      = fwin;
pstat.Percentages = ipcts;

pout.Tracking.raw      = P;    % Tracking Data
pout.Tracking.lengths  = Ls;   % Full midline lengths
pout.Arclength.raw     = plen; % Raw arclengths
pout.Arclength.rsmooth = psmt; % Smoothed arclengths
pout.Arclength.interp  = pint; % Interpolated arclengths
pout.Arclength.ismooth = pism; % Smoothed Interpolatd arclengths
pout.Velocity.raw      = vlen; % Raw velocities
pout.Velocity.rsmooth  = vsmt; % Smoothed velocities
pout.Velocity.interp   = vint; % Interpolated velocities
pout.Velocity.ismooth  = vism; % Smoothed Interpolatd velocities
pout.Profile.raw       = vprf; % Raw velocity per arclength
pout.Profile.interp    = vpsm; % Interpolated velocity per arclength

T = struct('Data', pstat, 'Input', pinn, 'Output', pout);
if nargout == 1; pout = T; end
if sav
    hdir = sprintf('tracking_results/%s/%s', ExperimentName, GenotypeName);
    if ~isfolder(hdir); mkdir(hdir); end
    tnm  = sprintf('%s/%s_trackingresults_%s_genotype%02d_%02dseedlings_%02dframes_%03dpoints', ...
        hdir, tdate, GenotypeName, GenotypeIndex, nsdls, nfrms, npcts);
    save(tnm, '-v7.3', 'T');
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Misc Options
p.addOptional('ifrm', []);
p.addOptional('ffrm', []);
p.addOptional('skp', 1);
p.addOptional('smth', 1);
p.addOptional('nintrp', 0);

% Information Options
p.addOptional('ExperimentName', 'experiment');
p.addOptional('GenotypeName', 'genotype');
p.addOptional('GenotypeIndex', 0);
p.addOptional('FIN', []);
p.addOptional('GMIDS', []);

% Visualization Options
p.addParameter('sav', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
