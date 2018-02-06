function [e, s] = TestHypoQuantyl(a, z, v)
tic;
    e = Experiment(pwd);
    e.FindGenotypes(1);
    e.Genotypes{1}.AddSeedlingsFromRange(a:z);
    s = e.Genotypes{1}.getRawSeedlings;
    e.Genotypes{1}.SortSeedlings;
    
fprintf('%d sec to analyze %d frames from %d Seedlings \n', ...
        toc,                z,             numel(e.Genotypes{1}.Seedlings));
    
    % Iterate through Seedlings and find Hypocotyl
%     for i = 1:length(e.Genotypes{1}.Seedlings)
%         p

    if v
        figure;
        
        for i  = 1 : e.Genotypes{1}.Seedlings{1}.getLifetime
            if i <= e.Genotypes{1}.Seedlings{1}.getLifetime
                subplot(331), imagesc(e.Genotypes{1}.Seedlings{1}.getImageData(i, 'Image_gray')), colormap gray, axis image, title(sprintf('Seedling %s, Frame %d', e.Genotypes{1}.Seedlings{1}.getSeedlingName, i));
                subplot(332), imagesc(e.Genotypes{1}.Seedlings{1}.getImageData(i, 'Image_BW')), colormap gray, axis image, title(sprintf('Seedling %s, Frame %d', e.Genotypes{1}.Seedlings{1}.getSeedlingName, i));
                subplot(333), imagesc(e.Genotypes{1}.Seedlings{1}.getImageData(i, 'Skeleton')), colormap gray, axis image, title(sprintf('Seedling %s, Frame %d', e.Genotypes{1}.Seedlings{1}.getSeedlingName, i));
            end

            if i <= e.Genotypes{1}.Seedlings{2}.getLifetime
                subplot(334), imagesc(e.Genotypes{1}.Seedlings{2}.getImageData(i, 'Image_gray')), colormap gray, axis image, title(sprintf('Seedling %s, Frame %d', e.Genotypes{1}.Seedlings{2}.getSeedlingName, i));
                subplot(335), imagesc(e.Genotypes{1}.Seedlings{2}.getImageData(i, 'Image_BW')), colormap gray, axis image, title(sprintf('Seedling %s, Frame %d', e.Genotypes{1}.Seedlings{2}.getSeedlingName, i));
                subplot(336), imagesc(e.Genotypes{1}.Seedlings{2}.getImageData(i, 'Skeleton')), colormap gray, axis image, title(sprintf('Seedling %s, Frame %d', e.Genotypes{1}.Seedlings{2}.getSeedlingName, i));
            end

            if i <= e.Genotypes{1}.Seedlings{3}.getLifetime
                subplot(337), imagesc(e.Genotypes{1}.Seedlings{3}.getImageData(i, 'Image_gray')), colormap gray, axis image, title(sprintf('Seedling %s, Frame %d', e.Genotypes{1}.Seedlings{3}.getSeedlingName, i));
                subplot(338), imagesc(e.Genotypes{1}.Seedlings{3}.getImageData(i, 'Image_BW')), colormap gray, axis image, title(sprintf('Seedling %s, Frame %d', e.Genotypes{1}.Seedlings{3}.getSeedlingName, i));
                subplot(339), imagesc(e.Genotypes{1}.Seedlings{3}.getImageData(i, 'Skeleton')), colormap gray, axis image, title(sprintf('Seedling %s, Frame %d', e.Genotypes{1}.Seedlings{3}.getSeedlingName, i));
            end

            pause(0.0001);
        end
    end

    if v
%         figure;
        x   = 1;
        fmt = [2 3 x];
        
        for i  = 1 : e.Genotypes{1}.Seedlings{1}.getLifetime           
            
            if i <= e.Genotypes{1}.Seedlings{x}.getLifetime
                subplot(2, 3, x), imagesc(e.Genotypes{1}.Seedlings{x}.getImageData(i, 'Image_gray')), colormap gray, axis image, title(sprintf('Seedling %s, Frame %d', e.Genotypes{1}.Seedlings{x}.getSeedlingName, i));                
            end
            x = x + 1;
            
            if i <= e.Genotypes{1}.Seedlings{x}.getLifetime
                subplot(2, 3, x), imagesc(e.Genotypes{1}.Seedlings{x}.getImageData(i, 'Image_gray')), colormap gray, axis image, title(sprintf('Seedling %s, Frame %d', e.Genotypes{1}.Seedlings{x}.getSeedlingName, i));                
            end
            x = x + 1;
            
            if i <= e.Genotypes{1}.Seedlings{x}.getLifetime
                subplot(2, 3, x), imagesc(e.Genotypes{1}.Seedlings{x}.getImageData(i, 'Image_gray')), colormap gray, axis image, title(sprintf('Seedling %s, Frame %d', e.Genotypes{1}.Seedlings{x}.getSeedlingName, i));                
            end
            x = x + 1;
            
            if i <= e.Genotypes{1}.Seedlings{x}.getLifetime
                subplot(2, 3, x), imagesc(e.Genotypes{1}.Seedlings{x}.getImageData(i, 'Image_gray')), colormap gray, axis image, title(sprintf('Seedling %s, Frame %d', e.Genotypes{1}.Seedlings{x}.getSeedlingName, i));                
            end
            x = x + 1;
            
            if i <= e.Genotypes{1}.Seedlings{x}.getLifetime
                subplot(2, 3, x), imagesc(e.Genotypes{1}.Seedlings{x}.getImageData(i, 'Image_gray')), colormap gray, axis image, title(sprintf('Seedling %s, Frame %d', e.Genotypes{1}.Seedlings{x}.getSeedlingName, i));                
            end            
            
            x = 1;
            pause(0.0001);
        end
    end
    
    
    
end