function [flds1 , flds2 , flds3] = extractFields(T)
%% extractFields: depth-first search through tracking structure
% Only works with 3 sub-fields for now


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