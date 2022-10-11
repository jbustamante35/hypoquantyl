function S = makegmmStruct(data, k)
%% makegmmStruct
kidx = kmeans(data(:), k);
for i = 1 : k
    S.mu(i)                  = mean(data(kidx == i));
    S.Sigma(:,:,i)           = cov(data(kidx == i));
    S.ComponentProportion(i) = sum(kidx == i) / numel(kidx);
end
S.mu = S.mu';
end