function [K,Vo] = surKur(I,para)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % compute surface curvature map
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % INPUT: 
    %           I       := image
    %           para    := parameters for running the script         
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % OUTPUT: 
    %           cM      := corner map       -> corner strength
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % init OUT vars
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        K = [];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % set variables
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        S = para.scales.value;
        imS = para.resize.value;
        sz = size(I);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % resize image and double of image
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % double
        if (imS~=1);Iorg = I;I = imresize(I,imS);
        end
        % resize
        if ~isa(I,'double')
            I = double(I);
        end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % first order terms
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %[dFd1 dFd2] = gradient(I);
        order = '1stOrder';
        dFd1 = DGradient(I,1,2,order);
        dFd2 = DGradient(I,1,1,order);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % second order terms
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %[d1d1 d1d2] = gradient(dFd1);
        d1d1 = DGradient(dFd1,1,2,order);
        d1d2 = DGradient(dFd1,1,1,order);
        %[d2d1 d2d2] = gradient(dFd2);
        d2d1 = DGradient(dFd2,1,2,order);
        d2d2 = DGradient(dFd2,1,1,order);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % for each scale
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for k = 1:numel(S)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % construct filter
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            edgeEffect = 'replicate';
            % disk size  
            PDSZ = 2*S(k) + S(k);
            % make filter
            h1 = fspecial('disk', PDSZ);
            h2 = fspecial('gaussian',size(h1),S(k));
            h = h1.*h2;
            % smooth first derivative
            tdFd1 = imfilter(dFd1,h,edgeEffect);
            tdFd2 = imfilter(dFd2,h,edgeEffect);
            % smooth second derivative
            td1d1 = imfilter(d1d1,h,edgeEffect);
            td1d2 = imfilter(d1d2,h,edgeEffect);
            td2d1 = imfilter(d2d1,h,edgeEffect);
            td2d2 = imfilter(d2d2,h,edgeEffect);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % operations
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%
            % tangent space - 1,2
            %%%%%%%%%%%%%%%%%%%%%%%%
            TMe1 = cat(3,ones(size(I)),zeros(size(I)),tdFd1);
            TMe1 = meshNormalize(TMe1);
            TMe1 = dimBulk(TMe1);
            TMe2 = cat(3,zeros(size(I)),ones(size(I)),tdFd2);
            TMe2 = meshNormalize(TMe2);
            TMe2 = dimBulk(TMe2);
            %%%%%%%%%%%%%%%%%%%%%%%%
            % normal space - 3
            %%%%%%%%%%%%%%%%%%%%%%%%
            NOR = cat(3,-tdFd1,-tdFd2,ones(size(I)));
            NOR = meshNormalize(NOR);
            NOR = dimBulk(NOR);
            %%%%%%%%%%%%%%%%%%%%%%%%
            % take covarient derivative
            %%%%%%%%%%%%%%%%%%%%%%%%
            v1 = coVar(TMe1,TMe1,NOR);
            v2 = coVar(TMe1,TMe2,NOR);
            v3 = coVar(TMe2,TMe1,NOR);
            v4 = coVar(TMe2,TMe2,NOR);
            %%%%%%%%%%%%%%%%%%%%%%%%
            % obtain e,f,g
            %%%%%%%%%%%%%%%%%%%%%%%%
            e = v1(:,:,2);
            f = .5*(v2(:,:,2) + v3(:,:,2));
            g = v4(:,:,2);
            M =  [e(:) f(:) f(:) g(:)];
            %%%%%%%%%%%%%%%%%%%%%%%%
            % choose to calc vector field
            %%%%%%%%%%%%%%%%%%%%%%%%
            if nargout == 1
                lam = eigenValues(M);
            elseif  nargout == 2
                % calc vectors too
                [lam,V] = eigenValues(M);
                Vo = [];
                % loop over each vector component - 
                for k = 1:size(V,2)
                    vT = reshape(V(:,k),size(I));
                    if (imS~=1)
                        vT = imresize(vT,sz);
                    end        
                    Vo = cat(3,Vo,vT);
                end
            end
            
            
            % prepare lambda
            lam = reshape(lam,[size(I) size(lam,2)]);
            if (imS~=1)
                lam = cat(3,imresize(lam(:,:,1),sz),imresize(lam(:,:,2),sz));
            end
            % stack ressults
            K = cat(4,K,lam);
        end

end

%%%%%%
% this is simular to a parallel transport idea
% bulk the vector field - toWit
% vector field in plane - a three dim
% field - then replicate along z
% this is such that grad along z:=0
function [d] = dimBulk(d)
    s = size(d);
    s = [s(1:2) 1 s(3)];
    d = reshape(d,s);
    d = repmat(d,[1 1 3 1]);
end

%%%%%%
% normalize vector field V
function [V]  = meshNormalize(V)
    nV = sum(V.*V,3).^-.5;
    V = bsxfun(@times,V,nV);
end

% covarient derivative
function [v] = coVar(X,Y,Z)
    % dX/dY along Z
    cvd = [];    
    
    for i = 1:size(X,4)
        % dX/(Descartes) for the ith component of X
        [d1 d2 d3] = gradient(X(:,:,:,i));
        % dX/dY for the ith component of X
        cvd = cat(4,cvd,Y(:,:,:,1).*d1 + Y(:,:,:,2).*d2 + Y(:,:,:,3).*d3);
    end
    % project along Z
    v = dot(cvd,Z,4);
end





