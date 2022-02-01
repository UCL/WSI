function cmHandle = histoCM
% histoCM Context Menu for ROI on a histology image
% 
% User can select if ROI is rotatable, can be resized, and the
% corresponding size in mm.
%
%  roi_handle.ContextMenu = histoCM ;
%
% Copyright 2022, David Atkinson
%
%  See also wsi_demo

% Adatped from tiledimCM
 
% Set menu entries
cmHandle = uicontextmenu('ContextMenuOpeningFcn',@cmopening) ;
uimenu(cmHandle,'Label','Rotatable','Checked','off','Callback',@rotatable) ;
uimenu(cmHandle,'Label','Can be reshaped','Checked','off','Callback',@reshape) 
uimenu(cmHandle,'Label','Enter ROI size','Callback',@enterRoiSize) 

% % insert separator 
% uimenu(cmHandle,'Separator','on','Label','Delete this tile (no undo)','Callback',@deleteTile) ;

end


% Callbacks

function cmopening(src,~)
% Future - checks may be done here, e.g. for UserData. Below is from tiledimCM
%clickedfig = src.Parent ;
% htl = findobj(clickedfig,'Type','tiledlayout') ;
% if isempty(htl)
%     src.Children(1).Enable = 'off' ;
%     src.Children(2).Enable = 'off' ;
%     src.Children(3).Enable = 'off' ;
%     src.Children(4).Enable = 'off' ;
%     src.Children(5).Enable = 'off' ;
%     src.Children(6).Enable = 'off' ;
%     src.Children(7).Enable = 'off' ;
% end
end

function rotatable(src,~)
% Toggle rotatable
hroi = findobj(src.Parent.Parent,'Type','images.roi.rectangle') ;
switch src.Checked
    case 'on'
        hroi.Rotatable = false  ;
        src.Checked = 'off' ;
    case 'off'
        hroi.Rotatable = true  ;
        src.Checked = 'on' ;
end
end

function reshape(src,~)
% Toggle reshape
hroi = findobj(src.Parent.Parent,'Type','images.roi.rectangle') ;
switch src.Checked
    case 'on'
        hroi.InteractionsAllowed = 'translate'  ;
        src.Checked = 'off' ;
    case 'off'
        hroi.InteractionsAllowed = 'all'  ;
        src.Checked = 'on' ;
end
end

function enterRoiSize(src,~)
% Input dialog box to enter roi size in mm
hroi = findobj(src.Parent.Parent,'Type','images.roi.rectangle') ;
pos = hroi.Position ;
UD = hroi.UserData ;

prompt = {'Enter roi height (mm):','Enter roi width (mm):'};
dlgtitle = 'Input roi size';
dims = [1 35];
definput = {num2str(pos(4)*UD.PS_bL_HW_mm(1)), num2str(pos(3)*UD.PS_bL_HW_mm(2))};
answer = inputdlg(prompt,dlgtitle,dims,definput) ;

if ~isempty(answer)
    newsizemm = [str2num(answer{1})  str2num(answer{2})]  ;

    newpos = [pos(1) pos(2) newsizemm(2)/UD.PS_bL_HW_mm(2) newsizemm(1)/UD.PS_bL_HW_mm(1)] ;
    hroi.Position = newpos ;
end
end





