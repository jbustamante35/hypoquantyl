function minDistIdx = compareCoords(pf,  cf)
%% Compare coordinates of previous frame with current frame
% If coordinates are within set error percent, it is added to the
% next frame of the Seedling. Otherwise the frame is skipped.
%
% Input:
%   pf: coordinates of previous frame for current Seedling
%   cf: cell array of Seedlings at specific frame to compare to pf
%   d : Euclidean distances between pf and cf
%
% Output:
%   minDistIdx: Seedling index where input coordinate is closest

    minDistIdx = nan;
    
    if length(cf) > 1
        %         d = cell(1, length(cf));
        d = zeros(1, numel(cf));

        for i = 1:length(cf)
            try
                %                 d{i} = pdist([pf; cf{i}.getCoordinates(1)]);
                d(i) = pdist([pf; cf{i}.getCoordinates(1)]);
            catch e
                d(i) = nan;
            end
        end

        %         dcats = cat(1, d{:});
        %         dmins = dcats == min(dcats(:));
        %         dname = char(cf{dmins}.getSeedlingName);
        if sum(isnan(d)) ~= numel(d)
            minIdx  = d == min(d);
            minName = char(cf{minIdx}.getSeedlingName);
        else
            fprintf(2, 'No coordinates found at any index\n');
            return;
        end

    else
        if ~isempty(cf{1})
            minName = char(cf{1}.getSeedlingName);
        else
            fprintf(2, 'No coordinates found at any index\n');
            return;
        end
            
    end

    % Return Seedling name to determine which data to extract
    if ~isempty(minName)
        minDistIdx = str2double(minName(end));
    else
        fprintf(2, 'No coordinates found at any index\n');
        return;
    end
    
end