function F = trackingWhole(gimgs, gmids, npcts, varargin)
%% trackingWhole: tracking all points through all frames
%
% Usage:
%   F = trackingWhole(gimgs, gmids, npcts, varargin)
%
% Input:
%   gimgs:
%   gmids:
%   npcts: total points to track [default 61]
%   varargin: various options
%       ifrm: starting frame for tracking [default 1]
%       ffrm: ending frame for tracking [default []]
%       skp: frames to skip per tracking [default 1]
%       dsk: size of disk domain [default 12]
%       dres: resolution of disk domain [default 130]
%       symin: minimum stretch value [default 1.0]
%       symax: maximum stretch value [default 1.3]
%       itrs: max iterations for patternsearch [default 500]
%       tolf: termination tolerance function value [default 1e-8]
%       tolx: termination tolerance x-value [default 1e-8]
%       dlt: default distance (pix) to search from point [default 20]
%       eul: track using Lagrangian (0) or Eulerian (1) mode [default 1]
%
% Output:
%   F: tracked percentages and stretch values on target image

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%
ipcts = 0 : 1 / (npcts - 1) : 1;
if isempty(ffrm); nfrms = numel(gimgs); else; nfrms = numel(ifrm : ffrm); end
ppcts = cell(1, npcts);

%
tf = tic;
F  = cell(nfrms, npcts);
for frm1 = 1 : nfrms
    frm2 = frm1 + 1;
    isrc = gimgs{frm1};
    itrg = gimgs{frm2};
    msrc = gmids{frm1};
    mtrg = gmids{frm2};

    if par
        peul   = eul;
        pdsk   = dsk;
        pdres  = dres;
        pdlt   = dlt;
        psymax = symax;
        pitrs  = itrs;
        ptolf  = tolf;
        ptolx  = tolx;
        parfor pct = 1 : npcts
            % Initial percentages to evaluate first frame
            ipct = ipcts(pct);
            ppct = ppcts{pct};

            fprintf(['| Frame %d to %d of %02d | Point %02d of %02d | ' ...
                'eul %d | '], frm1, frm2, nfrms, pct, npcts, peul);
            F{frm1,pct} = trackMidline(isrc, itrg, msrc, mtrg, ...
                ipct, ppct, pdsk, pdres, pdlt, psymax, pitrs, ptolf, ptolx);
        end
    else
        for pct = 1 : npcts
            % Initial percentages to evaluate first frame
            ipct = ipcts(pct);
            ppct = ppcts{pct};

            fprintf(['| Frame %d to %d of %02d | Point %02d of %02d | ' ...
                'eul %d | '], frm1, frm2, nfrms, pct, npcts, eul);
            F{frm1,pct} = trackMidline(isrc, itrg, msrc, mtrg, ...
                ipct, ppct, dsk, dres, dlt, symax, itrs, tolf, tolx);
        end
    end

    % Set positions to point if Eulerian
    if ~eul
        ipcts = getDim(cat(1, F{frm1,:}),1)';
        if frm1 > 1
            ppcts = getDim(cat(1, F{frm1-1,:}),1)';
            ppcts = arrayfun(@(x) x, ppcts, 'UniformOutput', 0);
        end
    end

    fprintf('%s\n', sprB);
end

fprintf('Tracked %02d frames [%.02f min]\n%s\n', ...
    nfrms, mytoc(tf, 'min'), sprB);
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
% Required
p = inputParser;

% Main Parameters
p.addOptional('ifrm', 1);
p.addOptional('ffrm', []);
p.addOptional('skp', 1);
p.addOptional('dsk', 12);    % Size of disk domain
p.addOptional('dres', 130);  % Resolution for disk domain
p.addOptional('symin', 1.0); % Min stretch value
p.addOptional('symax', 1.3); % Max stretch value
p.addOptional('itrs', 500);  % Maximum iterations
p.addOptional('tolf', 1e-8); % Termination tolerance for function value
p.addOptional('tolx', 1e-8); % Termination tolerance for x-value
p.addOptional('dlt', 20);    % Default distance to set lower bound above point
p.addOptional('eul', 1);     % Eulerian (1) or Lagrangian (0)
p.addOptional('par', 0);     % Run in parallel

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end