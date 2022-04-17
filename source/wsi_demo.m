function wsi_demo
% WSI_DEMO Whole Slide Image Demo
%
% WSI files can contain images at different resolution levels, as well as
% images of the whole slide (including label) and a map.
%
% MATLAB blockedImage can handle the resolution levels in a WSI file, and
% perform block processing. Blocks are not the same as levels.
%
% This demo loads a ndpi file that has been converted to tiff, presents the
% overview image if available and a highish resolution image with a
% rectangular ROI overlaid to simulate an MR voxel. 
% The ROI is initially in the top left corner and can be rotated and moved. 
% A label on the ROI gives the amount of 'lumen' within the ROI.
% Other functionality is provided by the cntext menu.
%
% NDPI
% ----
% NDPI format from Hamamatsu is TIFF-like but before trying to read in 
% MATLAB is best processed externally to create a well-formed tiff .
% 
% ndpitools for conversion to TIFF:
% https://www.imnc.in2p3.fr/pagesperso/deroulers/software/ndpitools/
%   Deroulers et al., Analyzing huge pathology images with open source software, 
%   Diagnostic Pathology 8:92 (2013).
% 
%  Example :   
%    ndpi2tiff -8 -m HMU_025_SH_A1.ndpi
%     -8 flag makes bigTIFF and -m means 'microscopic' avoiding the 
%      map and macroscopic layers.
%
% 
% Openslide documentation on the problems in NDPI:
% https://openslide.org/formats/hamamatsu/
% 
% DICOM WSI supplement (useful description of issues for WSI). 
% https://www.dicomstandard.org/News-dir/ftsup/docs/sups/sup145.pdf
%
%  Other software options might be 
%   OrthancWSIDicomzer and OrthancWSIWSIDicomToTiff. 
%   Google Health also has some stuff on all this.
%
%
% Data examples available from openslide folder:
%  https://openslide.cs.cmu.edu/download/openslide-testdata/Hamamatsu/
%
%
% Copyright 2022, David Atkinson, University College London
%  Archived on Zenodo: https://doi.org/10.5281/zenodo.6465073
%
% See also histoCM
%

% Choose a WSI file
group = 'wsi'; pref = 'ffn' ;
if ispref(group,pref)
  deffile = getpref(group, pref);
else
  deffile = '' ;
end
    
[fn,pn] = uigetfile('*','Select WSI file',deffile) ;
ffn = fullfile(pn,fn) ;

if ~exist(ffn,'file')
    return
else
    setpref(group, pref, ffn) ;
end

% Info from the file.
% File has information such as pixel sizes for each resolution level. These
% file resolution levels may be re-ordered when loading as a blockedImage.

iinfo = imfinfo(ffn) ;
nFLevels = length(iinfo) ; % Number of levels in file

% Load as a blockedImage
bim = blockedImage(ffn) ;

bimSize = bim.Size ;         % Sizes of all levels in blockedImage
nBLevel = size(bimSize,1) ;  % number of blockedImage levels

disp('Blocked Image Level and Sizes')
for iBLevel = 1: nBLevel
    disp([iBLevel bimSize(iBLevel,:)])
end


% Parse data to find correspondence of File and bim levels.
PS_FL_HW_mm  = zeros(nFLevels, 2) ;  % Pixel Spacing 
HW_FL = zeros(nFLevels, 2) ;         % height and width in pixels


for iFLevel = 1:nFLevels
  
    switch iinfo(iFLevel).ResolutionUnit
        case 'Centimeter'
            pixelInmm = 10 ;
        otherwise
            warning('wsi_demo:ResolutionUnit','Resoluton Unit must be Centimeter')
            pixelInmm = 10 ;
    end
 
    % PixelSpacing by File level in height-width order in mm
    PS_FL_HW_mm(iFLevel,:) = pixelInmm ./ ...
        [ iinfo(iFLevel).YResolution  iinfo(iFLevel).XResolution] ;

    HW_FL(iFLevel,:) = [ iinfo(iFLevel).Height iinfo(iFLevel).Width ] ;

    jHbim = find(bimSize(:,1)==HW_FL(iFLevel,1)) ;  % bim level with same height as file level
    jWbim = find(bimSize(:,2)==HW_FL(iFLevel,2)) ;

    if length(jHbim)~=1 || length(jWbim)~=1
        warning('wsi_demo:LevelCorrespondence','Must be exactly one matching Level')
        jfile2bim(iFLevel) = nan ;
        continue
    end
    if jHbim ~= jWbim
        warning('wsi_demo:SizeMismatch','H and W mismatch in level assignment')
    end

    jbim2file(jHbim)   = iFLevel ;
    jfile2bim(iFLevel) = jHbim ;
end

FOV_FL_HW_mm = PS_FL_HW_mm .* HW_FL ;  % Field of View

aRatio = FOV_FL_HW_mm(:,1) ./ FOV_FL_HW_mm(:,2) ;  % aspect ratio
nPixels_FL = HW_FL(:,1) .* HW_FL(:,2) ;            % number of pixels

disp(' ')
disp("File: " + ffn)  
for iFLevel = 1: nFLevels
    disp(['Level: ',num2str(iFLevel),' (file), ''',iinfo(iFLevel).ImageDescription, ''', ', ...
        num2str(jfile2bim(iFLevel)),' (bim), PS_HW microns: ', mat2str(1000*PS_FL_HW_mm(iFLevel,:)), ...
        '. (', num2str(HW_FL(iFLevel,1)),' x ', num2str(HW_FL(iFLevel,2)), ...
        '). FOV_HW: ',num2str(FOV_FL_HW_mm(iFLevel,1)), ' x ', num2str(FOV_FL_HW_mm(iFLevel,2)), ...
        ', Aspect: ',num2str(aRatio(iFLevel)) ])
end

% Summary images for those that are "wide" ie low aspect ratio
% This is intended for the whole slide view, which will not be present if
% the -m flag was used in ndpi2tiff

jwide = find(aRatio < 1/1.4) ;  % File levels of wide images
if ~isempty(jwide)
    figure('Name',iinfo(1).Filename)
    tiledlayout('flow')

    for iwide = 1:length(jwide)
        nexttile
        cim = gather(bim,'Level',jfile2bim(jwide(iwide))) ;
        imshow(cim,[])
        title(iinfo(jwide(iwide)).ImageDescription)
    end
end

% Following uses a fixed resolution image, rather than the bigimageshow
% Find level with a displayable resolution
approx_pix = 10000 * 10000 ;   % 19000 * 17000 is manageable on Mac with large RAM
[~,jDisp] = min(abs(nPixels_FL - approx_pix)) ;  % jDisp is file level to display

bLevel = jfile2bim(jDisp(1)) ;
figure('Name',['bLevel ',num2str(bLevel),': ',iinfo(jDisp(1)).ImageDescription])
disp(' '), disp("gathering bim layer " + bLevel)
cim = gather(bim,'Level',bLevel) ;
imshow(cim,[])


% Add a rectangle the size of an MR pixel
PS_MR_HW_mm = [1.5 1.5]   ;    % MR pixel size
PS_bL_HW_mm = PS_FL_HW_mm(jbim2file(bLevel),:)  ;  % histo pixel size
np = PS_MR_HW_mm ./ PS_bL_HW_mm ;       % number of histo pixels in MR

disp("Rectangle ROI: " + PS_MR_HW_mm(1)+" x "+ PS_MR_HW_mm(2)+ " mm, "+np(1)+" x "+np(2)+" pixels")

rr = drawrectangle('Position', [ 0 0 np(2) np(1)], ...
    'InteractionsAllowed','translate', 'Rotatable',false,...
    'LabelAlpha',0.4,'FaceAlpha',0.1,'Tag','voxel');
rr.ContextMenu = histoCM ;

% Create a "lumen" mask from luminosity using L*a*b space
%  No white point correction applied here
labx = rgb2lab(cim)/100  ;         % convert to L*a*b space 
thresh = graythresh(labx(:,:,1)) ; % find the lumen-tissue threshold
bwlumen = zeros(size(cim,[1 2])) ;     % make lumen mask
bwlumen(labx(:,:,1)>thresh)  = 1 ;

se = strel('disk',2);
bwlumen = imopen(bwlumen, se) ;

% eshow(bwlumen)

UD.bwlumen = bwlumen ;
UD.PS_bL_HW_mm = PS_bL_HW_mm ;

rr.UserData = UD ;  % Store with roi for callback use

addlistener(rr,'ROIMoved',@roievents);

disp("Luminosity threshold " + thresh)
end

% - - - - 
function roievents(src,~)
% ROIEVENTS Computes LWF when roi has been moved
    roi_mask = src.createMask ;
    UD = src.UserData ;
    linroi = roi_mask .* UD.bwlumen ;  % lumen within roi mask

    src.Label = ['LWF ',num2str(sum(linroi(:)/sum(roi_mask(:))))] ;
    %disp(['LWF ',num2str(sum(linroi(:)/sum(roi_mask(:))))])
end

% figure
% b=bigimageshow(bim) ;

% As read in, there is only one block per level - need to assign a block
% size for a level to then see a grid
% % bim.BlockSize(8,:) = [34 34 3];
% % b = bigimageshow(bim, 'ResolutionLevel',8,'GridVisible','on')
