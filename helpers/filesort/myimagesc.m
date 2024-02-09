function myimagesc(img, clr, im, ax)
%% myimagesc: my version of imagesc with options I always use
%
%

if nargin < 2; clr = 'gray';  end
if nargin < 3; im  = 'image'; end
if nargin < 4; ax  = 'off';   end

% imagesc(img);
image(img, 'CDataMapping', 'Scaled');
colormap(clr);
axis(im);
axis(ax);
end