function plotgmmStruct(S, x)
%% plotgmmStruct
if nargin < 2; x = linspace(0, 1, 255); end

super = zeros(size(x));
for i = 1 : numel(S.mu)
    y     = normpdf(x, S.mu(i), sqrt(S.Sigma(:,:,i)));
    y     = y * S.ComponentProportion(i);
    super = super + y;
end
super = super / sum(super);
plt([x ; super]', '-', 3);
end