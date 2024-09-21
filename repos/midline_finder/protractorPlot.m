function protractorPlot(P, alpha, vec, rad)
%% protractorPlot
nor = [vec(2) ; -vec(1)];
TH  = linspace(0, alpha, 100);
arc = rad * [cos(TH') , sin(TH')]';
F   = [vec , nor];
arc = (F * arc)' + P;
plot(arc(:,1), arc(:,2), 'k');
end