function [direc] = DC(I)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This code will find the direction that the root is coming from.
    % authored last at: June 21, 2007
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % change the function of flip on date of May, 14 2015
    % try var of surface curvature rather than gray scale intensity
    para.scales.value = 5;
    para.resize.value = .5;
    K = surKur(I,para);
    I = K(:,:,1);
    
    % setup with width of 100 pixels along the left hand side
    % for each rotation
    WIDTH = 100;
    IDX = 1:WIDTH;
    
    sz = size(I);
    I = imresize(I,.5);
    h = fspecial('gaussian',[21 21],4);
    I = imfilter(I,h,'replicate');
    I = imresize(I,sz);
    U = [];

    % sample and rotate
    for e = 1:4
        %imshow(I,[]);
        %drawnow
        %waitforbuttonpress
        V = I(:,IDX);
        V = mean(V,2);
        V = interp1(1:1:size(V,1),V,linspace(1,size(V,1),1000));
        I = imrotate(I,90);
        U = [U;V];
    end
    
    %{
    % find the outlier
    % this was the first - grand mean
    u = mean(U(:));
    U = U - u;
    D = sum(U.*U,2);
    %}
   
    %{
    % this is different - mean along each vec
    u = mean(U,2);
    % both use this offset
    U = bsxfun(@minus,U,u);
    %}
    
    
    % OR try var
    D = std(U,1,2);
    
    % 
    [JUNK,direc] = max(D);
    
    
    
end