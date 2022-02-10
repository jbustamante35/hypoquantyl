function [Y,Xf,Af] = N18(X,~,~)
%N18 neural network simulation function.
%
% Auto-generated by MATLAB, 15-Nov-2021 15:18:58.
% 
% [Y] = N18(X,~,~) takes these arguments:
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
x1_step1.xoffset = [-1396.75271772518;-1561.65607955089;-1386.81788498253;-1641.07966064304;-1385.8909313177;-1394.66947849866;-976.572338515372;-1069.76153929506;-913.24704847189;-881.461149192092;-940.343641966808;-830.867328564692;-762.335189513972;-925.124215159292;-613.941677112454;-811.333860424434;-464.596050713595;-696.291717270746;-615.275136169262;-567.029801723767];
x1_step1.gain = [0.000569532007647717;0.000608293328805863;0.000743863369469467;0.0006478130816029;0.000874914659364324;0.000828551987230656;0.0010586635516065;0.000977739796824683;0.00103706115737045;0.00124599143962939;0.000883339250997129;0.00125396926089722;0.00132370322068415;0.00122585531351382;0.00147726313696231;0.00143400385204409;0.0018369968582518;0.00134652292365207;0.0016705483417186;0.00169801488537172];
x1_step1.ymin = -1;

% Layer 1
b1 = [3.271808914960599779;5.2990914971311600112;-1.5170030979716511155;-4.65461751723841477;-5.5242127810386971731];
IW1_1 = [-0.36758065853944610346 -2.3691674442973700287 1.4927184069169805447 0.73814415002846445191 -1.4529521279079897766 0.57698285914435532007 2.9854776977050039299 0.46602712612004132398 -0.22575590929271624474 -0.81883982149386813632 1.0908184168995100904 -1.3784863270509237765 0.0042613502536723779288 -2.5297665465894882963 1.0415953441611738306 -2.1862247725606480664 2.4284987245909732678 0.38070557193183601763 -1.4189796718939471365 0.10357397639111226573;-2.0543055908964111822 -1.3440956487379398521 -3.5712538740306314367 -2.4020616998955914845 -1.6650000998763898608 -0.49877017817988533732 0.47891550027297719039 -3.0529652859948548382 0.82328101120125729562 0.93196603747023720743 -0.36514371701331355125 -0.81356744754986098922 -0.3566754423199414159 -1.6028402086216975153 2.5078336804549663519 1.169552271220401396 -0.87005190794854359027 0.88916193632312845452 -2.0150002627050609405 0.38125209953948924202;0.80211467117106760583 1.1343247103644742424 -1.4626769160231751776 0.23775994647670178894 0.012398339619316967042 1.5569240997097713031 -1.0268360545842587506 -0.34748981326201794362 -0.063940438680557321049 0.95348516121684945279 -0.0078148591304972314653 1.4544692479354646153 0.017762326877958464766 1.2653275258832412664 0.38557943631515528837 1.1678278895440761254 -1.362746059501040552 0.053302437596325538682 0.28052421905889246556 -0.60925226296625201172;0.19161105840884773421 1.7269568704352433741 1.3193755115121821309 -2.6817484550918875286 1.2111144285612587268 -3.473756036849013018 -2.7216284166301250025 0.25646744987424785478 -0.70156713110055890503 1.1315376497947842171 -2.0954643724887822565 2.1825106647993752773 -0.40645040607952354073 1.666973188947278528 -2.4130063564368144924 2.0979905346178346903 -2.7983374777690017687 0.47265226640518304135 2.9881297045568637749 0.099642515607788972876;-1.1402050362730236088 1.3024607019175482581 -1.7404551307761784162 -1.2670938308438119968 1.2982563081242963765 -0.72910831446947066414 -0.33495088052918403632 -2.6929583932206826447 0.0027653335753801515373 -1.4343458052858102381 0.31782988016135838016 -0.98043289591426530105 -1.078839530794811985 2.9204501644014300155 -2.6201857572748079583 1.5083714727864874217 -1.9050171210184760895 0.81893856654873187217 -0.91362950829883793347 -0.97074260578309867764];

% Layer 2
b2 = [-0.70703200277459909984;0.89424070566645752489];
LW2_1 = [-0.076586675720624414199 -0.021798914735710030188 -0.037843344595400500718 -0.061847726372850145293 -0.61034604353784716047;0.059177364545128188777 -0.26364077836354349316 0.031009633676712406586 0.024082908764216440223 0.69397809988626790734];

% Output 1
y1_step1.ymin = -1;
y1_step1.gain = [0.19743981069639;0.212463032730274];
y1_step1.xoffset = [-4.53377341285609;-4.47201044041348];

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