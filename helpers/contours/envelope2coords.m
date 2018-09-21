function raw = envelope2coords(env, crv, sz, pm, mid)
%% envelope2coords: convert envelope coordinates to raw image coordinates
% This function blah blah
%
% Usage:
%   raw = env2nrm2raw(env, crv, sz, mp, mid)
%
% Input:
%   env: segment in envelope coordinates 
%   sz: size of envelope used for this envelope
%   crv: parent curve to standardize to
%   pm: P-matrix to rotate back to original reference frame
%   mid: midpoint from raw segment
%
% Output:
%   raw: segment in raw image coordinates
%

%% Convert envelope coordinates to normalized coordinates
nrm = reverseEnvelopeMethod(env, crv, sz);

%% Convert normalized coordinates to raw image coordinates
raw = reverseMidpointNorm(nrm, pm) + mid;

end