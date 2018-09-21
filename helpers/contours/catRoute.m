function D = catRoute(X, req)
%% catRoute: concatonate Route data to multi-dimensional matrix
% This function takes requested data and concatenates it into a single multi-dimensional matrix.
%
% Usage:
%   D = catRoute(X, req)
%
% Input:
%   X: full object containing data
%   req: reqested property to concatenate ('P': Pmat | 'M': Ppar | 'R': Trace)
%
% Output:
%   D: single multi-dimensional matrix containing requested data
%

%% Retrieve requested property to extract
switch req
    case 'P'
        prp = 'getPmat';
        
    case 'M'
        prp = 'getPpar';
        
    case 'R'
        prp = 'getTrace';       
        
    otherwise
        fprintf(2, 'Invalid request: %s is not a property of Route\n', req);
        return;
end

%% Concatenate requested data
D1 = arrayfun(@(x) arrayfun(@(y) y.(prp), x.getRoute, 'UniformOutput', 0), X, 'UniformOutput', 0)';
D1 = cat(1, D1{:});

szAB = size(D1{1,1});
szCD = size(D1);
D = zeros([szAB szCD]);
for d = 1 : szCD(2)
    D(:,:,:,d) = cat(3, D1{:,d});
end

end