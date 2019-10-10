function Z = curve2framebundle(C)
%% curve2
%
len = size(C,1);
tmp = [C' , C' , C']';

%
dc = gradient(tmp')';
dl = sum(dc .* dc, 2).^-0.5;
dc = bsxfun(@times, dc, dl);
dn = [dc(:,2) , -dc(:,1)];
Z  = [tmp , dc , dn];

%
Z = Z(len+1 : 2*len, :);


end

