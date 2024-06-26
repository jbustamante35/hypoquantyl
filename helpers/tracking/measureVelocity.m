function vtrg = measureVelocity(ltrg, rep)
% function vtrg = measureVelocity(wsrc, ltrg, ipcts, rep)
%% measureVelocity: measure velocity between frames
if nargin < 2; rep = 0; end

% Make source arclengths and get difference to target arclenghts
% lsrc = flipud(cell2mat(arrayfun(@(y) arrayfun(@(x) ...
%     x.calculatelength(y,1), wsrc), ipcts, 'UniformOutput', 0))');
% vtrg = ltrg - lsrc;

% vtrg = [zeros(size(ltrg,1),1) , diff(ltrg')'];
vtrg = [zeros(size(ltrg,1),1) , gradient(ltrg)];

% Pc = arrayfun(@(y) arrayfun(@(x) y.calculatelength(x, 1, 1000), ...
%     ipcts'), sws, 'UniformOutput', 0);
% Pc = flipud(cat(2, Pc{:}));

if rep
    % Remove negative Velocity
    vtrg(vtrg < 0) = 0;

    if rep == 2
        % Remove high outliers
        ustd                 = mean(vtrg, 'all');
        rstd                 = std(vtrg, [], 'all');
        rthrsh               = ustd + (rstd * 1);
        vtrg(vtrg >= rthrsh) = rthrsh;
    end
end
end