function validContourPlot(xData, yData, idx, col)
%% validContourPlot: overlay inputted contour onto simulated contour after PCA
% Input:
%
%
% Output:
%
%

for i = idx
    plt([xData.InputData(i,:) ; yData.InputData(i,:)]', 'k--', 5);
    plt([xData.SimData(i,:)   ; yData.SimData(i,:)]', col, 5);
end

end