function F = trackMidline(isrc, itrg, msrc, mtrg, ipct, ppct, dsk, dres, dlt, symax, itrs, tolf, tolx)
%% trackMidline: track point(s) through single frame

t = tic;
fprintf('source %.03f | ', ipct);

[fa , tpt] = domainFinder(isrc, itrg, msrc, mtrg, ipct, ...
    'ppct', ppct, 'dsk', dsk, 'dres', dres, 'dlt', dlt, 'symax', symax, ...
    'itrs', itrs, 'tolf', tolf, 'tolx', tolx);

F = [fa , tpt];

fprintf('target %.03f | [%.02f sec] |\n', fa(1), toc(t));
end