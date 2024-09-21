function [m] = applyMetric(v,M,dim)
    v = pullFront(v,dim);
    [v,sz] = flattenBack(v);
    for e = 1:size(v,2)
        m(:,e) = M(v(:,e));
    end
    newSZ = [size(m,1) sz(2:end)];
    m = reshape(m,newSZ);
end