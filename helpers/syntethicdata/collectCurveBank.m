function crvbank = collectCurveBank(img, cntr, len_range, vis, f)
%% collectCurveBank: obtain contour segments that meet a ste of parameters
%
%
% Usage:
%   crvbank = collectCurveBank(img, cntr, len_range, vis, f)
%
% Input:
%   img: image associated with the contour
%   cntr: contour from an image
%   len_range: range of lengths to search for segments
%
% Output:
%   crvbank: segment of curves meeting a set of criteria
%

%% Parameter Constants
STP       = 1;
DTHRESH   = 2;
ANGTHRESH = 10;
LTHRESH   = 5;
INTRP     = 100;

%%
cnt     = 1;
crvbank = zeros(INTRP, 3);

%%
padVal      = size(img,1);
bw          = getSkelBWDisk(img, padVal);
base_length = measureBase(cntr);

for len = len_range    
    % Get tangent bundle of contour with len-sized segments
    [z, l, segs, lab] = contour2corestructure(cntr, len, STP);    
    
    % Set constraints
    bwd   = ba_interp2(bw, z(:,1), z(:,2));
    ang   = (180 * abs(atan2(-z(:,4), z(:,3)))) / pi;
    fIdx1 = bwd < DTHRESH;
    fIdx2 = ang < ANGTHRESH | ang > (180 - ANGTHRESH);
    fIdx3 = squeeze(all(lab == 0, 1));
    fIdx4 = abs(l - base_length) <= LTHRESH;
    fIdxT = fIdx1 & fIdx2 & fIdx3 & fIdx4;
    idxT  = find(fIdxT);
    
    if ~isempty(idxT)
        [~, mIdx] = min(z(idxT,2));
    else
        mIdx = [];
    end
    
    segsT = segs(:,:,fIdxT);
    
    if vis
        % Show segments
        set(0, 'CurrentFigure', f);
        cla;clf;
        
        myimagesc(bw);
        hold on;
        szf = 4;
        plt(z(:,1:2), 'g.', szf);
        plt(z(fIdx1,1:2), 'ro', szf+2);
        plt(z(fIdx2,1:2), 'go', szf+2);
        plt(z(fIdx3,1:2), 'bo', szf+2);
        plt(z(fIdx4,1:2), 'yo', szf+2);
        plt(z(fIdxT,1:2), 'co', szf+2);
        title(sprintf('Length %d | CurveBank %d', len, cnt));
        axis off;
        drawnow;
    end
    
    if ~isempty(mIdx)
        % Store curve bank in it's own reference frame
        tmpseg  = [segsT(:,:,mIdx) , ones(size(segsT,1), 1)]';
        tmpz    = z(idxT(mIdx),:);
        scl     = [(l(idxT(mIdx)) * 0.5) , 1];
        frm     = squeeze(tb2affine(tmpz, scl, 1));
        aff     = (frm * tmpseg)';
        tmpbank = interpolateOutline(aff, INTRP);
        crvbank = [crvbank , tmpbank];
        
        if vis
            % Store curve bank in it's original frame for plotting
            set(0, 'CurrentFigure', f);
            crvT = interpolateOutline(tmpseg(1:2,:)', INTRP);
            plt(crvT, 'm-', 2);
            axis off;
            drawnow;
        end
        
        cnt = cnt + 1;
    end
    
    fprintf('Length %d | CurveBank %d\n', len, cnt);
end

% Remove the first columns of zeros
crvbank(:,1:3) = [];

end


