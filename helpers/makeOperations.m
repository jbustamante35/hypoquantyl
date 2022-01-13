function [S , R , D] = makeOperations
%% makeOperations
S = @(sx,sy) [[sx , 0 , 0] ; [0 , sy , 0] ; [0 , 0 , 1]];
R = @(th) [[cos(th) , -sin(th) , 0] ; [sin(th) , cos(th) , 0] ; [0 , 0 , 1]];
D = @(dx,dy) [[1 , 0 , dx] ; [0 , 1 , dy] ; [0 , 0 , 1]];
end