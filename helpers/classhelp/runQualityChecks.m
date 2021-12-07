function goodFrmIdx = runQualityChecks(sdl, tests)
%% runQualityChecks: run tests on Seedling to determine frames with good data
% Run quality checks on various Seedling data. User determines which tests to
% run based on the indices marked 'true' in the 'tests' parameter.
%
% Current tests:
%   1) Empty coordinates
%   2) Empty PData
%   3) Empty image and contour data
%   4) Empty AnchorPoints
%   5) Out of frame growth
%   6) Collisions
%
% Usage:
%   goodFrmIdx = runQualityChecks(sdl, tests)
%
% Input:
%   sdl: full Seedling object to be tested
%   tests: [1 x n] array defining tests to run (see description above)
%
% Output:
%   goodFrmIdx: [1 x t] array defining frames that passed all tests
%

%% Vectorize data structure
goodFrmIdx = zeros(sum(tests), sdl.getLifetime);

%% 1) Check empty or NaN coordinates
num = 1;
if tests(num)
    crds    = sdl.getCoordinates(':');
    crdsIdx = ~isnan(sum(crds,2))';

    goodFrmIdx(num, crdsIdx) = 1;
end
num = num + 1;

%% 2) Check for empty PData
if tests(num)
    pdat    = sdl.getPData(':');
    pdatChk = struct2logical(pdat);
    pdatIdx = structfun(@(x) find(x == 1), pdatChk, 'UniformOutput', 0);

    fn      = fieldnames(pdatIdx);
    pdatMtc = zeros(numel(fn), sdl.getLifetime);
    for p = 1 : numel(fn)
        fld = fn{p}(~isspace(fn{p}));
        pdatMtc(p, pdatIdx.(fld)) = 1;
    end

    pdatFinal                  = sum(pdatMtc,1) == numel(fn);
    goodFrmIdx(num, pdatFinal) = 1;
end
num = num + 1;

%% 3) Check for empty image and ContourJB data
if tests(num)
    dat      = sdl.getImage;
    datFinal = cellfun(@isempty, dat) == false;
    goodFrmIdx(num, datFinal) = 1;
end
num = num + 1;

%% 4) Check for empty AnchorPoints
if tests(num)
    pts    = sdl.getAnchorPoints;
    ptsSum = sum(sum(permute(pts, [3 1 2]), 2),3);
    ptsIdx = ptsSum > 0;

    goodFrmIdx(num, ptsIdx) = 1;
end
num = num + 1;

%% 5) Check valid AnchorPoints for out of frame growth
if tests(num)
    % AnchorPoint is out of frame if it's touching the edge
end
num = num + 1;

%% 6) Check contours for collisions
if tests(num)
    % Collision is true if
end
% num = num + 1;

% Test Assessment: Check number of passing frames
goodFrmIdx = find(sum(goodFrmIdx,1) == sum(tests));
end