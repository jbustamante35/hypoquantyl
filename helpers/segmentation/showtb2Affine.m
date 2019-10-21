function showtb2Affine(img, affine_stack, scls)
%% showtb2Affine:
%

cla;clf;
imshow(img, []);
hold on;

for s = 1 : size(affine_stack,4)
    cla;clf;
    imshow(img, []);
    hold on;
    for e = 1 : size(affine_stack,1)
        p = squeeze(affine_stack(e,1:2,3,s));
        tng = squeeze(affine_stack(e,1:2,1,s));
        nrm = squeeze(affine_stack(e,1:2,2,s));
        
        plot(p(1), p(2), 'r.');
        quiver(p(1), p(2), tng(1), tng(2), 'Color', 'g');
        quiver(p(1), p(2), nrm(1), nrm(2), 'Color', 'b');        
    end
    ttl = sprintf('%s', num2str(scls(1,:)));
    title(ttl);
    hold off;
    waitforbuttonpress;
end


end