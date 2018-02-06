function [e, s] = TestHypoCotter(a, z, v)

    e = Experiment(pwd);
    e.FindGenotypes(1);
    e.Genotypes{1}.AddSeedlingsFromRange(a:z);
    s = e.Genotypes{1}.getRawSeedlings;
    e.Genotypes{1}.SortSeedlings;
    
    for i = 1:length(e.Genotypes{1}.Seedlings)
        p

    if v
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

end