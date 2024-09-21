function [alpha,s1,s2] = fastIntercept(varargin)
    disp = true;
    if nargin == 1
        p1 = varargin{1}(1:2);
        v1 = varargin{1}(3:4);
        p2 = varargin{1}(5:6);
        v2 = varargin{1}(7:8);
    elseif nargin == 2
        p1 = varargin{1}(1:2);
        v1 = varargin{1}(3:4);
        p2 = varargin{2}(1:2);
        v2 = varargin{2}(3:4);
    else
        p1 = varargin{1};
        v1 = varargin{2};
        p2 = varargin{3};
        v2 = varargin{4};
        if numel(varargin) > 4;disp = varargin{5};end
    end


    if nargin < 5;disp = false;end

    %%%%%%%%%%%%%%%%%%%%%
    % assume v1 and v2 are unit vectors
    %v1 = v1 / norm(v1);
    %v2 = v2 / norm(v2);

    T = p2 - p1;
    D = norm(T);
    T = T / norm(T);

    N = [-T(2) T(1)];
    M = [N;T];
    V = [v1;v2]';


    R = mtimesx(M,V);

    alpha = R\[0;D];


    if nargout > 1
        s1 = p1 + alpha(1)*v1;
        s2 = p2 + alpha(2)*v2;
    end

    %alpha(2) = -alpha(2);

    if disp

        longMag = 10;

        plot(p1(1),p1(2),'b.');hold on
        plot(p1(1),p1(2),'ko');

        plot(p2(1),p2(2),'r.');hold on
        plot(p2(1),p2(2),'ko');

        myquiver(p1(1),p1(2),v1(1),v1(2),5,'b');
        myquiver(p2(1),p2(2),v2(1),v2(2),5,'r');

        myquiver(p1(1),p1(2),v1(1),v1(2),alpha(1),'c',2);
        myquiver(p2(1),p2(2),v2(1),v2(2),-alpha(2),'m',2);


        myquiver(p1(1),p1(2),v1(1),v1(2),longMag,'k');
        myquiver(p1(1),p1(2),-v1(1),-v1(2),longMag,'k');


        myquiver(p2(1),p2(2),v2(1),v2(2),longMag,'k');
        myquiver(p2(1),p2(2),-v2(1),-v2(2),longMag,'k');

    

    end

end

%{

    p1 = [2 1.5];
    v1 = [-1 -1];
    p2 = [-1 1];
    v2 = [.5 2];
    
    fastIntercept(p1,v1,p2,v2);
    



%}