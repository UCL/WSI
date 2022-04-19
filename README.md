Releases are automatically archived on Zenodo. The Zenodo Context DOI (for all versions) is: 
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6465073.svg)](https://doi.org/10.5281/zenodo.6465073)

## Download
This repo manages all the files in the MATLAB Project. To use the code, only the files in the [source](source) folder are needed. A Toolbox file for easy installation is also provided: [WSI.mltbx](WSI.mltbx) 

# Whole Slide Imaging (WSI)

MATLAB code for handling histology whole slide images.

[source/wsi_demo.m](source/wsi_demo.m) shows an example of reading a histology file with multiple resolution levels.
Code analyses the order of the resolution levels after being read in by MATLAB's blockedImage. Uses `gather` to get an image at one resolution level for processing.

Example of overlaying an ROI on an image from one Resolution Level and the context menu:
![wsi_demo.png](/docs/wsi_demo.png)

The `Tile LWF` option replicates the ROI across the current axes to give an MR-like LWF map:
![tiledLWF.png](/docs/tiledLWF.png)

For example NDPI files see: https://openslide.org/formats/hamamatsu/ 

For conversion from NDPI to TIFF, see: https://www.imnc.in2p3.fr/pagesperso/deroulers/software/ndpitools/ 
