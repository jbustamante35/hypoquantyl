function myquiver(X, Y, VX, VY, mag, cl, th)
%% myquiver
XP = [X , X + VX * mag];
YP = [Y , Y + VY * mag];
for p = 1:size(XP,1)
    if nargin < 7
        plot(XP(p,:), YP(p,:), cl);
    else
        plot(XP(p,:), YP(p,:), cl, 'LineWidth', th);
    end
end
end