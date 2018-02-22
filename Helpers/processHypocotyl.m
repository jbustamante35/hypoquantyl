function img_out = processHypocotyl(img_input, anchor_points, scale_size)
%% processHypocotyl: one-line description
%  Detailed Summary
%   
%  Usage: 
%      [output1, output2] = functionName(input1, input2)
%   
%  Input:
%      input1: input1 summary
%      input2: input2 summary
%  
%  Output:
%      output1: output1 summary
%      output2: output2 summary

%%
    crp1    = [0 0 anchor_points(4,1) anchor_points(2,2)]; % Crop region containing PreHypocotyl
    cim1    = imcrop(img_input, crp1);                     % Crop image of PreHypocotyl
    img_out = imresize(cim1, scale_size);                  % Final rescaled image 

end