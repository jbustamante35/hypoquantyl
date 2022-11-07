function [pout , pstat , pinn] = trackingProcessor(fa, tpt, w, ipcts, varargin)
%% trackingProcessor: process tracking data
%
%
% Usage:
%   [pout , pstat , pinn] = trackingProcessor(fa, tpt, w, ipcts, varargin)
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
            if iscell(fa{sidx})
                P(pidx,sidx).percent(hidx) = fa{sidx}{hidx,pidx}(1);
                P(pidx,sidx).stretch(hidx) = fa{sidx}{hidx,pidx}(2);
                P(pidx,sidx).tpt(hidx,:)   = tpt{sidx}{hidx,pidx};
            else
                P(pidx,sidx).percent(hidx) = fa{pidx,sidx}(hidx,1);
                P(pidx,sidx).stretch(hidx) = fa{pidx,sidx}(hidx,2);
                P(pidx,sidx).tpt(hidx,:)   = tpt{pidx,sidx}(hidx,:);
            end
        end
    end
end

%% Convert tracked percentages to arclength from tip of midline
ws = w(fwin,:);
wt = w(fwin + skp,:);

% Total length of midline per time
L  = arrayfun(@(x) x.calculatelength(0, 1), w);
Ls = arrayfun(@(x) smooth(L(:,x), smth), 1 : nsdls, 'UniformOutput', 0);
Li = cellfun(@(x) interpolateGrid(repmat(x',10,1), ftrp, 1)', ...
    Ls, 'UniformOutput', 0);

% ---------------------------------------------------------------------------- %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ArcLengths %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Raw arclength from tip of midline
plen = arrayfun(@(sidx) arrayfun(@(pidx) arrayfun(@(frm) ...
    wt(frm,sidx).calculatelength(P(pidx,sidx).percent(frm), 1), ...
    1 : nwin, 'UniformOutput', 0), ...
    1 : numel(ipcts), 'UniformOutput', 0), ...
    1 : nsdls, 'UniformOutput', 0);
plen = cat(1, plen{:});
plen = cellfun(@(x) cell2mat(x)', plen, 'UniformOutput', 0)';
plen = arrayfun(@(x) cat(2, plen{:,x}), 1 : nsdls, 'UniformOutput', 0);

% ---------------------------------------------------------------------------- %
%%%%%%%%%%%%%%%%%%%%%%%%%%% Velocity %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Velocities
vlen = arrayfun(@(x) measureVelocity(ws(:,x), plen{x}, ipcts, 1), ...
    1 : nsdls, 'UniformOutput', 0);

% ---------------------------------------------------------------------------- %
%%%%%%%%%%%%%%%%%% Repair Arclengths and Velocities %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Find and repair frames with bad arclengths
nidxs = cellfun(@(x) findBadArclengths(x(:,1), nwin), plen, 'UniformOutput', 0);
prep  = cellfun(@(p,n) repairBadArclengths(p',n), ...
    plen, nidxs, 'UniformOutput', 0);
vrep  = cellfun(@(p,n) repairBadArclengths(p',n), ...
    vlen, nidxs, 'UniformOutput', 0);

% ---------------------------------------------------------------------------- %
%%%%%%%%%%%%%%%%%%%%%%%% Velocity Profile %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Velocity profiles
rlen = cellfun(@(py,vy) arrayfun(@(x) [py(x,:) ; vy(x,:)]', ...
    1 : nwin, 'UniformOutput', 0)', plen, vlen, 'UniformOutput', 0);
rrep = cellfun(@(py,vy) arrayfun(@(x) [py(x,:) ; vy(x,:)]', ...
    1 : nwin, 'UniformOutput', 0)', prep, vrep, 'UniformOutput', 0);

% ---------------------------------------------------------------------------- %
%%%%%%%%%%%%%%%%%%%% Relative Elemental Growth Rate %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% REGR
plen = cellfun(@(x) flipud(x'), plen, 'UniformOutput', 0);
prep = cellfun(@(x) flipud(x'), prep, 'UniformOutput', 0);
vlen = cellfun(@(x) flipud(x'), vlen, 'UniformOutput', 0);
vrep = cellfun(@(x) flipud(x'), vrep, 'UniformOutput', 0);
llen          = cellfun(@(x) interpolateGrid(x, ...
    'xtrp', ftrp, 'ytrp', ltrp, 'fsmth', smth), plen, 'UniformOutput', 0);
lrep          = cellfun(@(x) interpolateGrid(x, ...
    'xtrp', ftrp, 'ytrp', ltrp, 'fsmth', smth), prep, 'UniformOutput', 0);
[elen , tlen] = cellfun(@(x) measureREGR(x, ...
    'xtrp', ftrp, 'ytrp', ltrp, 'fsmth', smth), vlen, 'UniformOutput', 0);
[erep , trep] = cellfun(@(x) measureREGR(x, ...
    'xtrp', ftrp, 'ytrp', ltrp, 'fsmth', smth), vrep, 'UniformOutput', 0);

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
pout.Tracking.ilens    = Li;   % Interpolated midline lengths

pout.Arclength.raw    = plen; % Raw arclengths
pout.Arclength.rep    = prep; % Repaired arclengths
pout.Arclength.lraw   = llen; % Raw interpolated arclengths
pout.Arclength.lrep   = lrep; % Repaired interpolated arclengths

pout.Velocity.raw     = vlen; % Raw velocities
pout.Velocity.rep     = vrep; % Repaired velocities
pout.Velocity.traw    = tlen; % Raw interpolated velocities
pout.Velocity.trep    = trep; % Repaired interpolated velocities

pout.Profile.raw      = rlen; % Raw velocity per arclength
pout.Profile.rep      = rrep; % Repaired velocity per arclength

pout.REGR.raw         = elen; % Raw interpolated EGR
pout.REGR.rep         = erep; % Repaired interpolated EGR

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
p.addOptional('ftrp', 500);
p.addOptional('ltrp', 1000);

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

function [nidxs , nchk] = findBadArclengths(Ls, nwin, lthrsh)
%% findBadArclengths: identify frames with problem arc lengths
if nargin < 3; lthrsh = 10; end % Threshold for arclength drop

% Find problem frames
nchk  = true(1, nwin);
nchks = numel(nchk) - 1;
for ncur = 1 : nchks
    % Check if comparison should be made
    if nchk(ncur)
        nnxt = ncur + 1;
        lcur = Ls(ncur);
        lnxt = Ls(nnxt);
        lchk = lcur < (lnxt - lthrsh);

        % Check if current length < next length
        if ~lchk
            % Current length < than next length, check length after next and
            % mark each bad length false
            while ~lchk
                nchk(nnxt) = false;
                nnxt       = nnxt + 1;

                % Stop if at last frame
                if nnxt > nchks; break; end
                lnxt = Ls(nnxt);
                lchk = lcur < lnxt;
            end
        end
    end
end

% Adjust position to be 1 frame back [arclength value is from bad frame]
nchk(end) = true; % Last frame is always good
nidxs     = find(nchk);
rr        = regionprops(nchk, 'PixelIdxList');
for e = 1 : numel(rr)
    tmpi = rr(e).PixelIdxList(1);
    if tmpi > 1; nchk(tmpi - 1) = true; end
end
end

function aout = repairBadArclengths(ainn, nidxs)
%% repairBadArclengths
% ainn  = cat(2, Ainn{:})';
nfrms = size(ainn,2);
frms  = 1 : nfrms;
fnc   = @(xi) interp1(frms(nidxs)', ainn(:,nidxs)', xi, 'linear');
aout  = fnc(frms);
end
