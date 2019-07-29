function [N , Z] = addNormalVector(M, T)
%% addNormalVector: 
N = (Rmat(90) * (T - M)')' + M;
Z = [M , T , N];
end