function segtype = getSegmentType(req)
%% getSegmentType: Return requested segment type as string
% Simple switch statement to return Raw, Normal, or Envelope segment
%
% Usage:
%   segtype = getSegmentType(req)
%
% Input:
%   req: requested segment type
%
% Output:
%   segtype: string containing full name for requested segment type
%

switch req
    case 'raw'
        segtype = 'RawSegments';
        
    case 'norm'
        segtype = 'SVectors';
        
    case 'env'
        segtype = 'EnvelopeSegments';
        
    otherwise
        fprintf(2, 'Invalid type parameter: %s\n', req);
        segtype = '';
        return;
end

end