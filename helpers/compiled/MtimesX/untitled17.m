%%
WTS = [0 1 0 0 0 0 0];
[F dF] = pB.f(WTS,vec);
F = [];
for n = 1:1
    F = [];
    for dX = linspace(.0001,.0000001,5)
        dx = zeros(size(vec));
        dx(n) = dX;
        [F2 dF2] = pB.f(WTS,vec+dx);
        [F1 dF1] = pB.f(WTS,vec-dx);
        F = [F;(F2-F1)/(2*dX)];
        dX;
    end
    close all
    plot(F)
    hold all
    plot(dF(n)*ones(size(F)));
    dF(n)
    F(end)
    title(num2str(n))
    drawnow
end
%%
WTS = [0 1 0 0 0 0 0];
[F dF] = computeMeasure_verf0(vec,SSPoints,chainIndex,direc,WTS,dS);

for n = 1:6
    F = [];
    for dX = linspace(.0001,.0000001,5)
        dx = zeros(size(vec));
        dx(n) = dX;
        [F2 dF2] = computeMeasure_verf0(vec+dx,SSPoints,chainIndex,direc,WTS,dS);
        [F1 dF1] = computeMeasure_verf0(vec-dx,SSPoints,chainIndex,direc,WTS,dS);
        F = [F;(F2-F1)/(2*dX)];
        dX;
    end
    close all
    plot(F)
    hold all
    plot(dF(n)*ones(size(F)));
    dF(n)
    F(end)
    title(num2str(n))
    drawnow
end
%%
F = [];
[c3 ceq3 dc3 dceq3] = computeCon_ver0(vec,chainIndex,direc);

n = 3;
for dX = linspace(1,.0000001,5)
    dx = zeros(size(vec));
    dx(n) = dX;
    [c2 ceq2 dc dceq2] = computeCon_ver0(vec+dx,chainIndex,direc);
    [c ceq dc dceq] = computeCon_ver0(vec-dx,chainIndex,direc);
    F = [F;(ceq2-ceq)/(2*dX)];
    dX;
end
close all
plot(F)
hold all
plot(dceq3(n)*ones(size(F)));
dceq3(n)
F(end)
%%
F = [];
[D3 dD3] = computeMeasure(vec,SSPoints);
n = 5;
for dX = linspace(.00001,.000001,10)
    dx = zeros(size(vec));
    dx(n) = dX;
    [D2 dD] = computeMeasure(vec+dx,SSPoints);
    [D dD] = computeMeasure(vec-dx,SSPoints);
    F = [F;(D2-D3)/(dX)];
    %[c2 ceq2 dc dceq2] = computeCon_ver0(vec+dx,chainIndex,direc);
    %[c ceq dc dceq] = computeCon_ver0(vec-dx,chainIndex,direc);
    
    dX;
end
close all
plot(F)
hold all
plot(dD3(n)*ones(size(F)));
dD3(n)
F(end)
 