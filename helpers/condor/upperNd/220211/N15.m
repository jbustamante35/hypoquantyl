function [Y,Xf,Af] = N15(X,~,~)
%N15 neural network simulation function.
%
% Auto-generated by MATLAB, 11-Feb-2022 15:21:40.
% 
% [Y] = N15(X,~,~) takes these arguments:
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
x1_step1.xoffset = [-1402.20789282982;-1546.66021339065;-1406.90178492763;-1619.34306247223;-1339.9821327058;-1360.22379876149;-906.376276532021;-1046.01033923867;-875.339935848267;-837.652786446941;-932.255787170441;-921.886638411218;-645.665774338219;-697.67490056488;-585.782689235697;-566.346692292964;-584.560739371897;-773.689064883008;-616.974534202834;-560.646615359162];
x1_step1.gain = [0.00056131177980805;0.000599112942340463;0.000736572771669135;0.000654977241347466;0.000872767418353521;0.000840562269763725;0.00112176116125027;0.000956724043212926;0.00104770099728722;0.00125570409121648;0.000874314676048581;0.00119116748353191;0.00148298666509917;0.00122535564788881;0.0015373343336023;0.00149250195416437;0.00187457631823257;0.00133140032327146;0.00167655036192862;0.0018040446722073];
x1_step1.ymin = -1;

% Layer 1
b1 = [-5.117896936528919305;3.9474533686117108111;-16.941747610982030636;-0.0176667875569627153;-5.060964844838653498];
IW1_1 = [0.375286919688129883 3.1988888172495251183 0.28703602074388701038 -3.1799842791269221642 2.370628675273756425 0.41614560041051151806 -1.1790689871774799879 2.2466957247599408376 3.1434422171586882122 3.3501856434176877642 0.74786607835755647411 -2.8844272812909599324 1.7122199487280256314 1.8092199709816498832 0.74525170238055071792 4.332170052282214634 1.0895663201783385432 -0.69248310829855297399 -2.7993889703802787849 -0.70569774586672184835;2.9999721323238808246 -1.3292060691851816934 2.1375338122563101173 3.8531646246711752646 -6.5082642055923232149 -1.1282903073821533013 3.5993647841032223589 -0.23291692988672701992 -3.6923840457648942071 -1.6334756213982764006 -2.2057567330632417146 3.5073247969923060374 -3.6271770656084596496 0.14277236090596490126 0.67952946653223944562 -3.0359728506492795752 -2.0495225783841188871 -1.837154292440405623 0.28969345484366321175 0.98758073277996771822;-12.813324598651341546 -0.67827796353309321997 4.1365689082891234918 -11.215167184127635025 0.87074750699780389951 8.593636556099461643 2.5852602579751953193 9.0153559403446372755 8.3746136816264993286 -4.2885057778400641482 -12.158757866505974121 13.118866659530191043 23.885327374272023349 1.6089904028035044714 -6.2212863653418937204 -0.82398893425453545447 -0.30951406761157274072 -4.2973691831805744812 -4.864815439399999164 0.65049241728764872761;-0.068787634485842297227 -6.245293414795803244 -5.2622918664436832969 3.5963534288131091543 3.3244691742633540876 0.80286301218732170071 3.0440339119829840087 8.7791660906576982626 -18.246280631779200121 -5.7454211634062541947 21.834719438691855942 3.7246142308730290083 2.8265521282492667154 -9.5828539826744698615 3.1492724924558905819 -2.0778819180351386642 -10.46883149148771075 -15.23931673066367587 4.4830902339849707516 1.3667973393709993424;-3.3336395765392250468 -0.96394208078393006645 -2.1822579266155366362 -4.0381334788125702318 5.3252824247425625259 -0.4158354603582986031 -2.3472015617001762422 -1.7686144787397137801 2.0664346360062002539 2.3686766540780777035 -2.9001352013908059391 -2.0194797428448545418 2.5173710302582663623 -0.46330292961784425021 -1.9403922249688621005 0.62411836588220137578 2.3226608982463607944 0.32530822127856118264 -1.0667967783131580006 -0.69717314168498600857];

% Layer 2
b2 = [0.021490887952439013259;0.44582403603356829391];
LW2_1 = [-0.13783249911711689673 -0.097775762529219933938 -0.015905918895629072435 0.0016867486648252287898 -0.077106691445604433333;0.35045047205370227772 0.26821811086233782184 -0.023565428528190341534 0.014832515782617921099 0.29634856072377724345];

% Output 1
y1_step1.ymin = -1;
y1_step1.gain = [0.180269680102633;0.18143127018733];
y1_step1.xoffset = [-6.40785730340782;-6.01137402019492];

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
