function [CRCS, figs] = trainCircuits_automated(Ein, cin, fIdx, sav, vis)
%% trainCircuits_automated: automated segmentation before training contour
% This is the alternative version for training Hypocotyl objects that obtains
% an array of CircuitJB objects from auto-generated contours, rather than
% manually-drawn contours.
%
% Usage:
%   [CRCS, figs] = trainCircuits_automated(Ein, cin, fIdx, sav, vis)
%
% Input:
%   Ein: Experiment object to draw Hypocotyls from
%   cin: input matrix defining indices to draw child objects
%   fIdx: indices to overwrite figures, set to [] to create new figures
%   sav: boolean to save or not save output data
%   vis: boolean to visualize output data
%
% Output:
%   CRCS: CircuitJB object array of trained auto-generated contours
%   figs: handles to figures if vis is set to  true
%

%% Constants
SEGMENTATION_FACTOR = 0.60;  % Sensitivity factor for binarization
SEGMENTATION_SIZE   = 65;    % Total coordinates for an auto-generated ContourJB
TOTAL_ANCHORPOINTS  = 1 : 7; % Number of simulated anchor points for CircuitJB
TRAINING_TYPE       = 1;     % 0 to training Seedlings, 1 to training Hypocotyls

%% Extract untrained data from range of frames
% Store images with original and flipped versions
G  = Ein.getGenotype(cin(:,1));
S  = arrayfun(@(x) G(x).getSeedling(cin(x,2)), 1:numel(G), 'UniformOutput', 0);
H  = cellfun(@(s) s.MyHypocotyl, S, 'UniformOutput', 0);
I  = arrayfun(@(x) H{x}.getImage(cin(x,3)),  1:numel(H), 'UniformOutput', 0);
F  = arrayfun(@(x) H{x}.FlipMe(cin(x,3), 0), 1:numel(H), 'UniformOutput', 0);
X  = [I , F];

% Binarize images
imgsz   = size(X{1});
[~, BW] = cellfun(@(x) segmentObjectsHQ(x, imgsz, SEGMENTATION_FACTOR), ...
    X, 'UniformOutput', 0);

% Extract contours for all images and remove all overlapping poings
CJB = cellfun(@(x) extractContour(x, SEGMENTATION_SIZE, 'alt', 'alt'), ...
    BW, 'UniformOutput', 0);
CNT = cellfun(@(x) unique(x.NormalizedOutline, 'rows', 'stable'), ...
    CJB, 'UniformOutput', 0);

% Make artificial anchor points by dividing into 7 sections
pIdx = [1 : ceil(SEGMENTATION_SIZE / numel(TOTAL_ANCHORPOINTS)) : ...
    SEGMENTATION_SIZE , 1];
PTS  = cellfun(@(x) x(pIdx,:), CNT, 'UniformOutput', 0);

%% Perform training with contours and images
% Initialize object array of CircuitJB objects
tot  = numel(X);
CRCS = repmat(CircuitJB, 1, tot);
for t = 1 : tot
    CRCS(t) = CircuitJB;
end

idxs_o = [cin zeros(size(cin,1), 1)];
idxs_f = [cin ones(size(cin,1), 1)];
hidxs  = [idxs_o ; idxs_f];
hyps   = getHypocotylObjects(hidxs, Ein, 'Hypocotyl');

% Get CircuitJB for all auto-generated Hypocotyl contours
for hIdx = 1 : numel(hyps)
    hyp        = hyps(hIdx);
    frm        = hidxs(hIdx, 3);
    cntr       = CNT{hIdx};
    pts        = PTS{hIdx};
    isFlipped  = hidxs(hIdx, 4);
    [org, flp] = ...
        generateCircuit(hyp, frm, TRAINING_TYPE, isFlipped, cntr, pts);
    
    % Check if inserting flipped or original orientation
    if isFlipped
        % Insert flipped version
        CRCS(hIdx) = flp;
    else
        % Insert original orientation
        CRCS(hIdx) = org;
    end
end

%% Visualize data
if vis
    % Get figure indices or generate new figures
    if isempty(fIdx)
        fig1 = figure;
        fig2 = figure;
    else
        fig1 = figure(fIdx(1));
        fig2 = figure(fIdx(2));
    end
    
    %% Gallery of selected Hypocotyls with auto-generated contour on image
    set(0, 'CurrentFigure', fig1);
    cla;clf;
    
    [n , o] = deal(1 : numel(G));
    p       = deal(horzcat(n,o));
    tot     = numel(X);
%     rows    = ceil(tot / 10);
    rows = 2;
    cols    = ceil(tot / ceil(rows / 2));
    for slot = 1 : tot
        
        % Grayscale images with contour and start points
        subplot(rows, cols, slot);
        imagesc(X{slot});
        colormap gray;
        axis image;
        hold on;
        plt(CNT{slot}, 'b.', 4);
        plt(CNT{slot}, 'g-', 1);
        plt(CNT{slot}(1,:), 'rx', 6);
        plt(PTS{slot}, 'mo', 3);
        
        ttl = sprintf('%s\nSeedling %d Frame %d', ...
            fixtitle(G(p(slot)).GenotypeName), cin(p(slot), 2), cin(p(slot), 3));
        title(ttl);
        
        % Binarized images with contour and start point
        subplot(rows, cols, slot + tot);
        imagesc(BW{slot});
        colormap gray;
        axis image;
        hold on;
        plt(CNT{slot}, 'b.', 4);
        plt(CNT{slot}, 'g-', 1);
        plt(CNT{slot}(1,:), 'rx', 6);
        plt(PTS{slot}, 'mo', 3);
        
        ttl = sprintf('%s\nSeedling %d Frame %d', ...
            fixtitle(G(p(slot)).GenotypeName), cin(p(slot), 2), ...
            cin(p(slot), 3));
        title(ttl);
    end
    
    %% Gallery of contours on grayscale imagess
    set(0, 'CurrentFigure', fig2);
    cla;clf;
    
    rows = 2;
    cols = ceil(tot / rows);
    for slot = 1 : tot
        
        try
            % Draw contour and anchor points on grayscale image
            subplot(rows, cols, slot);
            imagesc(CRCS(slot).getImage('gray'));
            colormap gray;
            axis image;
            hold on;
            plt(CRCS(slot).getRawOutline, 'm.', 5);
            plt(CRCS(slot).getOutline, 'b-', 2);
            plt(CRCS(slot).getRawPoints, 'yo', 3);
            plt(CRCS(slot).getAnchorPoints, 'cx', 5);
            
            ttl = sprintf('%s\nSeedling %d Frame %d', ...
                fixtitle(G(p(slot)).GenotypeName), cin(p(slot), 2), ...
                cin(p(slot), 3));
            title(ttl);
            
        catch e
            fprintf(2, 'Skipping Circuit %d\n%s\n', slot, e.message);
        end
        
    end
    
    figs = [fig1 fig2];
    if sav
        fnms{1} = sprintf('%s_SegmentationGallery_%dImages', tdate('s'), tot);
        fnms{2} = sprintf('%s_CircuitJBGallerys_%dImages', tdate('s'), tot);
        for fig = 1 : numel(figs)
            savefig(figs(fig), fnms{fig});
            saveas(figs(fig), fnms{fig}, 'tiffn');
        end
    end
    
else
    figs = [];
end

%% Save output into .mat file
if sav
    arrayfun(@(x) x.DerefParents, CRCS, 'UniformOutput', 0);
    nm = sprintf('%s_AutoTrainedCircuits_%dHypocotyls', tdate('s'), tot);
    save(nm, '-v7.3', 'CRCS');
    arrayfun(@(x) x.ResetReference(Ein), CRCS, 'UniformOutput', 0);
end

end

function dout = getHypocotylObjects(din, ex, typ)
%% retrieveDataObjects: return data objects defined by [3 3] input matrix
% Input is in the form of indexed values in an Experiment object. Indices
% in the cin parameter should map to a frame containing a Seedling or Hypocotyl
% object in a given Genotype object.
%
% Example:
% [
%   [ 8 3 10 ] % 8th genotype , 3rd seedling , 10th frame
%   [ 1 2 1  ] % 1st genotype , 2nd seedling , 1st  frame
%   [ 3 5 25 ] % 3rd genotype , 5th seedling , 25th frame
%   [ 5 4 20 ] % 5th genotype , 4th seedling , 20th frame
%               ]

try
    % Determine final class to extract
    if typ
        dtyp = 'Hypocotyl';
    else
        dtyp = 'Seedling';
    end
    
    % Iterate through Genotype index [column 1]
    dttl = size(din, 1);
    dout = repmat(eval(dtyp), 1, dttl);
    for d = 1 : dttl
        g = ex.getGenotype(din(d,1));
        s = g.getSeedling(din(d,2));
        
        % Extract Hypocotyl or keep as Seedling
        if typ
            dout(d) = s.MyHypocotyl;
        else
            dout(d) = s;
        end
    end
catch e
    x = din(d,:);
    fprintf('Error extracting %s [ %d %d %d ]\n%s\n', dtyp, x, e.message);
    dout = [];
end

end


function [crc, flp] = generateCircuit(obj, frm, typ, flipme, cntr, pts)
%% getCircuit: subfunction to manually-draw contour on random frame of Seedling

% Get all un-trained random good frames from Seedling's lifetime
if typ
    % Get selected frame for Hypocotyl object
    org  = sprintf('%s_%s_%s_%s_Frm{%d}', obj.ExperimentName, ...
        obj.GenotypeName, obj.SeedlingName, obj.HypocotylName, frm);
else
    % Get selected frame for Seedling object
    org  = sprintf('%s_%s_%s_Frm{%d}', obj.ExperimentName, ...
        obj.GenotypeName, obj.SeedlingName, frm);
end

if flipme
    % Set flipped orientation of Circuit or Contour
    forg = sprintf('flip_%s', org);
    flp  = setOutline(obj, forg, cntr, pts);
    crc  = [];
    
    if typ
        obj.setCircuit(frm, flp, 'flp');
    else
        obj.setContour(frm, flp);
    end
else
    % Set original orientation of Circuit or Contour
    crc = setOutline(obj, org, cntr, pts);
    flp = [];
    
    if typ
        obj.setCircuit(frm, crc, 'org');
    else
        obj.setContour(frm, crc);
    end
end
end

function crc = setOutline(obj, org, cntr, pts)
%% Create CircuitJB using auto-generated contour
% Set image and origin data for CircuitJB
crc = CircuitJB('Origin', org, 'Parent', obj);
crc.setParent(obj);
crc.checkFlipped;

% Set Outline and AnchorPoints and normalize coordinates
crc.setRawOutline(cntr);
crc.setRawPoints(pts);
crc.ConvertRawPoints;

end
