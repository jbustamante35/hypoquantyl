function [lam,V] = eigenValues(M)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % [M1 M3]
    % [M2 M4]
    %%%%%%%%%%%%%%%
    % make symetric
    %%%%%%%%%%%%%%%
    M(:,3) = .5*(M(:,3) + M(:,2));
    M(:,2) = M(:,3);
    %%%%%%%%%%%%%%%
    % closed form for eigenvalues
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    lam(:,1) = .5*(M(:,1)+M(:,4)) + .5*(4*M(:,2).*M(:,3) + (M(:,1)-M(:,4)).^2).^.5;
    lam(:,2) = .5*(M(:,1)+M(:,4)) - .5*(4*M(:,2).*M(:,3) + (M(:,1)-M(:,4)).^2).^.5;
    
    %%%%%%%%%%%%%%%
    if nargout == 2
        
        M = reshape(M',[size(M,2)^.5 size(M,2)^.5 size(M,1)]);
        V = zeros(size(M));
        
        
        parfor i = 1:size(M,3)
            [V(:,:,i),~] = eigs(M(:,:,i));
            %fprintf([num2str(i) ':' num2str(size(M,3)) '\n']);
        end
        
        
        V = reshape(V,[size(M,1)^2 size(M,3)]);
        V = V';
        
    end
end