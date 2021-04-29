function [X] = myGrid(X)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % rank
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    rnk = numel(X.bv);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % create data grid
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    cmd = 'ndgrid';
    %%%%%%%%%%%%%%%%%%%
    icmd = '';
    ocmd = '';
    %%%%%%%%%%%%%%%%%%%
    icmd = [icmd '('];
    ocmd = [ocmd '['];
    %%%%%%%%%%%%%%%%%%%
    for e = 1:rnk
        icmd = [icmd 'X.bv(' num2str(e) ').v,'];
        ocmd = [ocmd 'X' num2str(e) ','];
    end
    %%%%%%%%%%%%%%%%%%%
    icmd(end) = [];
    ocmd(end) = [];
    icmd = [icmd ')'];
    ocmd = [ocmd ']'];
    %%%%%%%%%%%%%%%%%%%
    fcmd = [ocmd '=' cmd icmd ';'];
    eval(fcmd);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % cat data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    X.d = [];
    for e = 1:rnk
        cmd = ['X.d = cat(2,X.d' ',X' num2str(e) '(:));'];
        eval(cmd);
    end
    X.sz = size(X1);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

%{
    X(1).bv = linspace(0,10,100);
    X(2).bv = linspace(0,10,3);
    X(3).bv = linspace(0,10,21);
    G = myGrid(X);
%}