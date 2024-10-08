function [flds1 , flds2 , flds3] = extractFields(T, fld)
% flds = extractFields(T, fld)
%% extractFields: depth-first search through tracking structure
% Only works with 3 sub-fields for now
if nargin < 2; fld = ''; end

% % Check if prefix is provided, if not, initialize it as an empty string
% if nargin < 2; fld = ''; end

% flds  = {};            % Initialize an empty cell array to hold field names
% flds1 = fieldnames(T); % Get the fieldnames of the current structure
% 
% for i = 1 : numel(flds1)
%     field = flds1{i};
%     % Construct the full field name with a prefix if nested
%     if isempty(fld)
%         fullField = field;
%     else
%         fullField = [fld '.' field];
%     end
% 
%     % Add the current field to the list
%     flds{end+1} = fullField;
% 
%     % If the field is a structure, recurse into it
%     if isstruct(T.(field))
%         subFields = extractFields(T.(field), fullField);
% 
%         % Append the nested field names to the list
%         flds = [flds , subFields];
%     end
% end

%% TODO: make this flexible to unlimited sub-fields
flds1           = fieldnames(T);
[flds2 , flds3] = deal(cell(numel(flds1),1));
for f1 = 1 : numel(flds1)
    fld1 = flds1{f1};
    try
        flds2{f1} = fieldnames(T.(fld1))';
        for f2 = 1 : numel(flds2{f1})
            fld2 = flds2{f1}{f2};
            try
                flds3{f1}{f2} = fieldnames(T.(fld1).(fld2));
            catch
                flds3{f1}{f2} = {};
            end
        end
    catch
        flds2{f1} = {};
    end
end
end