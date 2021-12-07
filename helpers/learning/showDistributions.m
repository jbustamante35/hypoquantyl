function fnms = showDistributions(scrs, fidx)
%% plotScores
npz  = size(scrs,2);
rows = npz;
cols = npz;

figclr(fidx);
x = 1;
for i = 1 : npz
    for ii = 1 : npz
        subplot(rows, cols, x);
        plt([scrs(:,i) , scrs(:,ii)], 'k.', 5);
        xlabel(sprintf('PC%d', i), 'FontWeight', 'b');
        ylabel(sprintf('PC%d', ii), 'FontWeight', 'b');
        drawnow;
        x = x + 1;
    end
end

fnms = sprintf('%s_scoredistribution_%dPCs', tdate, npz);

end
