function ctrs = extractAllContours(seed_in, max_size, cont_ver)
%% extractAllContours: find contour at each frame for a single Seedling
% This function blah
%
% Usage:
%   ctrs = extractContour(seed_in, max_size)
%
% Input:
%   seed_in: Seedling object to generate contour data
%   max_size: number of coordinates to normalize boundaries
%   cont_ver: output version of extractContour
%
% Output:
%   ctrs: various data from contours
%

%% Contours from each frame
ctrs = ContourJB;

switch cont_ver
    case 1
        % extractContour outputs single ContourJB object
        try
            for i = 1 : seed_in.getLifetime
                bw  = seed_in.getImage(i, 'bw');
                tmp = extractContour(bw, max_size);
                
                fn = fieldnames(tmp);
                for ii = 1 : numel(fn)
                    ctrs.(fn{ii}){i} = tmp.(fn{ii});
                end
                
                org = sprintf('%s_%s_%s_Frm%d', seed_in.ExperimentName, seed_in.GenotypeName,...
                    seed_in.getSeedlingName, i);
                ctrs.setOrigin(org);
            end
        catch
            fprintf('Attempting alternate method. \n');
            ctrs = extractAllContours(seed_in, max_size, 2);
        end
        
    case 2
        % extractContour has multiple outputs for ContourJB object
        try
            for i = 1 : seed_in.getLifetime
                bw = seed_in.getImage(i, 'bw');
                
                [bnds, dL, L, I] = extractContour(bw, max_size);
                ctrs.Bounds{i}   = bnds;
                ctrs.Dists{i}    = dL;
                ctrs.Sums{i}     = L;
                ctrs.Interps{i}  = I;
                org = sprintf('%s_%s_%s_Frm%d', seed_in.ExperimentName, seed_in.GenotypeName,...
                    seed_in.getSeedlingName, i);
                ctrs.setOrigin(org);
            end
        catch
            fprintf('Attempting alternate method. \n');
            ctrs = extractAllContours(seed_in, max_size, 1);
        end
        
    otherwise
        % Default to version with single output
        fprintf('No specified output version. Using default. \n');
        ctrs = extractAllContours(seed_in, max_size, 1);
end

end


