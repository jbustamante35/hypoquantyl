function pts = minikini(fin, para, fidx, fnm)
%% minikini:
%
%
%
%
%

%%
switch nargin
    case 2
        fidx = 1;
        fnm  = [];
    case 3
        fnm = [];
end

%%
try
    pts = para.pointList;
    TH  = para.THRESH;
    
    % Get total frames
    TIME = para.TIME;
    if isempty(para.TIME)
        TIME = 1 : (numel(fin.Files));
    end
    
    % Init tracking vars - only allow for RAD via user
    RAD    = para.domainPara{1}.value{1}(2);
    BUFFER = 20;
    RADIUS = RAD + BUFFER;
    THRESH = 10^-6;
    
    % Create track domain
    domainPara = genDomains(para.domainPara);
    ndom       = domainPara{1}.d(1:2,:)';
    
    %% Track through frames
    frms = numel(TIME) - 1;
    for frm = 1 : frms
        t       = tic;
        tm      = TIME(frm);
        tm_next = TIME(frm + 1);
        
        % init the track for non-linear
        initP = [1 , 0 , 0 , 1 , 0 , 0];
        
        % get the images from the tensor via the default view
        I = double(fin.readimage(tm));
        G = double(fin.readimage(tm_next));
        
        % track each point
        for pt = 1:size(pts,1)
            % conditional statement for tracking
            if pts(pt,2,frm) > TH
                T = TR(I, G, pts(pt,:,frm), RADIUS, ndom, THRESH, initP, 1); % track is not tensor ready
            else
                T = [0 , 0 , 0 , 0 , 0 , 0];
            end
            pts(pt,:,frm+1) = pts(pt,:,frm) + fliplr((T(end-1:end)));
        end
        
        %% Display to screen
        if fidx
            figclr(fidx);
            myimagesc(I);
            hold on;
            plt(fliplr(pts(:, :, frm)), 'r.', 3);
            allpts = 1 : size(pts,1);
            ycrcs  = arrayfun(@(k) pts(k, 1, frm) + RAD * sin(linspace(-pi, pi, 200)), allpts, 'UniformOutput', 0);
            xcrcs  = arrayfun(@(k) pts(k, 2, frm) + RAD * cos(linspace(-pi, pi, 200)), allpts, 'UniformOutput', 0);
            crcs   = cellfun(@(x,y) [x ; y]', xcrcs, ycrcs, 'UniformOutput', 0);
            cellfun(@(x) plt(x, 'b-', 1), crcs, 'UniformOutput', 0);
            
            % Show trails
%             trls = arrayfun(@(x) fliplr(squeeze(pts(x,:,:))'), 1 : size(pts,1), 'UniformOutput', 0);
%             cellfun(@(x) plt(x, '.', 3), trls, 'UniformOutput', 0);
            
            ttl = sprintf('Frame %d of %d', frm, frms);
            title(ttl, 'FontSize', 10);
            drawnow;
            
            if ~isempty(fnm)
                fprintf('Saving frame %d of %d as png...', frm, frms);
                fnms = {sprintf('%s_frame%03dof%03d', fnm, frm, frms)};
                saveFiguresJB(fidx, fnms, 0, 'png');
                fprintf('DONE!...');
            end
            
        end
        
        fprintf('Frame %d of %d [%.03f sec]\n', frm , frms, toc(t));
    end
    
catch ME
    ME.message
    ME.stack
end
end

function T = TR(I, G, P, RADIUS, X, PER, T, externalInterp)
%% perform the tracking
% this function is NOT tensor ready
% it will drop back to OLD way
%
% Input:
%   I: first image
%   G: second image
%   P: point being tracked
%   RADIUS: the clipping window
%   X:
%   PER:
%   T:
%   externalInterp:
%
% Output:
%   T:
%

%%
% Clip out image patch around point
[U1 , U2] = ndgrid(P(1) - RADIUS : P(1) + RADIUS, P(2) - RADIUS : P(2) + RADIUS);

% Determine using external or internal interpolation
if externalInterp
    I = ba_interp2(I, U2, U1);
    G = ba_interp2(G, U2, U1);
else
    I = interp2(I, U2, U1);
    G = interp2(G, U2, U1);
end

% Take gradient
[D1 , D2] = gradient(I);
dX        = [1 , 1];

% Interpolate
if externalInterp
    Ii  = ba_interp2(I,  X(:,1) + RADIUS + 1, X(:,2) + RADIUS + 1);
    D1i = ba_interp2(D1, X(:,1) + RADIUS + 1, X(:,2) + RADIUS + 1);
    D2i = ba_interp2(D2, X(:,1) + RADIUS + 1, X(:,2) + RADIUS + 1);
else
    Ii  = interp2(I,  X(:,1) + RADIUS+1, X(:,2) + RADIUS + 1);
    D1i = interp2(D1, X(:,1) + RADIUS+1, X(:,2) + RADIUS + 1);
    D2i = interp2(D2, X(:,1) + RADIUS+1, X(:,2) + RADIUS + 1);
end

%% Interpolate
D    = [D1i , D2i];
icnt = 1;
flag = 1;
N    = [];
while flag & norm(dX) > PER
    
    TR = reshape(T,[2 3]);
    Xt = (TR*[X ones(size(X,1),1)]')';
    
    % if internal
    if externalInterp
        Gi = ba_interp2(G,Xt(:,1)+RADIUS+1,Xt(:,2)+RADIUS+1);
    else
        Gi = interp2(G,Xt(:,1)+RADIUS+1,Xt(:,2)+RADIUS+1);
    end
    
    % Solution vector
    Mi = [(D .* repmat(X(:,1), [1 , 2])) , (D(:,1)) , ...
        (D .* repmat(X(:,2), [1 , 2])) , (D(:,2))];
    dY = Mi \ (Ii - Gi);
    dX = [dY(1) , dY(2) , dY(4) , dY(5) , dY(3) , dY(6)]';
    
    % Displace vector
    T       = T + dX';
    N(icnt) = norm(Ii(:)-Gi(:));
    
    % Ensure norm is minimizing
    if icnt >= 2
        flag = N(icnt) <  N(icnt-1);
    end
    icnt = icnt + 1;
end
end
