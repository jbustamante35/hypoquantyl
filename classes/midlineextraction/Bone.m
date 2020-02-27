%% Bone : class for handling midline segments from the Skeleton parent class
% Description


classdef Bone < handle
    properties (Access = public)
        Parent
        Coordinate
    end

    properties (Access = protected)
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
            deflts = {};
            obj    = classInputParser(obj, prps, deflts, args);

        end


    end

    %% -------------------------- Helper Methods ---------------------------- %%
    methods (Access = public)

    end

    %% ------------------------- Private Methods --------------------------- %%
    methods (Access = private)

    end

end


