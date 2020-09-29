%% OutlineFixer: class to manually fix contours

classdef OutlineFixer < handle
    properties (Access = public)
        Circuit
        FigureIndex
        Image
        Contour
        InterpFix   % Interpolation size for fixing polygon
        SegSmooth
    end
    
    properties (Access = private)
        JBunits = get(0, 'ScreenPixelsPerInch'); % Normalized units for individual screen sizes
        YFactor = 2.5;                           % Relative y-position for top of figure
        YStep   = 0.3;                           % Recommended step size between job panels
        MainText
        MainButtons
        SubPlot
        ContourSize
        Polygon
        ResetContour
    end
    
    
    methods (Access = public)
        %% Set up main GUI
        function obj = OutlineFixer(varargin)
            %% Constructor method for OutlineFixer
            if ~isempty(varargin)
                % Parse inputs to set properties
                vargs = varargin;
            else
                % Set default properties for empty object
                vargs = {};
            end
            
            prps   = properties(class(obj));
            deflts = {...
                'FigureIndex' , 1 ; ...
                'InterpFix'   , 40 ; ...
                'SegSmooth'   , 10};
            obj    = classInputParser(obj, prps, deflts, vargs);
            
            [obj.Polygon , obj.SubPlot] = initializeFigure(obj);
            obj.ResetContour            = obj.Contour;
            obj.ContourSize             = size(obj.Contour, 1);
            obj.setupMainButtons;
            
        end
        
    end
    
    methods (Access = public)
        %% Helper methods
        function [h , pl] = initializeFigure(obj)
            %% initializeFigure: show image and contour polygon
            fidx = obj.FigureIndex;
            cntr = obj.Contour;
            
            figclr(fidx);
            pl = subplot(1,1,1);
            myimagesc(obj.Image);
            hold on;
            plt(cntr, 'g.', 5);
            
            intr = interpolateOutline(cntr, obj.InterpFix);
            h    = drawpolygon(pl, 'Position', intr);
        end
        
        function obj = setupMainButtons(obj)
            %% Function to set up Main Buttons objects
            u           = obj.JBunits;
            
             % Full screen, Half page
%             yPos        = obj.YFactor - (obj.YStep * 5);            
%             fullButtons = [u*03.00 , u*yPos  , u*3.50 , u*0.30];            
            
            % Half screen, Half page
            yPos        = obj.YFactor - (obj.YStep * 5);        
            fullButtons = [u*00.50 , u*yPos  , u*3.50 , u*0.30];
            setSizeL    = [u*00.05 , u*01.00 , u*00.25];
            
            % Main Buttons Panel
            f               = get(0, 'CurrentFigure');
            obj.MainButtons = uipanel(f, ...
                'units', 'pixels',       ...
                'Tag', 'MainButtons',    ...
                'pos', fullButtons,      ...
                'BorderType','n',        ...
                'BackgroundColor', 'w');
            
            boxSetup = struct(             ...
                'units', 'pixels',         ...
                'Style', 'pushbutton',     ...
                'FontUnits', 'pixels',     ...
                'FontName', 'DejaVu Sans', ...
                'FontWeight', 'Bold',      ...
                'BackgroundColor', 'w',    ...
                'FontSize', 12);
            
            % Main Buttons
            uicontrol(obj.MainButtons, boxSetup, 'Position', [u*00.10 setSizeL], 'Tag', 'ConfirmFix', 'String', 'Confirm', 'Callback', @ConfirmFix);
            uicontrol(obj.MainButtons, boxSetup, 'Position', [u*01.25 setSizeL], 'Tag', 'AutoSegment', 'String', 'AutoSegment', 'Callback', @AutoSegment);
            uicontrol(obj.MainButtons, boxSetup, 'Position', [u*02.40 setSizeL], 'Tag', 'Reset', 'String', 'Reset', 'Callback', @Reset);
            
            %% ============ Start of  Primary functions for MainButtons Callback ================ %%
            function ConfirmFix(hObject, ~)
                %% ConfirmFix: confirm contour fix and send back to CircuitJB
                trc         = obj.Polygon.Position;
                intr        = interpolateOutline(trc, obj.ContourSize);
                obj.Contour = unique(intr, 'rows', 'stable');                
                
                cfix = obj.Contour;
                crc  = obj.Circuit;
                crc.setRawOutline(cfix);
                crc.ConvertRawOutlines;
                crc.ConvertRawPoints;
                crc.ReconfigInterpOutline;
            end
            
            function AutoSegment(hObject, ~)
                %% segmentButton: auto-segmentation when fixing outline
                msk = segmentObjectsHQ(obj.Image, obj.SegSmooth);
                trc = extractContour(msk, 300);
                
                intr = interpolateOutline(trc, obj.InterpFix);
                intr = unique(intr, 'rows', 'stable');
                
                % Update Polygon
                plt(intr, 'y.', 5);
                obj.Polygon.Position = intr;
            end
            
            function Reset(hObject, ~)
                %% ConfirmFix: confirm contour fix and send back to CircuitJB
                obj.Contour = obj.ResetContour;
                intr        = interpolateOutline(obj.Contour, obj.InterpFix);
                
                % Update Polygon
                obj.Polygon.Position = intr;
            end
            %% ====== End of Primary functions for MainButtons Callback ====== %%
            
        end
    end
end
