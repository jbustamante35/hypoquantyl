function [U,E,L] = PCA_FIT_FULLws(M,COM,disp,sigma,nU)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % performs PCA (principal component analysis) using eigenvector
    % decomposition, backprojects to simulate the data and calculates the
    % error
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % INPUTS:   
    %           M       : = data matrix
    %           COM     : = number of vectors 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % OUTPUTS:  
    %           S       : = simulated signal (reconstruction)
    %           C       : = components ("unique" fingerprint)
    %           U       : = mean of data
    %           E       : = basis vectors 
    %           L       : = eig values
    %           ERR     : = error in reconstruction
    %           LAM     : = percent explained
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % sigma default
    if nargin <= 2
        disp = false;
    end
    if nargin <= 3
        sigma = 'largestabs';
    end
    % take the mean
    if disp;fprintf(['PCA:start:taking off mean \n']);end
    toOpDim = 1;
    U = mean(M,toOpDim);
    
    if nargin == 4
        fprintf('HELLO THIS IS THE PLACE WHERE YOU USE PCA ON DELTA MEAN.\n');
        U = nU;
    end
    M = bsxfun(@minus,M,U);
    if disp;fprintf(['PCA:end:taking off mean \n']);end
    % look at covariance
    if disp;fprintf(['PCA:start:creating COV \n']);end
    try
        if disp;fprintf(['i am speed.l.mcqueen \n']);end
        COV = mtimesx(M,'T',M,'speed');
        if disp;fprintf(['and you know that.l.mcqueen \n']);end
    catch
        COV = M'*M;
    end
    COV = COV / size(M,toOpDim);
    if disp;fprintf(['PCA:end:creating COV \n']);end
    % eig vector decomp
    if disp;fprintf(['PCA:start:decomposing COV \n']);end
    if ~isa(COV,'double')
        COV= double(COV);
    end
    [E,L] = eigs(COV,COM,sigma);
    if disp;fprintf(['PCA:end:decomposing COV \n']);end
end
