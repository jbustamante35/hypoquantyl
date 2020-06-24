function [figs , fnms] = makeBlankFigures(nf)
%% makeBlankFigures: generate empty figures and figure names
%
% Usage:
%    [figs , fnms] = makeBlankFigures(nf)
%
% Input:
%    nf: number of figures to generate
%
% Output:
%    figs: figure handle indices
%    fnms: figure names
%
% Author Julian Bustamante <jbustamante@wisc.edu>

%% Set figure handle index and place-holder names
figs = 1 : nf;
fnms = cell(nf, 1);

for n = 1 : nf
    if isempty(figure(figs(n)))
        figs(n) = figure;
    else
        figclr(n);
    end
    
    fnms{n} = sprintf('%s_blank', tdate('s'));
end

set(figs, 'Color', 'w');

end