%% Skeleton: class for handling skeletons to generate midlines
% Description

classdef Skeleton < handle
    properties (Access = public)
        Image
        Contour
        Mask
        Coordinates
        Graph
        Joints
        TotalJoints
        Bones
        TotalBones
        EndPoints
        BranchPoints
        EndIndex                  % End Point indices along the Skeleton
        BranchIndex               % Branch Point indices along the Skeleton
        Routes
    end

    properties (Access = protected)
        MASKSIZE = [101 , 101]    % Size of mask image
        THRESH   = sqrt(2) + eps; % Distance threshold between Graph nodes
        TotalEndPoints            % Total number of end points
        TotalBranchPoints         % Total number of branch points
        KernelEndPoints           % EndPoints identified by the Kernel
        KernelBranchPoints        % BranchPoitns identified by the Kernel
        ENDVALUES    = 1          % EndPoint pixel value from kernel image
        BRANCHVALUES = 3          % BranchPoint pixel value from kernel image
        Kernel                    % Kernel used for convolving through the mask
        KernelImage               % Colvolution image from kernel on mask
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
                args = varargin;
            else
                % Set default properties for empty object
                args = {};
            end

            prps   = properties(class(obj));
            deflts = { ...
                'Joints', repmat(Joint, 0); ...
                'TotalJoints', 0; ...
                'Bones', repmat(Bone, 0); ...
                'TotalBones', 0; ...
                'Routes', struct('Ends2Branches', [], 'Ends2Ends', [], ...
                'Branches2Branches', [], 'Branches2Ends', [])};
            obj = classInputParser(obj, prps, deflts, args);
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
            obj.EndIndex          = eidxs;
            obj.BranchIndex       = bidxs;
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
            obj.KernelImage        = Kimg;
            obj.Kernel             = K;
            obj.KernelMidpoint     = kmid;
            obj.KernelEndPoints    = kepcrds;
            obj.KernelBranchPoints = kbrcrds;

        end

        function obj = MakeJoints(obj)
            %% Convert BranchPoints to Joint objects
            bcrds = obj.BranchPoints;

            % Create the children
            BCH = arrayfun(@(x) Joint('Coordinate', bcrds(x,:)), ...
                1 : obj.TotalBranchPoints, 'UniformOutput', 0);

            cellfun(@(x) obj.setJoint(x), BCH, 'UniformOutput', 0);

            % Find each child's neighbors
            cellfun(@(x) x.FindNeighbors, BCH, 'UniformOutput', 0);


        end

    end


    %% -------------------------- Helper Methods ---------------------------- %%
    methods (Access = public)
        function [b2b , B2B] = branch2branches(obj, sIdx)
            %% branches2branches: get paths from branches to other branches
            s           = obj.BranchIndex(sIdx);
            e           = obj.BranchIndex;
            [b2b , B2B] = obj.path2ClosestNode(s, e);

        end

        function [b2e , B2E] = branch2ends(obj, sIdx)
            %% branches2ends: get paths from branches to end points
            s           = obj.BranchIndex(sIdx);
            e           = obj.EndIndex;
            [b2e , B2E] = obj.path2ClosestNode(s, e);

        end

        function [e2b , E2B] = end2branches(obj, sIdx)
            %% ends2branches: get paths from branches to other branches
            s           = obj.EndIndex(sIdx);
            e           = obj.BranchIndex;
            [e2b , E2B] = obj.path2ClosestNode(s, e);

        end

        function [e2e , E2E] = end2ends(obj, sIdx)
            %% ends2ends: get paths from branches to end points
            s           = obj.EndIndex(sIdx);
            e           = obj.EndIndex;
            [e2e , E2E] = obj.path2ClosestNode(s, e);

        end

        function [n2e , N2E] = node2ends(obj, nIdx)
            %% node2ends: get paths from node to end points
            eIdx        = obj.EndIndex;
            [n2e , N2E] = obj.path2ClosestNode(nIdx, eIdx);
        end

        function [n2b , N2B] = node2branches(obj, nIdx)
            %% node2ends: get paths from node to end points
            bIdx        = obj.BranchIndex;
            [n2b , N2B] = obj.path2ClosestNode(nIdx, bIdx);
        end

        function bch = getJoint(obj, bIdx)
            %% Return Joint object
            if nargin < 2
                bIdx = 1 : obj.TotalJoints;
            end

            try
                bch = obj.Joints(bIdx);
            catch
                fprintf(2, 'Error returning Joint at index %d\n', bIdx);
                bch = [];
            end
        end

        function setJoint(obj, bch, bIdx)
            %% Set Joint object
            if nargin < 3
                bIdx = obj.TotalJoints + 1;
            end

            try
                % Find Matching index
                sklIdx              = find(pdist2(bch.Coordinate, obj.Coordinates) == 0);
                bch.Parent          = obj;
                bch.IndexInSkeleton = sklIdx;
                obj.Joints(bIdx)    = bch;
                obj.TotalJoints     = bIdx;
            catch e
                fprintf(2, 'Error setting Joint at index %d\n%s\n', ...
                    bIdx, e.getReport);
            end
        end

        function prp = getProperty(obj, req)
            %% Return any property (for getting private properties)
            try
                prp = obj.(req);
            catch
                fprintf(2, 'Error returning %s property\n', req);
                prp = [];
            end
        end

        function setProperty(obj, prp, val)
            %% Set property for this object
            try
                prps = properties(obj);

                if sum(strcmp(prps, prp))
                    obj.(prp) = val;
                else
                    fprintf('Property %s not found\n', prp);
                end
            catch e
                fprintf(2, 'Can''t set %s to %s\n%s', ...
                    prp, string(val), e.getReport);
            end

        end
    end

    %% ------------------------- Private Methods --------------------------- %%
    methods (Access = private)
        function [r , R] = path2ClosestNode(obj, s, e)
            %% path2ClosestNode: returns paths to nearest node
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
            R = cellfun(@(x) skl(x,:), gma, 'UniformOutput', 0);
            r = R{minIdx};
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

