function [figs , fnms] = makeBlankFigures(nf, clr)
%% makeBlankFigures: generate empty figures and figure names
%
% Usage:
%   [figs , fnms] = makeBlankFigures(nf)
%
% Input:
%   nf: number of figures to generate
%   clr: make figure colormap gray by default (default false)
%
% Output:
%   figs: figure handle indices
%   fnms: figure names
%
% Author Julian Bustamante <jbustamante@wisc.edu>

%% Set figure handle index and place-holder names
if nargin < 2
    clr = 0;
end

figs = 1 : nf;
fnms = cell(nf, 1);

for n = 1 : nf
    if isempty(figure(figs(n)))
        figs(n) = figure;
    else
        figclr(n);
        
        if clr
            colormap gray;
        end
    end
    
    fnms{n} = sprintf('%s_blank', tdate('s'));
end

set(figs, 'Color', 'w');

end