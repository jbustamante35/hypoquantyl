%% Skeleton: class for handling skeletons to generate midlines
% Description


classdef Skeleton < handle
    properties (Access = public)
        Parent
        Mask
        Coordinates
        Graph
        EndPoints
        BranchPoints
        TotalEndPoints
        TotalBranchPoints
        Kernel
        Routes
    end
    
    properties (Access = protected)
        MASKSIZE = [101 , 101] % Size of mask image
        KernelMidpoint         % Midpoint coordinate of the Kernel
        EndIndices             % End Point Indices along the Skeleton 
        BranchIndices          % Branch Point Indices along the Skeleton 
    end
    
    %%
    methods (Access = public)
        %% Constructor and primary methods
        function obj = Skeleton(varargin)
            %% Constructor method to generate a Skeleton object
            if ~isempty(varargin)
                % Parse inputs to set properties
                args = obj.parseConstructorInput(varargin);
                
                fn = fieldnames(args);
                for k = fn'
                    obj.(cell2mat(k)) = args.(cell2mat(k));
                end
                
            else
                % Set default properties for empty object
            end
            
        end
        
        function [B2B , B2E] = BranchRoutes(obj)
            %% All routes from BranchPoints
            b   = 1 : obj.TotalBranchPoints;
            B2B = arrayfun(@(x) obj.branch2branches(x), b, 'UniformOutput', 0);
            B2E = arrayfun(@(x) obj.branch2ends(x), b, 'UniformOutput', 0);
        end
        
        function [E2B , E2E] = EndRoutes(obj)
            %% All routes from EndPoints            
            e   = 1 : obj.TotalEndPoints;
            E2B = arrayfun(@(x) obj.end2branches(x), e, 'UniformOutput', 0);
            E2E = arrayfun(@(x) obj.end2ends(x), e, 'UniformOutput', 0);
        end
        
    end
    
    
    %% Helper functions
    methods (Access = public)
        function X = helperfunction(varargin)
            %%
            X = [];
        end
        
        function b2b = branch2branches(obj, sIdx)
            %% branches2branches: get paths from branches to other branches
            s   = obj.BranchIndices(sIdx);
            e   = obj.BranchIndices;
            b2b = obj.path2ClosestNode(s, e);
            
        end
        
        function b2e = branch2ends(obj, sIdx)
            %% branches2ends: get paths from branches to end points
            s   = obj.BranchIndices(sIdx);
            e   = obj.EndIndices;
            b2e = obj.path2ClosestNode(s, e);
            
        end
        
        function e2b = end2branches(obj, sIdx)
            %% ends2branches: get paths from branches to other branches
            s   = obj.EndIndices(sIdx);
            e   = obj.BranchIndices;
            e2b = obj.path2ClosestNode(s, e);
            
        end
        
        function e2e = end2ends(obj, sIdx)
            %% ends2ends: get paths from branches to end points
            s   = obj.EndIndices(sIdx);
            e   = obj.EndIndices;
            e2e = obj.path2ClosestNode(s, e);
            
        end
        
    end
    
    %% Private functions
    methods (Access = private)
        function args = parseConstructorInput(varargin)
            %% Parse input parameters for Constructor method
            p = inputParser;
            p.addOptional('Parent', Hypocotyl);
            p.addOptional('Mask', []);
            p.addOptional('Coordinates', []);
            p.addOptional('Graph', []);
            p.addOptional('BranchPoints', []);
            p.addOptional('EndPoints', []);
            p.addOptional('TotalBranchPoints', []);
            p.addOptional('TotalEndPoints', []);
            p.addOptional('Kernel', []);
            p.addOptional('Routes', []);
            p.addOptional('BranchIndices', []);
            p.addOptional('EndIndices', []);
            
            % Parse arguments and output into structure
            p.parse(varargin{2}{:});
            args = p.Results;
        end
        
        function R = path2ClosestNode(obj, s, e)
            %% findNearestNodes: returns paths to nearest points
            g   = obj.Graph;
            skl = obj.Coordinates;
            
            % Iterate through all starting points to find closest Branch Point
            gsz    = numel(e);
            gma    = cell(1, gsz);
            dst    = zeros(1, gsz);
            
            % Compute the shortest path between each node
            for b = 1 : numel(e)
                [gma{b}, dst(b)] = g.shortestpath(s, e(b));
            end
            
            % Replace 0 with Inf (don't find self path)
            dst(dst == 0) = Inf;
            
            % Get the minimum distance from the set of paths
            [~, minIdx] = min(dst);
            
            % Identify path to closest branch point
            R = skl(gma{minIdx},:);
        end
        
        function obj = generateKernel(obj, ksz, vals)
            %% generateKernel:
            % This function creates a single-value square matrix and returns the
            % middle coordinate
            if nargin < 2
                vals = 0;
            end            
            
            obj.Kernel = repmat(vals, ksz, ksz);
            obj.KernelMidpoint = ceil(ksz / 2);
        end
    end
    
end

