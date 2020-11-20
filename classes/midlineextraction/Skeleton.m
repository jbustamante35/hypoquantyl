%% Skeleton: class for handling skeletonized contours to generate midlines
% Description

classdef Skeleton < handle
    properties (Access = public)
        Parent
        Image
        Contour
        Mask
        Coordinates
        Graph
        Joints
        TotalJoints
        BoneJointIndex
        Bones
        TotalBones
        EndPoints
        BranchPoints
        EndIndex                  % End Point indices along the Skeleton
        BranchIndex               % Branch Point indices along the Skeleton
        StartPoint
        Routes
    end
    
    properties (Access = protected)
        MASKSIZE = [101 , 101]    % Size of mask image
        THRESH   = sqrt(2) + eps; % Distance threshold between Graph nodes
        ENVELOPEDISTANCE = 10     % Distance to set envelope when sampling image
        SAMPLEDISTANCE   = 10     % Distance to spread coordinage sampling of image
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
            'TotalBones', 0};
        obj = classInputParser(obj, prps, deflts, args);
        end
        
        function obj = Contour2Skeleton(obj, cntr)
        %% Process the contour to obtain the skeleton image and coordinates
        if nargin < 2
            cntr = obj.Contour;
        end
        
        imSz = obj.MASKSIZE;
        
        % Get skeleton, end points, and branch points
        [~, bmrph]     = bwmorphjb(cntr, imSz);
        [skltn, bmrph] = bwmorphjb(bmrph, imSz, 'thin', Inf, 0);
        [ecrds , ~]    = bwmorphjb(bmrph, imSz, 'endpoints');
        [bcrds , ~]    = bwmorphjb(bmrph, imSz, 'branchpoints');
        
        % Compute inter-skeleton distances between end and branch points
        [~, eidxs] = find((pdist2(ecrds, skltn)) == 0);
        [~, bidxs] = find((pdist2(bcrds, skltn)) == 0);
        
        % Remove intersection points through contour
        % [xi , yi] = polyxpoly(skltn(:,1), skltn(:,2), cntr(:,1), cntr(:,2), 'unique');
        % [ai , bi] = polyxpoly(cntr(:,1), cntr(:,2), skltn(:,1), skltn(:,2), 'unique');
        
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
        
        function obj = FindStartPoint(obj)
        %% Find initial EndPoint
        ecrds = cell2mat(arrayfun(@(x) x.Coordinate, ...
            obj.Joints, 'UniformOutput', 0)');
        eidx  = getLowestIndex(ecrds);
        einit = obj.getJoint(eidx);
        
        obj.StartPoint = einit;
        end
        
        function obj = FindRoutesFromStartPoint(obj)
        %% Generate all Routes from starting point to all End Points
        if isempty(obj.StartPoint)
            obj.FindStartPoint;
        end
        startIdx  = obj.StartPoint.IndexInSkeleton == obj.EndIndex;
        [~ , E2E] = obj.end2ends(startIdx);
        
        obj.Routes = E2E;
        
        end
        
        function obj = MakeJoints(obj)
        %% Convert BranchPoints to Joint objects
        bcrds = obj.BranchPoints;
        ecrds = obj.EndPoints;
        
        % Create the children from EndPoints and BranchPoints
        BCH = arrayfun(@(x) ...
            Joint('Coordinate', bcrds(x,:), 'JointType', 'BranchJoint'), ...
            1 : obj.TotalBranchPoints, 'UniformOutput', 0);
        
        EPT = arrayfun(@(x) ...
            Joint('Coordinate', ecrds(x,:), 'JointType', 'EndJoint'), ...
            1 : obj.TotalEndPoints, 'UniformOutput', 0);
        
        % Reset Joints
        obj.Joints      =  repmat(Joint, 0);
        obj.TotalJoints = 0;
        
        cellfun(@(x) obj.setJoint(x), BCH, 'UniformOutput', 0);
        cellfun(@(x) obj.setJoint(x), EPT, 'UniformOutput', 0);
        
        % Find each Joints's neighbors
        cellfun(@(x) x.FindNeighbors, BCH, 'UniformOutput', 0);
        cellfun(@(x) x.FindNeighbors, EPT, 'UniformOutput', 0);
        
        end
        
        function obj = MakeBones(obj)
        %% Connect segments between Joints to generate Bone objects
        % Search for all shared paths and create Bone objects
        [JP , JI] = deal(cell(obj.TotalJoints, 1));
        for i = 1 : obj.TotalJoints
            j1 = i;
            for ii = 1 : obj.TotalJoints
                j2 = ii;
                [JP{i}{ii} , JI{i}{ii}] = obj.checkJointConnection(j1, j2);
            end
        end
        JP = cat(1, JP{:});
        JI = cat(1, JI{:});
        
        % Get all indices with matching paths and remove duplicates
        jpcat      = ~cellfun(@isempty, JP);
        [c1 , c2]  = find(jpcat);
        [~ , uidx] = unique(sort([c1 , c2], 2), 'rows');
        u1         = c1(uidx);
        u2         = c2(uidx);
        
        % Create Bones from pairs
        B = repmat(Bone, 1, numel(uidx));
        for i = 1 : numel(uidx)
            idx1 = u1(i);
            idx2 = u2(i);
            j    = JP{idx1,idx2};
            k    = JI{idx1,idx2};
            B(i) = obj.createBone(idx1, idx2, j, k);
        end
        
        % Reset Joints
        obj.Bones          = repmat(Bone, 0);
        obj.TotalBones     = 0;
        obj.Bones          = B;
        obj.TotalBones     = numel(B);
        obj.BoneJointIndex = [(1 : obj.TotalBones)' , u1 , u2];
        
        end
        
        function [Q , qd] = SampleRoute(obj, rtIdx)
        %%
        rt       = obj.Routes{rtIdx};
        img      = obj.Image;
        edst     = obj.SAMPLEDISTANCE;
        bg       = median(img, 'all');
        [Q , qd] = getStraightenedMask(rt, img, 0, edst, bg);
        Q        = flipud(Q);
        
        end
        
        function obj = RunPipeline(obj, id)
        %% Run through main methods
        % I omitted ConvolveSkeleton because I don't do anything with it
        if nargin < 2
            id = '';
        end
        
        sprA = repmat('=', 1, 80);
        sprB = repmat('-', 1, 80);
        ellp = @(x) repmat('.', 1, 80 - (length(x) + 13));
        
        tAll = tic;
        fprintf('\n%s\nCreating Skeleton [%s]\n%s\n', sprA, id, sprB);
        
        t = tic;
        obj.Contour2Skeleton;
        str  = sprintf('Contour2Skeleton');
        fprintf('%s%s [ %.02f sec ]\n', str, ellp(str), toc(t));
        
        t = tic;
        obj.CreateGraph;
        str  = sprintf('CreateGraph');
        fprintf('%s%s [ %.02f sec ]\n', str, ellp(str), toc(t));
        
        t = tic;
        obj.MakeJoints;
        str  = sprintf('MakeJoints ');
        fprintf('%s%s [ %.02f sec ]\n', str, ellp(str), toc(t));
        
        t = tic;
        obj.MakeBones;
        str  = sprintf('MakeBones');
        fprintf('%s%s [ %.02f sec ]\n', str, ellp(str), toc(t));
        
        t = tic;
        obj.FindRoutesFromStartPoint;
        str  = sprintf('FindRoutesFromStartPoint');
        fprintf('%s%s [ %.02f sec ]\n', str, ellp(str), toc(t));
        
        str = sprintf('DONE | %d Nodes | %d Joints | %d Segments | %d Routes', ...
            size(obj.Coordinates, 1), obj.TotalJoints, ...
            obj.TotalBones, numel(obj.Routes));
        fprintf('%s\n%s%s.[ %.02f sec ]\n%s\n', ...
            sprB, str, ellp(str), toc(tAll), sprA);
        end
        
        function obj = ConvolveSkeleton(obj)
        %% Convolution kernel across the skeleton
        % Prepare kernel
        if isempty(obj.Kernel)
            [K , kmid]    = obj.generateKernel;
            K(kmid, kmid) = 0;
        else
            K    = obj.Kernel;
            kmid = obj.KernelMidpoint;
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
    end
    
    
    %% -------------------------- Helper Methods ---------------------------- %%
    methods (Access = public)
        function [b2b , B2B, P] = branch2branches(obj, sIdx, typ)
        %% branches2branches: get paths from branches to other branches
        if nargin < 3
            typ = 'shortest';
        end
        
        switch typ
            case 'shortest'
                %% Search through shortest paths to other branches
                s             = obj.BranchIndex(sIdx);
                e             = obj.BranchIndex;
                [b2b, B2B, P] = obj.path2ClosestNode(s, e);
            case 'all'
                %% Search through all possible paths
                % This omits paths that intersect the contour
                s             = obj.BranchIndex(sIdx);
                e             = obj.BranchIndex;
                [b2b, B2B, P] = obj.path2ClosestNode(s, e, 1);
        end
        
        end
        
        function [b2e , B2E, P] = branch2ends(obj, sIdx)
        %% branches2ends: get paths from branches to end points
        s             = obj.BranchIndex(sIdx);
        e             = obj.EndIndex;
        [b2e, B2E, P] = obj.path2ClosestNode(s, e);
        end
        
        function [e2b , E2B, P] = end2branches(obj, sIdx)
        %% ends2branches: get paths from branches to other branches
        s             = obj.EndIndex(sIdx);
        e             = obj.BranchIndex;
        [e2b, E2B, P] = obj.path2ClosestNode(s, e);
        end
        
        function [e2e , E2E, P] = end2ends(obj, sIdx)
        %% ends2ends: get paths from branches to end points
        s             = obj.EndIndex(sIdx);
        e             = obj.EndIndex;
        [e2e, E2E, P] = obj.path2ClosestNode(s, e);
        end
        
        function [n2e , N2E, P] = node2ends(obj, nIdx)
        %% node2ends: get paths from node to end points
        eIdx          = obj.EndIndex;
        [n2e, N2E, P] = obj.path2ClosestNode(nIdx, eIdx);
        end
        
        function [n2b , N2B, P] = node2branches(obj, nIdx)
        %% node2ends: get paths from node to end points
        bIdx          = obj.BranchIndex;
        [n2b, N2B, P] = obj.path2ClosestNode(nIdx, bIdx);
        end
        
        function crd = node2skeleton(obj, nidx)
        %% Convert node index to index in skeleton
        crd = obj.Coordinates(nidx,:);
        
        end
        
        function j = getJoint(obj, jIdx)
        %% Return Joint object
        if nargin < 2
            jIdx = 1 : obj.TotalJoints;
        end
        
        try
            j = obj.Joints(jIdx);
        catch
            fprintf(2, 'Error returning Joint at index %d\n', jIdx);
            j = [];
        end
        end
        
        function E = getEndJoints(obj)
        %% Returns all EndJoints
        J = obj.getJoint;
        E = J(cell2mat(cellfun(@(x) isequal('EndJoint', x), ...
            arrayfun(@(y) y.JointType, ...
            J, 'UniformOutput', 0), 'UniformOutput', 0)));
        
        end
        
        function B = getBranchJoints(obj)
        %% Returns all EndJoints
        J = obj.getJoint;
        B = J(cell2mat(cellfun(@(x) isequal('BranchJoint', x), ...
            arrayfun(@(y) y.JointType, ...
            J, 'UniformOutput', 0), 'UniformOutput', 0)));
        
        end
        
        function setJoint(obj, j, jIdx)
        %% Set BranchChild object
        if nargin < 3
            jIdx = obj.TotalJoints + 1;
        end
        
        try
            % Find Matching index
            sklIdx = find(pdist2(j.Coordinate, obj.Coordinates) == 0);
            j.Parent          = obj;
            j.IndexInSkeleton = sklIdx;
            obj.Joints(jIdx)  = j;
            obj.TotalJoints   = jIdx;
        catch e
            fprintf(2, 'Error setting BranchChild at index %d\n%s\n', ...
                jIdx, e.getReport);
        end
        end
        
        function b = getBone(obj, bIdx)
        %% Return Bone object
        if nargin < 2
            bIdx = 1 : obj.TotalBones;
        end
        
        try
            b = obj.Bones(bIdx);
        catch
            fprintf(2, 'Error returning Bone at index %d\n', bIdx);
            b = [];
        end
        end
        
        function [jpth , jidx, jchk] = checkJointConnection(obj, jIdx1, jIdx2)
        %% Compare 2 Joints to determine if they share a neighbor path
        % NOTE [02.27.2020]
        % When comparing Neighbors, it is important to note that each path
        % starts at the coordinate AFTER the Joint and ends AT the Joint. So
        % the last coordinate in each path should be omitted from the
        % comparison. Also, the shared path between 2 Neighbors will be the
        % reverse of each other, and so remember to flip one of the paths.
        
        %% Get all neighbor paths from both Joints
        j1 = obj.getJoint(jIdx1);
        N1 = j1.getNeighbor;
        e1 = arrayfun(@(x) x.EndPath, N1, 'UniformOutput', 0);
        b1 = arrayfun(@(x) x.BranchPath, N1, 'UniformOutput', 0);
        i1 = arrayfun(@(x) x.EndIndex, N1, 'UniformOutput', 0);
        j1 = arrayfun(@(x) x.BranchIndex, N1, 'UniformOutput', 0);
        p1 = [e1(~cellfun(@isempty, e1)) , b1(~cellfun(@isempty, b1))];
        q1 = [i1(~cellfun(@isempty, i1)) , j1(~cellfun(@isempty, j1))];
        
        j2 = obj.getJoint(jIdx2);
        N2 = j2.getNeighbor;
        e2 = arrayfun(@(x) x.EndPath, N2, 'UniformOutput', 0);
        b2 = arrayfun(@(x) x.BranchPath, N2, 'UniformOutput', 0);
        i2 = arrayfun(@(x) x.EndIndex, N2, 'UniformOutput', 0);
        j2 = arrayfun(@(x) x.BranchIndex, N2, 'UniformOutput', 0);
        p2 = [e2(~cellfun(@isempty, e2)) , b2(~cellfun(@isempty, b2))];
        q2 = [i2(~cellfun(@isempty, i2)) , j2(~cellfun(@isempty, j2))];
        
        %% Compare all N1 paths with all N2 paths
        chk1 = cellfun(@(x) cellfun(@(y) obj.comparePaths(x,y), ...
            p2, 'UniformOutput', 0), p1, 'UniformOutput', 0)';
        chk2 = cellfun(@(x) cat(2, x{:}), chk1, 'UniformOutput', 0);
        chk3 = cat(1, chk2{:});
        
        % Find matching coordinate, if any, and construct the segment
        [c1 , c2] = find(chk3);
        
        if numel(c1)  > 1
            % Just choose the first row if more than one matching segment
            c1 = c1(1);
            c2 = c2(1);
        end
        
        jchk = chk3(c1 , c2);
        
        if jchk
            crd2 = p2{c2}(end,:);
            jpth = [crd2 ; p1{c1}];
            idx2 = q2{c2}(end);
            jidx = [idx2 , q1{c1}];
        else
            jpth = [];
            jidx = [];
        end
        
        end
        
        function bone = createBone(obj, jIdx1, jIdx2, pth, idx)
        %% Create Bone object from path between pairs of Joints
        j1 = obj.getJoint(jIdx1);
        j2 = obj.getJoint(jIdx2);
        
        bone = Bone('Parent', obj, 'Coordinate', pth, ...
            'IndexInSkeleton', idx, 'Length', size(pth,1), ...
            'Joints', [j1 , j2], 'JointIndex', [jIdx1 , jIdx2]);
        
        end
        
        function [P , pd] = sampleImage(obj, crds, edst)
        %% Interpolation of coordinates onto image
        if nargin < 3
            edst = obj.ENVELOPEDISTANCE;
        end
        
        img      = obj.Image;
        bg       = median(img, 'all');
        [P , pd] = getStraightenedMask(crds, img, 0, edst, bg);
        P        = flipud(P);
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
        
        function [pth , pthIdx] = getLongestRoute(obj, typ)
        %% Find longest route through skeleton
        % Type parameter determines all joints or only branch joints
        if nargin < 2
            typ = 'all';
        end
        
        switch typ
            case 'all'
                %% Find longest route through all points
                [~ , pthIdx] = max(cell2mat(cellfun(@(x) ...
                    max(size(x,1)), obj.Routes, 'UniformOutput', 0)));
                pth          = obj.Routes{pthIdx};
                
            case 'branches'
                %% Find longest route through only branch points
                BJ = obj.getBranchJoints;
                bc = cell2mat(arrayfun(@(bj) bj.Coordinate, ...
                    BJ, 'UniformOutput', 0)');
                bi = getLowestIndex(bc);
                
                % Get all routes from lowest branch point and select longest
                [~ , rts , pth] = obj.branch2branches(bi, 'all');
                [~ , pthIdx]    = max(cell2mat(cellfun(@(p) numel(p), ...
                    pth, 'UniformOutput', 0)));
                pth             = rts{pthIdx};
                
        end
        end
    end
    
    %% ------------------------- Private Methods --------------------------- %%
    methods (Access = private)
        function [r , R , P] = path2ClosestNode(obj, s, e, remInt)
        %% path2ClosestNode: returns paths to nearest node
        % Implements Dijkstra's algorithm to find the shortest path between
        % an input node (s) and an array of nodes (e) in the Graph. The
        % indices of the nodes ought to be those corresponding to EndPoints,
        % BranchPoints, or Neighbors, since all other intermediate nodes are
        % practically useless.
        %
        % Usage:
        %   [r , R , P] = path2ClosestNode(obj, s, e, remInt)
        %
        % Input:
        %   obj: This Skeleton object
        %   s: node to start searching through paths
        %   e: 1 or more indices to serve as the target node
        %   remInt: omit paths that intersect contour (default 0)
        %
        % Output:
        %   r: the shortest path between s and all of e
        %   R: all shortest paths between s and each e
        %   P: all path indices of nodes
        
        %% Iterate through all starting points to find closest Branch Point
        if nargin < 4
            remInt = 0;
        end
        
        g   = obj.Graph;
        skl = obj.Coordinates;
        cnt = obj.Contour;
        gsz = numel(e);
        gma = cell(1, gsz);
        dst = zeros(1, gsz);
        
        % Compute the shortest path between each node
        for b = 1 : numel(e)
            [gma{b}, dst(b)] = g.shortestpath(s, e(b));
            
            %% Remove intersecting path through contour
            if remInt
                gtmp         = g;
                pth          = skl(gma{b},:);
                [~ , ~ , ni] = polyxpoly( ...
                    cnt(:,1), cnt(:,2), pth(:,1), pth(:,2));
                
                while ~isempty(ni)
                    RWEIGHT = 1000; % Weight to set edge to
                    
                    % Set max weight of intersecting edge
                    nidx = gma{b}(ni(1,2));
                    neig = gtmp.nearest(nidx,2);
                    edgs = gtmp.findedge(nidx, neig);
                    gtmp = gtmp.rmedge(edgs(edgs > 0));
                    gtmp = gtmp.addedge(nidx, neig, RWEIGHT);
                    
                    % Re-compute shortest path to target
                    [gma{b}, dst(b)] = gtmp.shortestpath(s, e(b));
                    
                    % Re-check for intersecting path
                    pth          = skl(gma{b},:);
                    [~ , ~ , ni] = polyxpoly( ...
                        cnt(:,1), cnt(:,2), pth(:,1), pth(:,2));
                    
                end
            end
        end
        
        % Replace 0 with Inf (don't find self path)
        zIdx      = dst == 0;
        dst(zIdx) = [];
        gma(zIdx) = [];
        
        %         %% Remove paths that pass through the contour [may not be best check]
        %         skls = cellfun(@(midx) skl(midx,:), gma, 'UniformOutput', 0);
        %         cntr = obj.Contour;
        %         iIdx = cell2mat(cellfun(@(skl) ~isempty(polyxpoly(cntr(:,1), cntr(:,2), ...
        %             skl(:,1), skl(:,2))), skls, 'UniformOutput', 0));
        %
        %         dst(iIdx) = [];
        %         gma(iIdx) = [];
        
        %% Get the minimum distance from the set of paths
        [~, minIdx] = min(dst);
        
        % Identify path to closest branch point
        P = gma;
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
        
        function chk = comparePaths(obj, p1, p2)
        %% Compare 2 Neighbor paths for similarity
        % NOTE [02.27.2020]
        % When comparing Neighbors, it is important to note that each path
        % starts at the coordinate AFTER the Joint and ends AT the Joint. So
        % the last coordinate in each path should be omitted from the
        % comparison. Also, the shared path between 2 Neighbors will be the
        % reverse of each other, and so I need to flip one of the paths.
        
        p1 = p1(1:end-1,:);
        p2 = p2(1:end-1,:);
        try
            % Check for equal coordinates
            chksum = sum(all(p1 == flipud(p2)));
            %                 chksum = min(pdist2(p1, flipud(p2)));
            if chksum == 2
                % Check if paths are crossing through another BranchPoint
                bcrds  = obj.BranchPoints;
                minDst = min(pdist2(bcrds, p1), [], 'all');
                
                if minDst == 0
                    chk = 0;
                else
                    chk = 1;
                end
            else
                chk = 0;
            end
        catch
            chk = 0;
        end
        
        end
        
    end
    
end

