function [srgcrv, aff] = replaceCurve(img, cntr, rplcrv, vis, f)
%% replaceCurve: place part of a curve with another
% This function allows the user to select a section of a curve and replace it
% with another curve section. The replacement curve should be expressed in it's
% own reference frame, where an affine transformation allows that curve to be
% projected into the same reference frame as the initial curve.
%
% Usage:
%   srgcrv = replaceCurve(img, cntr, crvbank)
%
% Input:
%   img: image associated with the initial curve
%   cntr: contour of the initial curve
%   rplcrv: curve in it's own reference frame to replace
%   vis: boolean to visualize the surgery
%   f: figure handle index to select points
%
% Output:
%   srgvcrv: curve with replaced section
%   aff: affine transformation to move to initial frame of reference
%

%% Chop off the heads
% Define section to replace
set(0, 'CurrentFigure', f);
cla;clf;
myimagesc(img);
hold on;
plt(cntr, 'g-', 2);
plt(cntr(1,:), 'c+', 10);
plt(cntr(end,:), 'm+', 10);
[col , row, ~] = impixel;
[~, snpIdx]    = snap2curve([col , row], cntr);

%% Store section to cut off
snp    = snpIdx(1) : snpIdx(2);
tmpcrv = cntr(snp, :);

% If length ofsection is odd, make it even
if mod(size(tmpcrv,1), 2) == 1
    snpIdx(end) = snpIdx(end) + 1;
end

% Store section that was cut off
snp    = snpIdx(1) : snpIdx(end);
tmpcrv = cntr(snp, :);

% Visualize initial curve, section anchor points, and section to replace
if vis
    set(0, 'CurrentFigure', f);
    cla;clf;
    myimagesc(img);
    hold on;
    
    plt(cntr, 'g-', 2);
    plt(tmpcrv, 'r-', 2);
    plt(cntr(snpIdx,:), 'y*', 10);
end

%% Set-up sections to replace and section to replace
srgsig      = zeros(size(cntr, 1), 1);
srgsig(snp) = 1;
srgsig      = logical(srgsig);
rplcrvF     = interpolateOutline(rplcrv, sum(srgsig));

% Move the replacement curve into the original curve's reference frame
rplcrvF = [rplcrvF , ones(size(rplcrvF,1),1)];
[z, l]  = generateSegmentFrame(tmpcrv);
scl     = [(l * 0.5) , ones(size(l))];
aff     = squeeze(tb2affine(z, scl));

% Affine transformation to project into frame and then perform the replacement
rplcrvT          = (aff * rplcrvF')';
srgcrv           = cntr;
srgcrv(srgsig,:) = rplcrvT(:,1:2);

% Show the replacement surgery
if vis
    set(0, 'CurrentFigure', f);
    plt(rplcrvT, 'c-', 2);
    plt(srgcrv, 'c.', 10);
    
    ttl = sprintf('Curve Replacement\nInitial [%s] | Replacement [%s]', ...
        num2str(size(tmpcrv)), num2str(size(rplcrvT)));
    title(ttl);
end

end

