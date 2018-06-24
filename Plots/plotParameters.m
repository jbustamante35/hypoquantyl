function figs = plotParameters(x, y, t)
%% plotParameters:
%
%
% Usage:
%
%
% Input:
%
%
% Output:
%   fig: function handle to figure
%

%%
% Ppar = struct('full', Ppar_Full, 'left', Ppar_Left, 'right', Ppar_Right);
pltl = @(n) plot3(Ppar.left.x(:,n), Ppar.left.y(:,n), Ppar.left.t(:,n),'.','MarkerSize',15);
pltr = @(n) plot3(Ppar.right.x(:,n), Ppar.right.y(:,n), Ppar.right.t(:,n),'.','MarkerSize',15);

%%
n = 1;
for i = 1 : 7
    if n <= 7
        n = dewit(pltl, pltr, n);
    else
        n = 1;
        n = dewit(pltl, pltr, n);
    end
    pause(1);
end

%%
n = 1;
n = dewit(pltl, pltr, n);
end

function f = paramPlot(func, num, face)

f = func(num);
ttl = sprintf('Parameters (\theta, x, y) | %s-Facing | Segment %d', face, num);
title(ttl);
xlabel('x-coordinate');
ylabel('y-coordinate');
zlabel('theta');
grid on;
set(gcf, 'Color', 'w');

end

function n = dewit(pltl, pltr, n)

subplot(211);
paramPlot(pltl, n, 'Left');

subplot(212);
paramPlot(pltr, n, 'Right');

n = n + 1;
end