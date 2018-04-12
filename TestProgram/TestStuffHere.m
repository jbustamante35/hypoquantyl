function TestStuffHere(e, n, m, f)
%% TestStuffHere: plot a bunch of data about Seedlings
%
%
%
% Input:
%   e: Experiment from which to extract data
%   n: Genotype number from e
%   m: Seedling number from e(n)
%   f: boolean to create new figure or overwrite existing
%
% Output: n/a
%   Output is a single figure with multiple subplots of various data
%

%% Set up figure and a few variables
if f
    figure;
else
    clf;
end

rows = 2;
cols = 3;
figs = 1;

g = e.getGenotype(n);
s = g.getSeedling(m);

ap = s.getAnchorPoints(':');
A = arrayfun(@(x) ap(1,:,x), 1:length(ap), 'UniformOutput', 0);
B = arrayfun(@(x) ap(2,:,x), 1:length(ap), 'UniformOutput', 0);
C = arrayfun(@(x) ap(3,:,x), 1:length(ap), 'UniformOutput', 0);
D = arrayfun(@(x) ap(4,:,x), 1:length(ap), 'UniformOutput', 0);

A = cell2mat(A');
B = cell2mat(B');
C = cell2mat(C');
D = cell2mat(D');

pd = cat(1, s.getPData(':'));
o = cat(1, pd.Orientation);
wc = cat(1, pd.WeightedCentroid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot constant points on respective subplots
subplot(rows, cols, figs);
hold on;
axis ij;
plot(A(:,1), A(:,2), 'b--');
plot(A(1,1), A(1,2), 'bx', 'MarkerSize', 15);
plot(B(:,1), B(:,2), 'r--');
plot(B(1,1), B(1,2), 'rx', 'MarkerSize', 15);
plot(C(:,1), C(:,2), 'g--');
plot(C(1,1), C(1,2), 'gx', 'MarkerSize', 15);
plot(D(:,1), D(:,2), 'm--');
plot(D(1,1), D(1,2), 'mx', 'MarkerSize', 15);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Start loop for plotting data
for i = 1 : s.getLifetime
    figs = 1;
    subplot(rows, cols,  figs);
    figs = figs + 1;
    
    hold on;
    axis ij;
    plot(ap(1,1,i), ap(1,2,i), 'bo');
    plot(ap(2,1,i), ap(2,2,i),'ro');
    plot(ap(3,1,i), ap(3,2,i),'go');
    plot(ap(4,1,i), ap(4,2,i),'mo');
    
    %     pp = cell(4, 1);
    %     for j = 1 : 4
    %         pp{j} = num2str(ap(j,:,i));
    %     end
    %
    %     ps = sprintf('%s\t%s\t%s\t%s', pp{1}, pp{2}, pp{3}, pp{4});
    cs = sprintf('%.02f %.02f', wc(i,2), wc(i,1));
    t = sprintf('%s \n %s Frame %d \n AnchorPoints %s \n Centroid %s', ...
        g.getGenotypeName, s.getSeedlingName, i, cs);
    title(t);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    subplot(rows, cols,  figs);
    figs = figs + 1;
    imagesc(s.getImage(i, 'gray'));
    colormap gray, axis image;
    hold on;
    plot(ap(1,1,i), ap(1,2,i), 'bo');
    plot(ap(2,1,i), ap(2,2,i),'ro');
    plot(ap(3,1,i), ap(3,2,i),'go');
    plot(ap(4,1,i), ap(4,2,i),'mo');
    t = sprintf('%s \n %s Frame %d \n Orientation %.02f', ...
        g.getGenotypeName, s.getSeedlingName, i, o(i));
    title(t);
    
    hold off;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    subplot(rows, cols,  figs);
    figs = figs + 1;
    im = s.getImage(i, 'gray');
    histogram(im);
    t = sprintf('%s \n %s Frame %d \n MeanInt %.02f', ...
        g.getGenotypeName, s.getSeedlingName, i, mean(im(:)));
    title(t);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    subplot(rows, cols,  figs);
    figs = figs + 1;
    plot(o, 'r--');
    hold on;
    plot(i, o(i), 'bo');
    t = sprintf('%s \n %s Frame %d \n Orientation %.02f', ...
        g.getGenotypeName, s.getSeedlingName, i, o(i));
    title(t);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    subplot(rows, cols,  figs);
    figs = figs + 1;
    h = s.getPreHypocotyl(i);
    hyp = h.getImage('gray');
    imagesc(hyp);
    colormap gray, axis image;
    t = sprintf('%s \n %s Frame %d \n %s', ...
        g.getGenotypeName, s.getSeedlingName, i, h.getHypocotylName);
    title(t);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    subplot(rows, cols,  figs);
    figs = figs + 1;
    h = s.getPreHypocotyl(i);
    hyp = h.getImage('gray');
    histogram(hyp);
    t = sprintf('%s \n %s Frame %d \n MeanInt %.02f', ...
        g.getGenotypeName, h.getHypocotylName, i, mean(hyp(:)));
    title(t);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    drawnow;
end


end

function NotInFunctionB
%% For presentation purposes
n = 1;
m = 3;
t1 = 2;
t2 = 2;

%% Repeat same Seedling
for i = 1 : t1
    TestStuffHere(e, n, m, 0);
end

%% All Seedlings
for i = 1 : t2
    for i = 1 : e.NumberOfGenotypes
        g = e.getGenotype(i);
        for j = 1 : g.NumberOfSeedlings
            s = g.getSeedling(j);
            TestStuffHere(e, i, j, 0);
        end
    end
end


%%



end
