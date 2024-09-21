function [X,invOp] = iflattenTensor(X,ivec)
    
    invOp.sz = size(X);
    invOp.pvec = ivec.pvec;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    X = reshape(X,ivec.sz);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    X = ipermute(X,ivec.pvec);
    
    
end