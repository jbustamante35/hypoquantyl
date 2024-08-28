function results2csv(udata, dpths, varargin)
%% results2csv: export velocity and REGR profiles into CSV file

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Extract information from data
ntbls          = (1 : numel(udata))';
[ltrp , nfrms] = size(udata{1});

% Append converted interpolated arclengths to velocities and regrs
f     = getConversionFunctions;
hrs   = round(f.frm2hr(1 : nfrms,3) - f.frm2hr(1,3), 2);
hrs   = arrayfun(@(x) sprintf('%s h', num2str(x)), hrs, 'UniformOutput', 0);
flds  = ['L (mm)' , hrs];

if lthr >= LEN_CUTOFF
    % Make space in pix, then convert to mm
    lens = f.pix2mm(linspace(0, lthr, ltrp), 5)';
    lens = f.mm2pix(lens, udig);
else
    lens = round(linspace(0, lthr, ltrp), 5)';
end

%%
if ~isempty(udig)
    % Round to number of digits
    utbl  = cellfun(@(x) array2table([lens , round(x,udig)], ...
        'VariableNames', flds), udata, 'UniformOutput', 0);
else
    % No rounding
    utbl  = cellfun(@(x) array2table([lens , x], ...
        'VariableNames', flds), udata, 'UniformOutput', 0);
end

% Setup file names
if isempty(elbls)
    elbls = arrayfun(@(x) sprintf('experiment%02d', x), ...
        ntbls, 'UniformOutput', 0);
end

if isempty(nlbls); nlbls = arrayfun(@(x) 0, ntbls); end

[~ , dnm] = fileparts(dpths);
unms      = arrayfun(@(x) sprintf('%s/%s_%s_%02dseedlings_%s.csv', ...
    dpths, tdate, elbls{x}, nlbls(x), dnm), ntbls, 'UniformOutput', 0);

%% Export to csv
if ~isfolder(dpths); mkdir(dpths); end
cellfun(@(rin,fout) writetable(rin, fout), utbl, unms, 'UniformOutput', 0);
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Misc Options
p.addOptional('LEN_CUTOFF', 50); % Set cutoff arclength in mm
p.addOptional('lthr', 2);        % Requested arclength in mm [pix if >= LEN_CUTOFF]
p.addOptional('udig', 5);        % Digits to round means to
p.addOptional('elbls', []);      % Label names
p.addOptional('nlbls', []);      % Number of seedlings

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
