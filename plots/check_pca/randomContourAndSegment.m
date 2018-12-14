function [cIdx, cntr, crvs, segs, sIdx] = randomContourAndSegment(cntrs, rndFun)
%% randomContourAndSegment: define randomized contour and segment
% This function draws from an array of CircuitJB objects and extracts a random 
% CircuitJB object, it's corresponding Curve object, and a random segment from 
% that curve. User is only provided the index of the segment, rather than the 
% segment itself. The randomization function is provided by the user, but if 
% set to false, the default is the following:
%   rndFun = @(x) randi([1 length(x)], 1)
%
% Usage:
%   [cIdx, cntr, crvs, segs, sIdx] = randomContourAndSegment(cntrs, rndFun)
%
% Input:
%   cntrs: object array of CircuitJB objects to draw from
%   rndFun: function handle to draw from a random selection
%
% Output:
%   cIdx: index of CircuitJB object taken from array
%   cntr: handle to chosen CircuitJB object
%   crvs: handle to child Curve object from chosen cntr
%   segs: total number of segment around cntr
%   sIdx: index of segment chosen from crvs
%

if ~isa(rndFun, 'function_handle')
    rndFun = @(x) randi([1 length(x)], 1);
end

cIdx = rndFun(cntrs);
cntr = cntrs(cIdx);
crvs = cntr.Curves;
segs = crvs.NumberOfSegments;
sIdx = rndFun(1 : segs);

end
