function cmHandle = histoCM
% histoCM Context Menu for a voxel ROI on a histology image
% 
% Menu offers the following features:
%  Select if ROI is rotatable, 
%  Select if ROI can be reshaped (translations are always allowed here)
%  Select new width and height in mm.
%  Show the luminal space in the ROI.
%  Produced LWF map (from ROI tiled across visible axes).
%  Move ROI one voxel to right, left, up or down.
%
%  roi_handle.ContextMenu = histoCM ;
%
% Copyright 2022, David Atkinson, University College London
%  Archived on Zenodo: https://doi.org/10.5281/zenodo.6465073
%
%  See also wsi_demo

% Adapted from tiledimCM
 
% Set menu entries
cmHandle = uicontextmenu('ContextMenuOpeningFcn',@cmopening) ;
uimenu(cmHandle,'Label','Rotatable','Checked','off','Callback',@rotatable) ;
uimenu(cmHandle,'Label','Can be reshaped','Checked','off','Callback',@reshape) 
uimenu(cmHandle,'Label','Enter ROI size (mm)','Callback',@enterRoiSize) 
uimenu(cmHandle,'Label','Show lumen in ROI','Callback',@showLumen)
uimenu(cmHandle,'Label','Tile LWF','Callback',@tileLWF) 

uimenu(cmHandle,'Label','Move right one voxel','Tag','right','Callback',@moveOneVoxel, 'Separator','on') 
uimenu(cmHandle,'Label','Move left one voxel','Tag','left','Callback',@moveOneVoxel) 
uimenu(cmHandle,'Label','Move up one voxel','Tag','up','Callback',@moveOneVoxel) 
uimenu(cmHandle,'Label','Move down one voxel','Tag','down','Callback',@moveOneVoxel) 

end


% Callbacks

function cmopening(src,~)
% Checks may be done here, e.g. for UserData. 
hroi = findobj(src.Parent.Parent,'Type','images.roi.rectangle','Tag','voxel') ;
if isempty(hroi) || ~ishandle(hroi) || isempty(hroi.UserData)
    src.Children.Enable = 'off' ;
end

end

function rotatable(src,~)
% Toggle rotatable
hroi = findobj(src.Parent.Parent,'Type','images.roi.rectangle','Tag','voxel') ;
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
hroi = findobj(src.Parent.Parent,'Type','images.roi.rectangle','Tag','voxel') ;
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
hroi = findobj(src.Parent.Parent,'Type','images.roi.rectangle','Tag','voxel') ;
pos = hroi.Position ;
UD = hroi.UserData ;

if isempty(UD)
    warning('UserData not set')
    return
end

prompt = {'Enter roi height (mm):','Enter roi width (mm):'};
dlgtitle = 'Input roi size';
dims = [1 35];
definput = {num2str(pos(4)*UD.PS_bL_HW_mm(1)), num2str(pos(3)*UD.PS_bL_HW_mm(2))};
answer = inputdlg(prompt,dlgtitle,dims,definput) ;

if ~isempty(answer)
    newsizemm = [str2double(answer{1})  str2double(answer{2})]  ;

    newpos = [pos(1) pos(2) newsizemm(2)/UD.PS_bL_HW_mm(2) newsizemm(1)/UD.PS_bL_HW_mm(1)] ;
    hroi.Position = newpos ;
    notify(hroi,'ROIMoved') ;
end
end

function moveOneVoxel(src,~)
% Move ROI left, right, up or down
% Y increases down 

hroi = findobj(src.Parent.Parent,'Type','images.roi.rectangle','Tag','voxel') ;
pos = hroi.Position ;
verts = hroi.Vertices ; % top-left, bot-left, bot-right, top-right

switch src.Tag
    case 'right'
        dx = verts(4,1)-verts(1,1) ;
        dy = verts(4,2)-verts(1,2) ;
    case 'left'
        dx = verts(1,1) - verts(4,1) ;
        dy = verts(1,2) - verts(4,2) ;
    case 'up'
        dx = verts(1,1) - verts(2,1) ;
        dy = verts(1,2) - verts(2,2) ;
    case 'down'
        dx = verts(2,1) - verts(1,1) ;
        dy = verts(2,2) - verts(1,2) ;
    otherwise
        warning('Unknown dirction')
end

newpos = [pos(1)+dx pos(2)+dy pos(3) pos(4)] ;
hroi.Position = newpos ;
notify(hroi,'ROIMoved') ;

end

function tileLWF(src,~)
% tileLWF Produces LWF image from tiles of the ROI
% 
% Note y increases down and Position(1) and (2) refer to top-left
% Also Position is for an UNROTATED ROI (whereas Vertices take any rotation
% into account.

hroi = findobj(src.Parent.Parent,'Type','images.roi.rectangle','Tag','voxel') ;

pos = hroi.Position ;
verts = hroi.Vertices ; % top-left, bot-left, bot-right, top-right

% largest diagonal size of image
ax=findobj(src.Parent.Parent,'Type','Axes') ;
d1=sqrt((ax.YLim(2)-ax.YLim(1)).^2 + (ax.XLim(2)-ax.XLim(1)).^2) ;

dxx = verts(1,1) - verts(4,1) ; % step in x for move to right
dxy = verts(1,2) - verts(4,2) ; % step in y for move to right

dyx = verts(1,1) - verts(2,1) ;
dyy = verts(1,2) - verts(2,2) ;

nhx = ceil(abs(d1/dxx)) ; % number of voxels to furthest possible edge
nhy = ceil(abs(d1/dyy)) ;

indx = -nhx:nhx ;
indy = -nhy:nhy ;

UD = hroi.UserData ;

lwfim = zeros(size(UD.bwlumen)) ; % for the final LWF image
m1 = ones(size(lwfim)) ;

hroi.Label = '' ; % turn off label during step through image
for ix = 1:length(indx)
    for iy = 1:length(indy)
      
        thisposx = pos(1)+(indx(ix)*dxx) + (indy(iy)*dyx);
        thisposy = pos(2)+(indx(ix)*dxy) + (indy(iy)*dyy);

        if thisposx<(ax.XLim(1)-abs(dxx)) || thisposx>ax.XLim(2) || ...
                thisposy<(ax.YLim(1)-abs(dyy)) || thisposy>ax.YLim(2)
            continue
        end

        hroi.Position = [thisposx thisposy pos(3) pos(4)] ;
        
        roi_mask = createMask(hroi,UD.bwlumen) ;
        
        linroi = roi_mask .* UD.bwlumen ; 
       
        lwf = sum(linroi(:)/sum(roi_mask(:))) ;

        if ~isnan(lwf)
          lwfim = lwfim + roi_mask.*lwf.*m1 ;
        end

    end
end

hroi.Position = pos ;
notify(hroi,'ROIMoved')

eshow(lwfim)

end

function showLumen(src,~)
% showLumen Shows the luminal space within the ROI (for visual checking)
hroi = findobj(src.Parent.Parent,'Type','images.roi.rectangle','Tag','voxel') ;
roi_mask = hroi.createMask ;
UD = hroi.UserData ;
linroi = roi_mask .* UD.bwlumen ;  % lumen within roi mask

eshow(linroi)

end
