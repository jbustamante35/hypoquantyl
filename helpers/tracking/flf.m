function v = flf(x, p)
%% flf: compute and fit velocity to flf function
%
% Usage:
%   v = flf(x, p)
%
% Input:
%   x: arclengths
%   p: parameters ([vmax , k , x0 , n])
%
% Output:
%   v: fit velocity

if size(p,1) > size(x,1); x = ones(size(p, 1), 1) * x; end

if size(x,1) == size(p,1)
    for e = 1 : size(p,1)
        v(e,:) = p(e,1) .* ...
            (1 + exp(-p(e,2) * (x(e,:) - p(e,3)))).^-(p(e,4).^-1);
    end
else
    v = p(1) .* (1 + exp(-p(2) * (x - p(3)))).^-(p(4).^-1);
end

if any(isinf(v)) | any(isnan(v))
    fidx    = isinf(v) | any(isnan(v));
    v(fidx) = 10000;
end
end
