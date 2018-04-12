function dat = requestImageData(varargin)
%% requestImageData: determine what type of image data to return
% This function blah blah
%
% Usage:
%   img = requestImageData(varargin)
%
% Input:
%
%
% Output:
%   img: image data can either be structure, grayscale, bw, coordinates, etc depending on field
%

% Parse inputs to set properties
args = parseInput(varargin{:});

fn = fieldnames(args);
for k = fn'
    obj.(cell2mat(k)) = args.(cell2mat(k));
end


switch numel(fieldnames(args))
    case 1
        % Full structure of image data at all frames         
        dat = obj.Image;
        
    case 2
        % All image data at frame
        try             
            frm = varargin{2};
            dat = obj.Image(frm);
        catch
            fprintf(2, 'No image at frame %d \n', frm);
        end
        
    case 3
        % Specific image type at frame
        % Check if frame exists
        try             
            frm = varargin{2};
            req = varargin{3};
            dat = obj.Image(frm);
        catch
            fprintf(2, 'No image at frame %d \n', frm);
        end
        
        % Get requested data field
        try
            dfm = obj.Image(frm);
            dat = dfm.(req);
        catch
            fn  = fieldnames(dfm);
            str = sprintf('%s, ', fn{:});
            fprintf(2, 'Requested field must be either: %s\n', str);
        end
        
    otherwise
        fprintf(2, 'Error requesting data.\n');
        return;
end


end