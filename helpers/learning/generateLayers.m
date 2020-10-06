function layers = generateLayers(flts, nflts, nf)
%% generateLayers: generate convolution layers from range of filter sizes
%
%
% Usage:
%   layers = generateLayers(flts, nflts, n)
%
% Inputs:
%   flts: size of filter
%   nflts: number of filters to create
%   n: number of times to copy given layers [default 1]
%
% Outputs:
%   layers: layers generated from filter sizs and numbers
%
if nargin < 3
    nf = 1;
end

layers = cell(numel(flts) * numel(nflts), 1);
t      = 1;

for f = 1 : numel(flts)
    for n = 1 : numel(nflts)
        flt    = flts(f);
        nflt   = nflts(n);
        cnvnm  = sprintf('conv_%d_flt%d_num%d', t, flt, nflt);
        btcnm  = sprintf('batchnorm_%d', t);
        relnm  = sprintf('relu_%d', t);
        mpolnm = sprintf('mpool_%d', t);
        
        layers{t} = [ ...
            convolution2dLayer(flt, nflt, 'Name', cnvnm, 'Padding', 'same') ;
            batchNormalizationLayer('Name', btcnm) ;
            reluLayer('Name', relnm) ;
            maxPooling2dLayer(2, 'Stride', 2, 'Name', mpolnm); ...
            ];
        
        t = t + 1;
    end
end

layers = cat(1, layers{:});

if nf > 1
    layers = repmat(layers, nf, 1);
end

end