function [P, allCores, nCores] = setupParpool(nCores, testOn)
%% setupParpool: setup a parallel pool with designated number of cores
%
%
% Usage:
%   [P, allCores, halfCores] = setupParpool(nCores, testOn)
%
% Input:
%   nCores: number of workers to setup (defaults to using half available cores)
%   testOn: simple parfor loop to check parallel pool (defaults to true)
%
% Output:
%   P: handle to the parallel pool created
%   allCores: total number of cores available
%   nCores: total number of cores set up
%

%% Default to half the number of available cores and with testing on
t          = tic;
poolExists = ~isempty(gcp('nocreate'));
allCores   = feature('numcores');
halfCores  = ceil(allCores / 2);

if nargin < 1
    nCores = halfCores;
    testOn = 1;
end

%% Light it Up or Shut it Down
if nCores == 0
    %% Close the pool if selecting 0 cores
    fprintf('Shutting down parallel pool...\n');
    if poolExists
        delete(gcp('nocreate'));
    end
    
elseif nCores > allCores
    %% Error check to make sure you don't break anything
    fprintf(2, 'Too many cores selected [%d of %d total]\n', nCores, allCores);
    
elseif poolExists
    %% Decide if pool needs to be reset or not
    currCores = get(parcluster, 'NumWorkers');
    if nCores == currCores
        %% Pool with desired number cores already set up
        fprintf('\nParallel pool with %d Workers already set up!\n', ...
            currCores);
        P = gcp('nocreate');
    else
        %% Delete all open pools if they don't match number to set up
        fprintf('Shutting down pool of %d Workers and setting with %d Workers...\n', ...
            currCores, halfCores);
        delete(gcp('nocreate'));
        P = startPool(nCores, testOn);
    end
    
    
else
    %% Create parallel pool with nCores workers
    fprintf('Setting up pool of %d Workers...', nCores);
    P = startPool(nCores, testOn);
    
end

fprintf('DONE! [%.02f sec]\n', toc(t));

end

function P = startPool(nCores, testOn)
%% Start it up!
P = parcluster;
set(P, 'NumWorkers', nCores);
parpool(P);

% Test it out
if testOn
    parfor i = 1 : 100
        fprintf('%d.', i);
    end
end
end
