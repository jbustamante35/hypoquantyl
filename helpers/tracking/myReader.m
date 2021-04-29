function [I] = myReader(varargin)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % example use:
    % 1) normal Read: 
    %       I = myReader(fileName)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2) read at domain:
    %       para{1} = centerPoint = with [row col]
    %       para{2} = width
    %       para{3} = height
    %       I = myReader(fileName,'atP',para);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 3) read at domain + toGray
    %       para{1} = centerPoint = with [row col]
    %       para{2} = width
    %       para{3} = height
    %       I = myReader(fileName,'atP',para,'toGray');
    % fullfill example 3:
    %{
        fileName = '';
        I = imread(I);
        [r c] = impixel(fileName);
        para{1} = [r c];
        para{2} = 100;
        para{1} = 300;
    %}
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % this is the general method for reading images
    % it can read the whole image, if there is only one
    % parameter. however, the second parameter, if given,
    % will be a cell array with:
    % {1} = center point
    % {2} = half_width - along dim2
    % {3} = half_height - along dim3
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % INPUTS:   
    %           curve   : = curve for analysis
    %           radius  : = radius for pca
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % OUTPUTS:  
    %           BV      : = a sequence of basis vectors for the tangent and
    %           normal space
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [file extraArgs] = parse_inputs(varargin);    
    %%%%%%%%%%%%%%%%%%%%%%%%%
    % if nargin is 1 then 
    %   case 1: file name
    %   case 2: image
    if isa(file,'imageStack');
        if isfield(extraArgs,'atP') | isfield(extraArgs,'iatP')
            
            if isfield(extraArgs,'atP')
                file = file{extraArgs.atP(3)};
                affine = extraArgs.atP{1};
            else
                file = file{extraArgs.iatP{1}(3,3)};
                affine = extraArgs.iatP{1};
            end
            
            affine(:,end-1) = [];
            affine(end-1,:) = [];
            
            if isfield(extraArgs,'atP')
                extraArgs.atP{1} = affine;
            else                
                extraArgs.iatP{1} = affine;
            end
            
            
        else
            fprintf(['request read from image stack at unknow frame']);
        end
    end
    
    
    if isa(file,'imageFile');file = file.fileName;end
    
    
    
    if ~isfield(extraArgs,'atP') & ~isfield(extraArgs,'iatP')
        if isa(file,'char') | isjava(file) | isa(file,'imageFile');
            % read image
            I = imread(file);
            % get info
            %info = imfinfo(file);
            info.BitDepth = 8;
            % normalize
            I = normalizeImage(I,extraArgs,info);
        else % all else reduce to number state
            I = file;
        end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%
    % if is 'atP'
    % look for extra args
    %%%%%%%%%%%%%%%%%%%%%%%%%
    elseif isfield(extraArgs,'atP')
        %%%%%%%%%%%%%%%%%%%%%%%%%
        % set variables
        para = extraArgs.atP;        
        cenP = para{1};
        %%%%%%%%%%%%%%%%%%%%%%%%%
        %
        half_width = para{2};
        half_height = para{3};
        COL = round([(cenP(1) - half_width) (cenP(1) + half_width)]);
        ROW = round([(cenP(2) - half_height) (cenP(2) + half_height)]);
        
        
        if isa(file,'char') | isa(file,'imageFile')
            % set variables
            I = imread(file,'PixelRegion',{ROW,COL});
        else            
            I = file(ROW(1):ROW(2),COL(1):COL(2));
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%
        % get info
        % info = imfinfo(file);
        info.BitDepth = 8;
        % normalize
        I = normalizeImage(I,extraArgs,info);
        
        
    elseif isfield(extraArgs,'iatP')
        % sample image at point P
        % if not spec then the third value of point
        % is the 
    
        % buffer around the point for cropping
        BUFFER = 10;
        
        try
            % move the doamin
            nD = extraArgs.iatP{1}*extraArgs.iatP{2};
        catch ME
            extraArgs.iatP{1}(:,end-1) = [];
            extraArgs.iatP{1}(end-1,:) = [];
            nD = extraArgs.iatP{1}*extraArgs.iatP{2};
        end
    
        % make the crop box based on location
        m = round(min(nD,[],2) - BUFFER);
        M = round(max(nD,[],2) + BUFFER);
        CP = mean([m M],2);
        SZ = round((M - m)/2);
        
        % make odd crop box
        if mod(SZ(1),2) == 1
            SZ(1) = SZ(1) + 1;
        end
        % make odd crop box
        if mod(SZ(2),2) == 1
            SZ(2) = SZ(2) + 1;
        end
        % read around crop box
        para{1} = round((CP(1:2)));
        para{2} = round(SZ(2));    
        para{3} = round(SZ(1));
        I = myReader(file,'atP',para,'toGray',1);
        
        % get offset from CP
        delta = CP(1:2) - extraArgs.iatP{1}(1:2,3);
        centerPointforPatch = (size(I)+1)/2;
        delta = delta + centerPointforPatch';
        affine = eye(3);
        affine(1:2,1:2) = extraArgs.iatP{1}(1:2,1:2);
        affine(1:2,end) = delta;
        nD = affine*extraArgs.iatP{2};
        I = myInterp(I,[nD(2,:)' nD(1,:)']);
        if numel(extraArgs.iatP) == 3
            I = reshape(I,extraArgs.iatP{3});
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% normalize image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [I] = normalizeImage(I,extraArgs,info)
    % convert
    I = double(I);
    I = I * (2^info.BitDepth)^-1;
    if isfield(extraArgs,'toGray')
        if extraArgs.toGray
            if size(I,3) == 3
                I = rgb2gray(I);
            else
                I = I;
            end    
        end
    end
end




%%%
%%% Function parse_inputs
%%%
function [filename, extraArgs, msg] = parse_inputs(v)
    try
        filename = '';
        extraArgs = {};    

        % Parse arguments based on their number.
        switch(numel(v))
            case 0
                % Not allowed.
                msg = 'Too few input arguments.';
                return;
            case 1
                % Filename only.
                filename = v{1};
            otherwise
                % Filename and format or other arguments.
                filename = v{1};
                v(1) = [];

                % loop over other arguments
                for e = 1:(numel(v)/2)
                    prop = (e-1)*2 + 1;
                    value = prop + 1;
                    extraArgs.(v{prop}) = v{value};
                end
        end
    catch
        
    end
end