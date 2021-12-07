function [Y,Xf,Af] = N4(X,~,~)
%N4 neural network simulation function.
%
% Auto-generated by MATLAB, 15-Nov-2021 15:18:45.
% 
% [Y] = N4(X,~,~) takes these arguments:
% 
%   X = 1xTS cell, 1 inputs over TS timesteps
%   Each X{1,ts} = 20xQ matrix, input #1 at timestep ts.
% 
% and returns:
%   Y = 1xTS cell of 1 outputs over TS timesteps.
%   Each Y{1,ts} = 2xQ matrix, output #1 at timestep ts.
% 
% where Q is number of samples (or series) and TS is the number of timesteps.

%#ok<*RPMT0>

% ===== NEURAL NETWORK CONSTANTS =====

% Input 1
x1_step1.xoffset = [-1378.72560151913;-1549.27852066869;-1287.95710467909;-1345.08789684906;-856.565888393657;-1359.62513540061;-910.730529948393;-857.76483974376;-1031.36604493973;-813.158358750558;-1362.08469876483;-743.320302982051;-671.399675673525;-767.22210769697;-667.870729437632;-619.533369377738;-619.661297626533;-546.902937784634;-680.05235505782;-661.271860047318];
x1_step1.gain = [0.00056905578141331;0.000601487179161109;0.000760338277168596;0.000667818961683427;0.000890274445686531;0.000820576148416968;0.00105642607298014;0.00105115112401491;0.00109842316740759;0.00111249193797342;0.000856774829603831;0.00123683128198217;0.00143820441744905;0.00117015409971427;0.00146312363322666;0.00143970950914631;0.00154410856773327;0.00183368491737847;0.00153611105853478;0.00172395392169596];
x1_step1.ymin = -1;

% Layer 1
b1 = [1.0501539290253489867;1.8090165608904622552;-1.7626865186918190265;1.3457123937051604923;2.9890246989572357705];
IW1_1 = [0.30333824341888099285 0.87661611972650910207 0.034337684321637848561 1.4236782395356202269 0.24311106960956826994 0.8265290327818455296 -0.46773874098095619134 0.71318166573521113438 0.90625021757176305037 0.608310980835693349 -0.86587354305236419183 -1.3278527033855662687 -0.097268061811019906893 0.70297264520495805762 1.962968920940255213 0.73608055861795840258 -0.076369820939510876801 -0.9983407237698822545 -1.1731917563869380672 0.50040590190217593136;-0.81599507704139440101 -1.1629404791562645283 -0.44403367864015419464 1.114951728100365802 -1.3597272053847961892 0.79364078193712594977 0.099069690268173263292 0.48107608585419692204 -1.4035010799742482224 -0.80368407823202148155 0.087248204766627660001 0.46959938907774295691 -1.1633356460332662241 0.66168661732794786801 0.46974831945127049071 -0.48314074080546409728 -0.9322304469964486362 -0.55476902850256326616 0.35500991288559546888 -0.044945328512217705419;0.9737727536480720314 1.5648455180213729498 0.26716678091888795832 -0.6611595600870806555 1.477276043016439111 -0.95185883104478130612 -0.46380084376607916274 -0.82707402212363334559 1.62346991650956185 0.39479944745441225562 -0.021182083931543249644 -0.64292505739616978566 1.9793978419398559065 -0.063408305227747804866 -0.50836944444134235521 0.67189926297781699116 1.8787517661842991767 -0.13423839576219373515 -0.0056575640111213021388 -1.1460292945208074844;1.066840711680759668 0.864323798964164558 1.4421677257243925574 -1.3719536253982533847 0.713957754098517694 -1.5190450517431384192 -0.92464446628786733928 -0.22513559414137648829 0.051186228218094875775 -0.12734095061632891288 -0.26762009485186250002 3.1085018138461690818 -1.5726537078954521132 -0.82689105493835679539 -1.2759506748012474642 -0.95858255934447367252 -0.36692477599073991534 2.2015771090792775055 2.4684190593445443085 1.5256165162285075798;0.22251901224632736342 -0.087165481206058798014 0.32234330857538123771 0.62066507422440286845 0.11584861066376700434 -0.054456437702852668326 -0.23672393765390137288 0.26100295588825089821 0.53145218943940708556 -0.29078282845211722574 -0.2775271870238397165 0.45557201371394029366 -0.66187299273219057927 0.35559884010635911533 0.87019375774971841064 -0.20739628274866028779 -0.50963595320065069316 0.53038941303858377907 1.0405174361367930391 0.73568081520141836993];

% Layer 2
b2 = [3.4391705914443124747;1.0071500405970887915];
LW2_1 = [0.064485601622635835284 0.17651636081253879729 0.0056706970429241214393 0.073539078659234327628 -3.6476801627923101101;0.018299759888023323789 -0.32256873130508184611 -0.31006650238982325085 0.010941127895323509919 -0.96214568045841197819];

% Output 1
y1_step1.ymin = -1;
y1_step1.gain = [0.136255947526047;0.152290855029599];
y1_step1.xoffset = [-7.62663433403022;-6.87811368428895];

% ===== SIMULATION ========

% Format Input Arguments
isCellX = iscell(X);
if ~isCellX
  X = {X};
end

% Dimensions
TS = size(X,2); % timesteps
if ~isempty(X)
  Q = size(X{1},2); % samples/series
else
  Q = 0;
end

% Allocate Outputs
Y = cell(1,TS);

% Time loop
for ts=1:TS

    % Input 1
    Xp1 = mapminmax_apply(X{1,ts},x1_step1);
    
    % Layer 1
    a1 = tansig_apply(repmat(b1,1,Q) + IW1_1*Xp1);
    
    % Layer 2
    a2 = repmat(b2,1,Q) + LW2_1*a1;
    
    % Output 1
    Y{1,ts} = mapminmax_reverse(a2,y1_step1);
end

% Final Delay States
Xf = cell(1,0);
Af = cell(2,0);

% Format Output Arguments
if ~isCellX
  Y = cell2mat(Y);
end
end

% ===== MODULE FUNCTIONS ========

% Map Minimum and Maximum Input Processing Function
function y = mapminmax_apply(x,settings)
  y = bsxfun(@minus,x,settings.xoffset);
  y = bsxfun(@times,y,settings.gain);
  y = bsxfun(@plus,y,settings.ymin);
end

% Sigmoid Symmetric Transfer Function
function a = tansig_apply(n,~)
  a = 2 ./ (1 + exp(-2*n)) - 1;
end

% Map Minimum and Maximum Output Reverse-Processing Function
function x = mapminmax_reverse(y,settings)
  x = bsxfun(@minus,y,settings.ymin);
  x = bsxfun(@rdivide,x,settings.gain);
  x = bsxfun(@plus,x,settings.xoffset);
end
