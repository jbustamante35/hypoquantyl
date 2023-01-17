function rcntr = thumb2full2(cntr, gbox, sbox, soff, hoff, hln, scl)
%% thumb2full2: coordinate conversion with new remapping function
%

if nargin < 4; soff = [0 , 0 , 0 , 0]; end
if nargin < 5; hoff = [0 , 0 , 0 , 0]; end
if nargin < 6; hln  = 250;             end
if nargin < 7; scl  = [101 , 101];     end

gbc         = gbox + soff;
sic         = imcrop(gio, gbc);
smc         = imcrop(gmo, gbc);
[sbc , hic] = cropBoxFromAnchorPoints(smc, hln, hoff, scl, sic);

switch drc
    case 'fwd'
        % Forward Direction [Genotype --> Seedling --> Hypocotyl]
        icntr = remapCoordinates(gio, sic, gbc, bs2g, 'g2s');
        rcntr = remapCoordinates(sic, hic, sbc, icntr, 's2h');
    case 'rev'
        % Reverse Conversion [Hypocotyl --> Seedling --> Genotype] (default)
        icntr = remapCoordinates(hio, sio, sbox, cntr,  'h2s');
        rcntr = remapCoordinates(sio, gio, gbox, icntr, 's2g');
end
end