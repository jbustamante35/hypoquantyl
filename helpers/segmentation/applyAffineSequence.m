function Y = applyAffineSequence(aff, D)
%% applyAffineSequence:
%
%
% Input:
%   aff:

%%
for e = 1 : size(aff,1)
    Y(:,e) = squeeze(aff(e,:,:)) * D(:,e);
end

end

