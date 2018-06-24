function chk = checkCatRoute(X, D)
%% checkCatRoute: verify data concatenation from catRoute is correct
% Sometimes reorganizing data can lead to mismatches in dimensions. This function compares original
% output from the single multi-dimensional matrix.
%
% Usage:
%   chk = checkCatRoute(X, D)
%
% Input:
%   X: original object where concatenated data was extracted
%   D: concatenated data outputted from catRoute
%
% Output:
%   chk: boolean to verify whether output data matches actual data
%

%% Retrieve requested property to check results
switch sum([size(D, 1) size(D, 2)])
    case sum(size(X(1).getRoute(1).getPmat)) % sum = 6
        prp = 'getPmat';
        
    case sum(size(X(1).getRoute(1).getPpar)) % sum = 4
        prp = 'getPpar';
        
    case sum(size(X(1).getRoute(1).getTrace)) % sum = 302
        prp = 'getTrace';
        
    otherwise
        fprintf(2, 'Invalid data: property with dimensions [%d %d] not found\n', size(D));
        return;
end

%% Compare actual with concatenated data
t = size(D,3) * size(D,4);
T = zeros(t,1);
x = 1;
for n = 1 : numel(X)
    for m = 1 : numel(X(n).getRoute)
        T(x) = isequal(D(:,:,n,m), X(n).getRoute(m).(prp));
        x = x + 1;
    end
end

%% Boolean verification of result
V = sum(T);
chk = isequal(sum(V), t);

end