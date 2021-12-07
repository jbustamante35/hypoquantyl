%% Evaluator: simple class for dealing with curves and midlines
% Used to load a curve and determine the direction it's facing (left-right)

classdef EvaluatorJB < handle & matlab.mixin.Copyable
    properties (Access = public)
        Trace
        SegmentLengths
        Corners
        Direction
        DirectionIdx
    end

    methods (Access = public)
        function obj = EvaluatorJB(varargin)
            %% Constructor method for single Cure
            if ~isempty(varargin)
                % Parse inputs to set properties
                vargs = varargin;
            else
                % Set default properties for empty object
                vargs = {};
            end

            prps   = properties(class(obj));
            deflts = {...
                'Trace', [] ; ...
                'SegmentLengths', [] ; ...
                'Corners', []};
            obj    = classInputParser(obj, prps, deflts, vargs);
        end

        function SetCorners(obj)
            %%
            %             trc   = obj.Trace;
            %             ncrns = numel(obj.SegmentLengths);
            %             crns  = arrayfun(@(x) obj.getCornerPoint( ...
            %                 trc, x, obj.SegmentLengths), (1 : ncrns)', 'UniformOutput', 0);
            %
            %             obj.Corners = cat(1, crns{:});

            ncrns       = numel(obj.SegmentLengths);
            obj.Corners = obj.getCornerPoint(1 : ncrns);
        end

        function [drc1 , drc2] = getDirection(obj)
            %% getDirection
            trc         = obj.Trace;
            seg_lengths = obj.SegmentLengths;

            l1  = obj.getSegmentLength(1, trc, seg_lengths);
            l3  = obj.getSegmentLength(3, trc, seg_lengths);

            if l3 > l1
                drc1 = 'left';
                drc2 = 1;
            else
                drc1 = 'right';
                drc2 = 0;
            end

            obj.Direction    = drc1;
            obj.DirectionIdx = drc2;
        end

        function lng = getSegmentLength(obj, num, trc, seg_length)
            %% getSegmentLength
            if nargin < 2; num        = 1;                  end
            if nargin < 3; trc        = obj.Trace;          end
            if nargin < 4; seg_length = obj.SegmentLengths; end

            seg = obj.getSegment(num, trc, seg_length);
            lng = sum(sum(diff(seg, 1, 1).^2, 2).^0.5);
        end

        function crn = getCornerPoint(obj, num, trc, seg_length)
            %% Get coordinates of corner
            if nargin < 2; num        = 1;                  end
            if nargin < 3; trc        = obj.Trace;          end
            if nargin < 4; seg_length = obj.SegmentLengths; end

            idx = obj.getIndex(num, seg_length);
            crn = trc(idx,:);
        end

        function idx = getIndex(obj, num, seg_length)
            %% Get index of corners
            if nargin < 2; num        = 1;                  end
            if nargin < 3; seg_length = obj.SegmentLengths; end

            L   = cumsum([1 , seg_length]);
            idx = L(num);
        end

        function mid = getBotMid(obj, trc, seg_length)
            %% Get midpoint of bottom segment
            if nargin < 2; trc        = obj.Trace;          end
            if nargin < 3; seg_length = obj.SegmentLengths; end

            seg = obj.getSegment(4, trc, seg_length);
            mid = mean(seg,1);
        end

        function seg = getSegment(obj, idx, trc, seg_length)
            %% Get top, bottom, left, or right
            if nargin < 2; idx        = 1;                  end
            if nargin < 3; trc        = obj.Trace;          end
            if nargin < 4; seg_length = obj.SegmentLengths; end

            switch idx
                case 1
                    str = obj.getIndex(1, seg_length);
                    stp = obj.getIndex(2, seg_length);
                case 2
                    str = obj.getIndex(2, seg_length);
                    stp = obj.getIndex(3, seg_length);
                case 3
                    str = obj.getIndex(3, seg_length);
                    stp = obj.getIndex(4, seg_length);
                case 4
                    str = obj.getIndex(4, seg_length);
                    stp = obj.getIndex(5, seg_length);
                otherwise
                    fprintf(2, '');
                    seg = [];
                    return;
            end

            seg = trc(str:stp,:);
        end
    end
end
