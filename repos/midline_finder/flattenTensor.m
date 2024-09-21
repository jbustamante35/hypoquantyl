function [X,ivec] = flattenTensor(X,fvec)
    %{
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    A = rand(3,4,5,2);
    [B,i] = flattenTensor(A,{[3 4]  [2 1]});
    [C,ii] = iflattenTensor(B,i);
    [D,iii] = flattenTensor(C,ii);
    all(C(:) == A(:))
    all(D(:) == B(:))
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %}

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % flatten := permute and reshape into new tensor
    % fvec can be {[] [] []} or struct produced
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if isa(fvec,'cell')

        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % check to see if flattenOp need pre-permute
        pvec = [];
        for e = 1:numel(fvec)
            pvec = [pvec fvec{e}];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % if needs permute then build
        if ~all((1:numel(pvec)) == pvec)
            in.pvec = pvec;
            %{
            [nvec] = ifind(pvec);
            % build new flattenop
            for e = 1:numel(fvec)
                nfvec{e} = nvec(fvec{e});
            end
            % assign to new vec
            fvec = nfvec;
            %}
        % else do not build and permute with natural pvec
        else
            in.pvec = 1:(numel(pvec));
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        szX = size(X);
        % agument for ones
        szX = [szX ones(1,numel(in.pvec) - size(szX,2))];
        for e = 1:numel(fvec)
            d(e) = prod(szX(fvec{e}));
        end
        in.sz = d;
        
    elseif isa(fvec,'struct')
        in = fvec;
        pvec = in.pvec;
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    X = permute(X,in.pvec);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    szX = size(X);
    X = reshape(X,in.sz);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    ivec.sz = szX;
    ivec.pvec = pvec;
    
end