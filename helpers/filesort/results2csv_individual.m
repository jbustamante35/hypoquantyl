function results2csv_individual(idata, ipths, varargin)
%% results2csv_individual: export individual seedling to csv files

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Extract information from data
ntbls          = (1 : numel(idata))';
[ltrp , nfrms] = size(idata{1});

% Append converted interpolated arclengths to velocities and regrs
f     = getConversionFunctions;
hrs   = round(f.frm2hr(1 : nfrms,3) - f.frm2hr(1,3), 2);
hrs   = arrayfun(@(x) sprintf('%s h', num2str(x)), hrs, 'UniformOutput', 0);
flds  = ['L (mm)' , hrs];

if lthr >= LEN_CUTOFF
    % Convert to mm
    lens = f.pix2mm(linspace(0, lthr, ltrp), 5)';
else
    lens = round(linspace(0, lthr, ltrp), 5)';
end

%% Structure to table
itbl = cell(ntbls(end),1);
for ix = ntbls'
    fchk = 1;
    id   = idata{ix};
    ud   = udig{ix};

    % Check if field columns are in coordinates
    if size(id,2) + 1 ~= numel(flds); fchk = 0; end

    % Check if length (mm) is part of data
    if size(id,1) <= 1; lens = []; end

    % Create table
    if ~isempty(ud)
        % Round to number of digits
        if fchk
            itbl{ix} = array2table([lens , round(id,ud)], ...
                'VariableNames', flds);
        else
            itbl{ix} = array2table([lens , round(id,ud)]);
        end
    else
        % No rounding
        if fchk
            if isempty(lens)
                itbl{ix} = array2table(id, 'VariableNames', flds(2:end));
            else
                itbl{ix} = array2table([lens , id], 'VariableNames', flds);
            end
        else
            itbl{ix} = array2table([lens , id]);
        end
    end
end

[~ , inm] = fileparts(ipths);
inms      = cellfun(@(x) sprintf('%s/%s_%s_%s_%s.csv', ...
    ipths, rdate, elbls, inm, x), nlbls, 'UniformOutput', 0)';

%% Export to csv
if ~isfolder(ipths); mkdir(ipths); end
cellfun(@(iin,iout) writetable(iin, iout), itbl, inms, 'UniformOutput', 0);
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
p.addOptional('rdate', tdate);   % Date exported

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
