function myimagesc(img, clr, im, ax)
%% myimagesc: my version of imagesc with options I always use
%
%

if nargin < 2
    clr = 'gray';
    im  = 'image';
    ax  = 'off';
end

imagesc(img);
colormap(clr);
axis (im);
axis(ax);

end

