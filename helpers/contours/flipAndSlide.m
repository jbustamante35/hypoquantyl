function trc = flipAndSlide(trc, seg_lengths)
%% flipAndSlide
if nargin < 2   
    seg_lengths = [53 , 52 , 53 , 51];
end

bmid = getBotMid(trc, seg_lengths);
dspl = displaceContour(trc, -bmid);
flpd = flipContour(dspl);
fdsp = displaceContour(flpd, bmid);

segs = arrayfun(@(n) getSegCoords(fdsp, seg_lengths, n), ...
    1 : 4, 'UniformOutput', 0);
rvrs = reverseOrientation(segs);
sld  = calcSlide(bmid, seg_lengths);
trc  = displaceContour(rvrs, sld);

end

function bmid = getBotMid(trc, seg_lengths)
%%
seg  = getSegCoords(trc, seg_lengths, 4);
bmid = mean(seg,1);
end

function trc = displaceContour(trc, dsp)
%% displaceContour:
trc = trc + dsp;
end
% ---------------------------------------------------------------------------- %
function trc = flipContour(trc)
%% flipContour
trc(:,1) = -trc(:,1);
end

function seg = getSegCoords(trc, seg_lengths, idx)
%% getSegCoords: get top, bottom, left, or right
switch idx
    case 1
        str = getSegIndex(1);
        stp = getSegIndex(2);
    case 2
        str = getSegIndex(2);
        stp = getSegIndex(3);
    case 3
        str = getSegIndex(3);
        stp = getSegIndex(4);
    case 4
        str = getSegIndex(4);
        stp = getSegIndex(5);
    otherwise
        fprintf(2, '');
        seg = [];
        return;
end

seg = trc(str:stp,:);

    function idx = getSegIndex(num)
        %%
        L   = cumsum([1 , seg_lengths]);
        idx = L(num);
    end
end

function trc = reverseOrientation(segs)
%% reverseOrientation
lft = segs{1};
top = segs{2};
rgt = segs{3};
bot = segs{4};

lft = flip(lft,1);
top = flip(top,1);
rgt = flip(rgt,1);
bot = flip(bot,1);

lft = lft(1:end-1,:);
top = top(1:end-1,:);
rgt = rgt(1:end-1,:);

trc = cat(1, rgt, top, lft, bot);
end

function sld = calcSlide(bmid, seg_lengths)
%%
f   = seg_lengths(end);
sld = [f - bmid(1) , 0] * 2;
end
