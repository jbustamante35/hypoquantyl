function [msh , mshmid, skl , skl2 , skl3] = model2mesh_oufti(crds, stp, tol, wid)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function res = model2mesh_oufti(crds, stp, tol, wid)
%oufti.v0.3.0
%@author:  oleksii sliusarenko
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%cellMesh:  created mesh from coordinate points.
%**********Input********:
%coordinatePoints:  coordinate vector for a cell contour.
%stepSize:  steps to void between each segment in a mesh.
%tolerance: ?
%meshWidth: width of the mesh to be created.
%=========================================================================
% PURPOSE:
% This function performs a medial axis transform to a non-branching axis
% Takes the outline coordinates, step size on the final centerline,
% tolerance to non-centrality, and the length of the ribs. The last
% parameter should be longer than the ribs, but should not be too long to
% intersect the countour agan: though most cases of >1 intersection will
% be resolved by the function, some will not. Outputs the coordinates of
% the centerline points.
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

delta = 1E-10;

% voronoi transform
while true
    if length(crds)<=2, msh=0; return; end
    if abs(crds(1,1)-crds(end,1))<0.00001 && abs(crds(1,2)-crds(end,2))<0.00001
        crds = crds(1:end-1,:);
    else
        break;
    end
end
crds = double(crds);
warning('off','MATLAB:triangulation:PtsNotInTriWarnId');
warning('off','MATLAB:delaunay:DuplicateDataPoints')
warning('off','MATLAB:delaunay:DupPtsDelaunayWarnId')
warning('off','MATLAB:TriRep:PtsNotInTriWarnId')
[vx,vy] = voronoi(crds(:,1),crds(:,2));
warning('off','MATLAB:delaunay:DupPtsDelaunayWarnId')
warning('off','MATLAB:delaunay:DuplicateDataPoints')
warning('off','MATLAB:TriRep:PtsNotInTriWarnId')
% remove vertices crossing the boundary
vx = reshape(vx,[],1);
vy = reshape(vy,[],1);
q = intxy2(vx,vy,crds(:,1),crds(:,2));
vx = reshape(vx(~[q;q]),2,[]);
vy = reshape(vy(~[q;q]),2,[]);

% remove vertices outside
q = logical(inpolygon_(vx(1,:),vy(1,:),crds(:,1),crds(:,2))...
    .* inpolygon_(vx(2,:),vy(2,:),crds(:,1),crds(:,2)));
vx = reshape(vx([q;q]),2,[]);
vy = reshape(vy([q;q]),2,[]);

% remove isolated points
if isempty(vx), msh=0;return; end
t = ~((abs(vx(1,:)-vx(2,:))<delta)&(abs(vy(1,:)-vy(2,:))<delta));
vx = reshape(vx([t;t]),2,[]);
vy = reshape(vy([t;t]),2,[]);

% remove branches
vx2=[];
vy2=[];
while true
    for i=1:size(vx,2)
        if((sum(sum((abs(vx-vx(1,i))<delta)&(abs(vy-vy(1,i))<delta)))>1)&&(sum(sum((abs(vx-vx(2,i))<delta)&(abs(vy-vy(2,i))<delta)))>1))
            vx2=[vx2 vx(:,i)]; %#ok<AGROW>
            vy2=[vy2 vy(:,i)]; %#ok<AGROW>
        end
    end
    % % %             vectCheck = (((abs(vx(2,:)-vx(1,:))<delta)&(abs(vy(2,:)-vy(1,:))<delta)>1)&(abs(vx(1,:)-vx(2,:))<delta)&(abs(vy(1,:)-vy(2,:))<delta)>1);
    % % %             vx3 = (vectCheck.*vx)+(~vectCheck.*vx);
    % % %             vy3 = (VectCheck.*vy)+(~vectCheck.*vy);
    if size(vx,2)-size(vx2,2)<=2
        vx3 = vx2;
        vy3 = vy2;
        break;
    else
        vx = vx2;
        vy = vy2;
        vx2 = [];
        vy2 = [];
    end
end
vx = vx3;
vy = vy3;

% check that there are no cycles
vx2 = [];
vy2 = [];
while size(vx,2)>1
    for i=1:size(vx,2)
        if((sum(sum((abs(vx-vx(1,i))<delta)&(abs(vy-vy(1,i))<delta)))>1)&&(sum(sum((abs(vx-vx(2,i))<delta)&(abs(vy-vy(2,i))<delta)))>1))
            vx2=[vx2 vx(:,i)]; %#ok<AGROW>
            vy2=[vy2 vy(:,i)]; %#ok<AGROW>
        end
    end
    if size(vx,2)-size(vx2,2)<=1
        msh = 0;
        return;
    else
        vx = vx2;
        vy = vy2;
        vx2 = [];
        vy2 = [];
    end
end
vx = vx3;
vy = vy3;
if isempty(vx) || size(vx,1)<2, msh=0;return;end

% % sort points
vx2=[];
vy2=[];
for i=1:size(vx,2) % in this cycle find the first point
    if sum(sum(abs(vx-vx(1,i))<delta & abs(vy-vy(1,i))<delta))==1
        vx2=vx(:,i)';
        vy2=vy(:,i)';
        break;
    elseif sum(sum(abs(vx-vx(2,i))<delta & abs(vy-vy(2,i))<delta))==1
        vx2=fliplr(vx(:,i)');
        vy2=fliplr(vy(:,i)');
        break;
    end
end
k=2;
while true % in this cycle sort all points after the first one
    f1=find(abs(vx(1,:)-vx2(k))<delta & abs(vy(1,:)-vy2(k))<delta & (abs(vx(2,:)-vx2(k-1))>=delta | abs(vy(2,:)-vy2(k-1))>=delta));
    f2=find(abs(vx(2,:)-vx2(k))<delta & abs(vy(2,:)-vy2(k))<delta & (abs(vx(1,:)-vx2(k-1))>=delta | abs(vy(1,:)-vy2(k-1))>=delta));
    if f1>0
        vx2 = [vx2 vx(2,f1)]; %#ok<AGROW>
        vy2 = [vy2 vy(2,f1)]; %#ok<AGROW>
    elseif f2>0
        vx2 = [vx2 vx(1,f2)]; %#ok<AGROW>
        vy2 = [vy2 vy(1,f2)]; %#ok<AGROW>
    else
        break;
    end
    k=k+1;
end
% % % vx2 = vx(1,:);
% % % vy2 = vy(1,:);
skl=[vx2' vy2']; % Midline

if size(vx2,2)<=1, msh = 0; return; end

% interpolate skeleton to equal step, extend outside of the cell and smooth
% tolerance=0.001;
d=diff(skl,1,1);
l=cumsum([0;sqrt((d.*d)*[1 ;1])]);
if l(end)>=stp
    skl = [interp1(l,vx2,0:stp:l(end))' interp1(l,vy2,0:stp:l(end))'];
else
    skl = [vx2(1) vy2(1);vx2(end) vy2(end)];
end
if size(skl,1)<=1, msh = 0; return; end
lng0 = l(end);
sz = lng0/stp;
L = size(crds,1);
% crds = [crds;crds(1,:)]; % Close contour
% lng = 100;
skl2 = [skl(1,:)*(wid/stp+1) - skl(2,:)*wid/stp; skl;...
    skl(end,:)*(wid/stp+1) - skl(end-1,:)*wid/stp];
% skl2 = skl;
d=diff(skl2,1,1);
l=cumsum([0;sqrt((d.*d)*[1 ;1])]);
[l,i] = unique(l);
skl2 = skl2(i,:);
if length(l)<2 || size(skl2,1)<2, msh=0; return; end
% find the intersection of the 1st skel2 segment with the contour, the
% closest to one of the poles (which will be called 'prevpoint')
[~, ~, indS, indC] = intxyMulti(skl2(2:-1:1,1), skl2(2:-1:1,2), crds(:,1), crds(:,2));
% [~, prevpoint]     = min([min(modL(indC,1)) , min(modL(indC, L / 2 + 1))]);
[~, prevpoint]     = min([min(modL(indC,1,L)) , min(modL(indC, L / 2 + 1, L))]);

if prevpoint == 2
    prevpoint = L / 2;
end

% prevpoint = mod(round(indC(1))-1,L)+1;
skl3 = spsmooth(l, skl2', tol, 0 : stp : l(end))'; %1:stp:

% recenter and smooth again the skeleton
% [pintx,pinty,q] = skel2mesh(skl3);
[pintx, pinty, q] = skel2mesh(skl3, crds, prevpoint, stp, wid, L);

if length(pintx) < sz - 1
    skl3              = spsmooth(l, skl2', tol / 100, 0 : stp : l(end))';
%     [pintx, pinty, q] = skel2mesh(skl3);
    [pintx, pinty, q] = skel2mesh(skl3, crds, prevpoint, stp, wid, L);
end

%% Error Checks
if ~q || length(pintx) < sz - 1  || length(skl3) < 4
    msh = 0;
    mshmid = 0;
    return;
end

skl   = [mean(pintx,2) mean(pinty,2)];
d     = diff(skl,1,1);
l     = cumsum([0;sqrt((d.*d)*[1 ;1])]);
[l,i] = unique(l);
skl   = skl(i,:);

if length(l)<2 || size(skl,1)<2
    msh = 0;
    mshmid = 0;
    return;
end

skl = spsmooth(l, skl', tol, -3 * stp : stp : l(end) + 4 * stp)';

% get the mesh
% [pintx, pinty, q] = skel2mesh(skl);
[pintx, pinty, q] = skel2mesh(skl3, crds, prevpoint, stp, wid, L);

if ~q
    msh = 0;
    mshmid = 0;
    return;
end

msh = [pintx(:,1) pinty(:,1) pintx(:,2) pinty(:,2)];

% Get centerline
mshx   = msh(:,1) + (msh(:,3) - msh(:,1)) ./ 2;
mshy   = msh(:,2) + (msh(:,4) - msh(:,2)) ./ 2;
mshmid = [mshx , mshy];

if (pintx(1,1) - crds(end,1))^2 + (pinty(1,1) - crds(end,2))^2 > (pintx(end,1) - crds(end,1))^2 + (pinty(end,1) - crds(end,2))^2
    msh = flipud(msh);
end

if numel(msh) == 1 || length(msh) <= 4
    msh = 0;
    mshmid = 0;
    disp('Unable to create mesh');
end

if length(msh) > 1 && (msh(1,1) ~= msh(1,3) || msh(end,1) ~= msh(end,3))
    msh = 0;
    mshmid = 0;
    disp('Mesh creation error! Cell rejected');
end

end

function out = modL(in, shift, L)
out = mod(in - shift, L);
out = min(out, L - out);
end

function [pintx, pinty, q] = skel2mesh(sk, crds, prevpoint, stp, wid, L)
%% skel2mesh: finds intersections of ribs with the contour
% To be used in "model2mesh" function
if isempty(sk)
    pintx = [];
    pinty = [];
    q     = false;
    return;
end

% Find the intersection of the skel with the contour closest to prevpoint
pintx = [];
pinty = [];
[intX, intY, indS, indC] = intxyMulti(sk(:,1), sk(:,2), crds(:,1), crds(:,2));

if isempty(intX) || isempty(indC) || isempty(prevpoint)
    q = false;
    return;
end

% [prevpt , ind] = min(modL(indC, prevpt));
[prevpoint , ind] = min(modL(indC, prevpoint, L));
prevpoint         = indC(ind);
indS              = indS(ind);

if indS > (size(sk,1)+1-indS)
    sk = sk(ceil(indS):-1:1,:);
else
    sk = sk(floor(indS):end,:);
end

% 2. define the first pair of intersections as this point
% 3. get the list of intersections for the next pair
% 4. if more than one, take the next in the correct direction
% 5. if no intersections found in the reqion between points, stop
% 6. goto 3.
% Define the lines used to compute intersections
d=diff(sk,1,1);
plinesx1 = repmat_(sk(1:end-1,1),1,2)+wid/stp*d(:,2)*[0 1];
plinesy1 = repmat_(sk(1:end-1,2),1,2)-wid/stp*d(:,1)*[0 1];
plinesx2 = repmat_(sk(1:end-1,1),1,2)+wid/stp*d(:,2)*[0 -1];
plinesy2 = repmat_(sk(1:end-1,2),1,2)-wid/stp*d(:,1)*[0 -1];
% Allocate memory for the intersection points
pintx = zeros(size(sk,1)-1,2);
pinty = zeros(size(sk,1)-1,2);
% Define the first pair of intersections as the prevpoint
pintx(1,:) = [intX(ind) intX(ind)];
pinty(1,:) = [intY(ind) intY(ind)];
prevpoint1 = prevpoint;
prevpoint2 = prevpoint;

% for i=1:size(d,1), plot(plinesx(i,:),plinesy(i,:),'r'); end % Testing
q=true;
fg = 1;
jmax = size(sk,1)-1;
for j=2:jmax
    % gdisp(['Use 1: ' num2str(size(plinesx1(j,:))) ' ' num2str(size(coord(:,1))) ' j=' num2str(j)]); % Testing
    [pintx1,pinty1,~,indC1]=intxyMulti(plinesx1(j,:),plinesy1(j,:),crds(:,1),crds(:,2),floor(prevpoint1),1);%
    [pintx2,pinty2,~,indC2]=intxyMulti(plinesx2(j,:),plinesy2(j,:),crds(:,1),crds(:,2),ceil(prevpoint2),-1);%
    if (~isempty(pintx1))&&(~isempty(pintx2))
        if pintx1~=pintx2
            if fg==3
                break;
            end
            fg = 2;
%             [~,ind1] = min(modL(indC1,prevpoint1));
%             [~,ind2] = min(modL(indC2,prevpoint2));
            [~,ind1] = min(modL(indC1, prevpoint1, L));
            [~,ind2] = min(modL(indC2, prevpoint2, L));
            prevpoint1 = indC1(ind1);
            prevpoint2 = indC2(ind2);
            pintx(j,:)=[pintx1(ind1) pintx2(ind2)];
            pinty(j,:)=[pinty1(ind1) pinty2(ind2)];
        else
            q=false;
            return;
        end
    elseif fg==2
        fg = 3;
    end
end
pinty = pinty(pintx(:,1)~=0,:);
pintx = pintx(pintx(:,1)~=0,:);
[intX,intY,indS,indC]=intxyMulti(sk(:,1),sk(:,2),crds(:,1),crds(:,2));
% [prevpoint,ind] = max(modL(indC,prevpoint));
[prevpoint, ind] = max(modL(indC, prevpoint, L));
pintx = [pintx;[intX(ind) intX(ind)]];
pinty = [pinty;[intY(ind) intY(ind)]];
nonan = ~isnan(pintx(:,1))&~isnan(pinty(:,1))&~isnan(pintx(:,2))&~isnan(pinty(:,2));
pintx = pintx(nonan,:);
pinty = pinty(nonan,:);

end % function skel2mesh
