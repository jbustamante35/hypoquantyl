%% Skeleton: class for handling skeletons to generate midlines
% Description

classdef Skeleton < handle
    properties (Access = public)
        Image
        Contour
        Mask
        Coordinates
        Graph
        EndPoints
        BranchPoints
        KernelEndPoints
        KernelBranchPoints
        Routes
    end
    
    properties (Access = protected)
        MASKSIZE = [101 , 101]    % Size of mask image
        THRESH   = sqrt(2) + eps; % Distance threshold between Graph nodes
        EndIndex                  % End Point indices along the Skeleton
        BranchIndex               % Branch Point indices along the Skeleton
        TotalEndPoints            % Total number of end points
        TotalBranchPoints         % Total number of branch points
        ENDVALUES    = 1          % EndPoint pixel value from kernel image
        BRANCHVALUES = 3          % BranchPoint pixel value from kernel image
        Kernel                    % Kernel used for convolving through the mask
        KernelMidpoint            % Midpoint coordinate of the Kernel
        KERNELSIZE  = 3           % Side length of the square kernel
        KERNELVALUE = 1           % Values within the kernel
    end
    
    %%
    methods (Access = public)
        %% Constructor and primary methods
        function obj = Skeleton(varargin)
            %% Constructor method to generate a Skeleton object
            if ~isempty(varargin)
                % Parse inputs to set properties
                prps = properties(class(obj));
                obj  = classInputParser(obj, prps, varargin);
                
            else
                % Set default properties for empty object
                obj.Routes = struct('Ends2Branches', [], 'Ends2Ends', [], ...
                    'Branches2Branches', [], 'Branches2Ends', []);
            end
            
        end
        
        function obj = Contour2Skeleton(obj, cntr)
            %% Process the contour to obtain the skeleton image and coordinates
            if nargin < 2
                cntr = obj.Contour;
            end
            
            imSz = obj.MASKSIZE;
            
            % Get skeleton, end points, and branch points
            [skltn, bmrph] = bwmorphjb(cntr, imSz);
            [ecrds , ~]    = bwmorphjb(bmrph, imSz, 'endpoints');
            [bcrds , ~]    = bwmorphjb(bmrph, imSz, 'branchpoints');
            
            % Compute inter-skeleton distances between end and branch points
            [~, eidxs] = find((pdist2(ecrds, skltn)) == 0);
            [~, bidxs] = find((pdist2(bcrds, skltn)) == 0);
            
            % Store class properties
            obj.Coordinates       = skltn;
            obj.Mask              = bmrph;
            obj.EndPoints         = ecrds;
            obj.BranchPoints      = bcrds;
            obj.EndIndex        = eidxs;
            obj.BranchIndex     = bidxs;
            obj.TotalEndPoints    = numel(eidxs);
            obj.TotalBranchPoints = numel(bidxs);
            
        end
        
        function obj = CreateGraph(obj)
            %% Generate the Graph Diagram for various algorithms
            skltn = obj.Coordinates;
            thrsh = obj.THRESH;
            
            % Squared distances from each node to the other
            sqrdist                  = squareform(pdist(skltn));
            sqrdist(sqrdist > thrsh) = 0;
            [n1 , n2]                = find(sqrdist ~= 0);
            d                        = sqrdist(sqrdist ~= 0);
            
            % Make graph diagram with distances as weights
            g         = digraph(n1, n2, d);
            obj.Graph = g;
            
        end
        
        function obj = FindBranchRoutes(obj)
            %% All routes from BranchPoints
            b   = 1 : obj.TotalBranchPoints;
            B2B = arrayfun(@(x) obj.branch2branches(x), b, 'UniformOutput', 0);
            B2E = arrayfun(@(x) obj.branch2ends(x), b, 'UniformOutput', 0);
            
            % Store class properties
            obj.Routes.Branches2Branches = B2B;
            obj.Routes.Branches2Ends     = B2E;
        end
        
        function obj = FindEndRoutes(obj)
            %% All routes from EndPoints
            e   = 1 : obj.TotalEndPoints;
            E2B = arrayfun(@(x) obj.end2branches(x), e, 'UniformOutput', 0);
            E2E = arrayfun(@(x) obj.end2ends(x), e, 'UniformOutput', 0);
            
            % Store class properties
            obj.Routes.Ends2Branches = E2B;
            obj.Routes.Ends2Ends     = E2E;
        end
        
        function obj = ConvolveSkeleton(obj)
            %% Convolution kernel across the skeleton
            % Prepare kernel
            if isempty(obj.Kernel)
                [K , kmid]    = obj.generateKernel;
                K(kmid, kmid) = 0;
            end
            
            % Get properties
            bmrph    = obj.Mask;
            skltn    = obj.Coordinates;
            epValues = obj.ENDVALUES;
            brValues = obj.BRANCHVALUES;
            
            % Convolution to identify branch and end points
            Kimg    = conv2(bmrph, K, 'same');
            Kvals   = ba_interp2(Kimg, skltn(:,1), skltn(:,2));
            brIdxs  = Kvals >= brValues;
            epIdxs  = Kvals == epValues;
            kbrcrds = skltn(brIdxs,:); % Branch Points identified on kernel
            kepcrds = skltn(epIdxs,:); % End Points identified on kernel
            
            % Store class properties
            obj.KernelEndPoints    = kepcrds;
            obj.KernelBranchPoints = kbrcrds;
            
        end
        
    end
    
    
    %% -------------------------- Helper Methods ---------------------------- %%
    methods (Access = public)        
        function b2b = branch2branches(obj, sIdx)
            %% branches2branches: get paths from branches to other branches
            s   = obj.BranchIndex(sIdx);
            e   = obj.BranchIndex;
            b2b = obj.path2ClosestNode(s, e);
            
        end
        
        function b2e = branch2ends(obj, sIdx)
            %% branches2ends: get paths from branches to end points
            s   = obj.BranchIndex(sIdx);
            e   = obj.EndIndex;
            b2e = obj.path2ClosestNode(s, e);
            
        end
        
        function e2b = end2branches(obj, sIdx)
            %% ends2branches: get paths from branches to other branches
            s   = obj.EndIndex(sIdx);
            e   = obj.BranchIndex;
            e2b = obj.path2ClosestNode(s, e);
            
        end
        
        function e2e = end2ends(obj, sIdx)
            %% ends2ends: get paths from branches to end points
            s   = obj.EndIndex(sIdx);
            e   = obj.EndIndex;
            e2e = obj.path2ClosestNode(s, e);
            
        end
        
    end
    
    %% ------------------------- Private Methods --------------------------- %%
    methods (Access = private)
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
        
        function [K , Kmid] = generateKernel(obj, ksz, vals)
            %% generateKernel:
            % This function creates a single-value square matrix and returns the
            % middle coordinate
            if nargin < 2
                ksz  = obj.KERNELSIZE;
                vals = obj.KERNELVALUE;
            end
            
            K    = repmat(vals, ksz, ksz);
            Kmid = ceil(ksz / 2);
        end
    end
    
end

