%% Bone : class for handling midline segments from the Skeleton parent class
% Description


classdef Bone < handle
    properties (Access = public)
        Parent
        Coordinates
        IndexInSkeleton
        Length
        Joints
        JointIndex
    end
    
    properties (Access = protected)
        SAMPLEDISTANCE = 10 % Distance to spread coordinage sampling of image
    end
    
    %% ------------------------ Main Methods -------------------------------- %%
    methods (Access = public)
        function obj = Bone (varargin)
            %% Constructor method to generate a BranchChild object
            if ~isempty(varargin)
                % Parse inputs to set properties
                args = varargin;
            else
                % Set default properties for empty object
                args = {};
            end
            prps   = properties(class(obj));
            deflts = { ...
                'Coordinates', [0 0] ; ...
                'IndexInSkeleton', 0 ; ...
                'Length', 0};
            obj    = classInputParser(obj, prps, deflts, args);
            
        end
        
        function obj = FindIndexInSkeleton(obj)
            %% Find corresponding Nodes for each coordinate
            
        end
        
        function [Q , qd] = SampleSegment(obj, interp_length, sample_distance)
            %%
            switch nargin 
                case 1
                    interp_length   = size(obj.Coordinates, 1);
                    sample_distance = obj.SAMPLEDISTANCE;
                case 2
                    sample_distance = obj.SAMPLEDISTANCE;
                case 3
                otherwise
                    fprintf(2, 'Error with inputs [%d]\n', nargin);
                    return;
            end
            
            rt       = interpolateOutline(obj.Coordinates, interp_length);
            img      = obj.Parent.Image;
            bg       = median(img, 'all');            
            [Q , qd] = getStraightenedMask(rt, img, 0, sample_distance, bg);
            Q        = flipud(Q);
            
        end
        
    end
    
    %% -------------------------- Helper Methods ---------------------------- %%
    methods (Access = public)
        function j = getJoint(obj, jIdx)
            %% Return a Joint
            if nargin < 2
                jIdx = 1 : 2;
            end
            
            try
                j = obj.Joints(jIdx);
            catch
                fprintf(2, 'Error returning Joint at index %d\n', jIdx);
                j = [];
            end
        end
        
        function jprop = getJointProp(obj, jIdx, req)
            %% Return a property of a Joint
            switch nargin
                case 1
                    jIdx = 1 : 2;
                    req  = 'all';
                case 2
                    req = 'all';
                case 3
                otherwise
                    fprintf(2, 'Too many input arguments [%d]\n', nargin);
                    jprop = [];
                    return;
            end
            
            % Get the property (or properties) from the Joint
            try                
                if strcmpi(req, 'all')
                    if numel(jIdx) > 1
                        jprop = cell2mat(arrayfun(@(x) struct(obj.Joints(x)), ...
                            jIdx, 'UniformOutput', 0)');
                    else
                        jprop = struct(obj.Joints(jIdx));
                    end
                else
                    if numel(jIdx) > 1
                        jprop = cell2mat(arrayfun(@(x) obj.Joints(x).(req), ...
                            jIdx, 'UniformOutput', 0)');
                    else                        
                        jprop = obj.Joints(jIdx).(req);
                    end
                end
            catch
                fprintf(2, 'Error retrieving %s from Joint %d\n', req, jIdx);
                jprop = [];
            end
        end
    end
    
    %% ------------------------- Private Methods --------------------------- %%
    methods (Access = private)
        
    end
    
end


