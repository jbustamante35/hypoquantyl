function [b , dpre] = pcaRegression(DIN, DOUT, mth)
%% pcaRegression:
% Note that this is different from pcaRegression in CarrotSweeper
%
% Usage:
%   [b , dpre] = pcaRegression(DIN, DOUT, mth)
%
% Input:
%   DIN: raw data input
%   DOUT: target values
%   mth: method to obtain covariance [pcr|cca]
%
% Output:
%   b: regressor
%   dpre: predicted values given input data
%

%% Determine  method for regressino
if nargin < 3; mth = 'pcr'; end

switch mth
    case 'pcr'
        %% 
        ND   = DIN - mean(DIN);
        b    = DOUT \ ND;
        dpre = DOUT * b;
        
    case 'cca'
        %% 
        X           = DOUT;
        Y           = DIN - mean(DIN);
        [A,B,R,U,V] = canoncorr(X,Y);
        
        b    = A;
        dpre = U / B;
        
    otherwise
        fprintf(2, 'Regression Method %s must be [pcr|cca]\n', mth);
        [b , dpre] = deal([]);
end
end
