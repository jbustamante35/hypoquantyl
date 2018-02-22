function minDistIdx = compareCoords(pf,  cf)
%% Compare coordinates of previous frame with current frame
% If coordinates are within set error percent, it is added to the
% next frame of the Seedling. Otherwise the frame is skipped.
%
% Input:
%   pf: coordinates of previous frame for current Seedling
%   cf: frame of Seedlings currently comparing to pf
%   d : Euclidean distances between pf and cf
%
% Output:
%   minDistIdx: Seedling index where input coordinate is closest 

    if length(cf) > 1
        d = cell(1, length(cf));

        for i = 1:length(cf)
            d{i} = pdist([pf; cf{i}.getCoordinates(1)]);
        end

        x = cat(1, d{:});
        m = x == min(x(:));                
        n = char(cf{m}.getSeedlingName);

    else                                
        n = char(cf{1}.getSeedlingName);                
    end

    % Return Seedling name to determine which data to extract 
    minDistIdx = str2double(n(end));                

end