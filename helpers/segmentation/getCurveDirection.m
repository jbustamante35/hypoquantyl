function [drc , dorg] = getCurveDirection(trc, seg_lengths)
%% getCurveDirection
%
%
% Usage:
%   [drc , dorg] = getCurveDirection(trc, seg_lengths)
%
% Input:
%   trc:
%   seg_lengths:
%
% Output:
%   drc:
%   dorg:
%

if nargin < 2; seg_lengths = [53 , 52 , 53 , 51]; end

eorg = EvaluatorJB('Trace', trc, 'SegmentLengths', seg_lengths);
dorg = eorg.getDirection;

drc = 1;
if strcmpi(dorg, 'left'); drc = -1; end
end
