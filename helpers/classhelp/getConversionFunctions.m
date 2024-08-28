function [funcs , dats] = getConversionFunctions(X, varargin)
%% getConversionFunctions: get function handles to convert lengths and times
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

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

% Get function handles
f2h        = 1 / frm_per_hr;
mm2pix     = @(p,i) round((p * pix_per_mm), i);
pix2mm     = @(p,i) round((p / pix_per_mm), i);
frm2hr     = @(f,i) round(f * frm_per_hr, i);
hr2frm     = @(h,i) round(h / frm_per_hr,i);
vf2h       = @(f) (pix2mm(f,8) * f2h); % Velocity pix -> mm then frames --> hours
rf2h       = @(f) (f * f2h) * 100;     % REGR frames -> hours

fhnd  = {pix2mm ; mm2pix ; frm2hr ; hr2frm ; vf2h ; rf2h};
flds  = {'pix2mm' ; 'mm2pix' ; 'frm2hr' ; 'hr2frm' ; 'vf2h' ; 'rf2h'};
funcs = cell2struct(fhnd, flds);

% Extract Data [requires more inputs]
[pts , nfrms , lens , mms , frm , hrs] = deal([]);
if nargin > 0
    nfrms  = size(X{1}.Stats.cuREGR, 2);
    maxpts = round(nfrms,-1) - 10;
    pts    = {5  : 20 ; 30 : 45 ; 65 : maxpts};

    lthr  = pix_per_mm * 2;
    lmax  = max(cellfun(@(y) max(cell2mat(cellfun(@(x) x(end,:), ...
        y.Output.Arclength.src, 'UniformOutput', 0)), [], 'all'), X));
    lens  = [lthr , lmax];
    mms   = pix2mm(lens,3);
    frm   = [fblu , nfrms , cellfun(@(x) x(round(numel(x) / 2)), pts')];
    hrs   = frm2hr(frm,3);
    fprintf('\n%s\n| smallest: %.02f px | largest %.02f px |\n', sprA, lens);
    fprintf('| smallest: %.02f mm | largest %.02f mm |\n%s\n', mms, sprB);
    fprintf(['| blue %d frms | total %d frms | ' ...
        'early %d frms | mid %d frms | late %d frms |\n'], frm);
    fprintf(['| blue %.01f hrs | total %.01f hrs | ' ...
        'early %.01f hrs | mid %.01f hrs | late %.01f hrs |\n%s\n'], hrs, sprA);
end

ddat  = {pts ; nfrms ; lens ; mms ; frm ; hrs};
dlds  = {'pts' ; 'nfrms' ; 'lens' ; 'mms' ; 'frm' ; 'hrs'};
dats  = cell2struct(ddat, dlds);
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Misc Options
p.addOptional('pix_per_mm', 184.5);  % Digits to round means to
p.addOptional('frm_per_hr', 0.0833); % Digits to round sterrs to
p.addOptional('fblu', 24);           % Digits to round sterrs to

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end