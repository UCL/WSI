# Whole Slide Imaging (WSI)
MATLAB code for handling histology whole slide images.

[source/wsi_demo.m](source/wsi_demo.m) shows an example of reading a histology file with multiple resolution levels.
Code analyses the order of the resolution levels after being read in by MATLAB's blockedImage.

Example of overlaying an ROI on one Resolution Level, setting the ROI context menu to control the ROI and displaying an image parameter.
![wsi_demo.png](/docs/wsi_demo.png)

For example NDPI files see: https://openslide.org/formats/hamamatsu/ 

For conversion from NDPI to TIFF, see: https://www.imnc.in2p3.fr/pagesperso/deroulers/software/ndpitools/ 
