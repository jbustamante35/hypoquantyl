function fig = plotScoreDistribution(X, Y, f)
%% plotScoreDistribution:
% Still unsure exactly what this will do
%
% Usage;
%
%
% Input:
%
%
% Output:
%
%

fig = figure(f);

% Create a histogram of each PC score distribution
subplot(321);
hold on;
histogram(X(:,1), 'FaceColor', 'b');
histogram(X(:,2), 'FaceColor', 'r');
histogram(X(:,3), 'FaceColor', 'k');
legend('PC1', 'PC2', 'PC3');
ttl = sprintf('Original Scores\nData Distribution');
title(ttl);

% Plot the PC score distribution
subplot(322);
hold on;
plot3(X(:,1), X(:,2), X(:,3), 'k.');
xlabel('PC1');
ylabel('PC2');
zlabel('PC3');
ttl = sprintf('Original Scores\nPoint Field');
title(ttl);

% Test out creating and drawing from a distribution
subplot(323);
hold on;
histogram(Y(:,1), 'FaceColor', 'c');
histogram(Y(:,2), 'FaceColor', 'm');
histogram(Y(:,3), 'FaceColor', 'y');
legend('PC1', 'PC2', 'PC3');
ttl = sprintf('Random Draw\nData Distribution');
title(ttl);

% Plot the PC score distribution
subplot(324);
hold on;
plot3(Y(:,1), Y(:,2), Y(:,3), 'g.');
xlabel('PC1');
ylabel('PC2');
zlabel('PC3');
ttl = sprintf('Random Draw\nPoint Field');
title(ttl);

% Overlay both distributions
% Create a histogram of each PC score distribution
subplot(325);
hold on;
histogram(X(:,1), 'FaceColor', 'b');
histogram(X(:,2), 'FaceColor', 'r');
histogram(X(:,3), 'FaceColor', 'k');
histogram(Y(:,1), 'FaceColor', 'c');
histogram(Y(:,2), 'FaceColor', 'm');
histogram(Y(:,3), 'FaceColor', 'y');
legend('rawPC1', 'rawPC2', 'rawPC3', 'dstPC1', 'dstPC2', 'dstPC3');
ttl = sprintf('Original Scores vs Random Draw\nData Distribution');
title(ttl);

% Plot the PC score distribution
subplot(326);
hold on;
plot3(X(:,1), X(:,2), X(:,3), 'k.');
plot3(Y(:,1), Y(:,2), Y(:,3), 'g.');
xlabel('PC1');
ylabel('PC2');
zlabel('PC3');
ttl = sprintf('Original Scores vs Random Draw\nPoint Field');
title(ttl);

end