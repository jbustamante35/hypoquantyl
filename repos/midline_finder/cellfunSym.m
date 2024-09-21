function [y] = cellfunSym(g,f,x)
    y = f(x);
    if isa(y,'cell')
        y = cell2mat(cellfun(g,f(x),'UniformOutput',false));
    else
        y = double(y);
    end      
end