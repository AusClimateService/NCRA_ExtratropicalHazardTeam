; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;
; This file, being a user-created file, is not automatically loaded
load "~/Shapefiles/shapefile_utils.ncl"

gridfile="/g/data/eg3/asp561/Shapefiles/mask_australia_0.05deg.nc"

shapedir="/g/data/eg3/asp561/Shapefiles/NCRA/"
shapefile="NCRA_regions.shp"

a=addfile(gridfile,"r")
mask1=a->landmask

shape=addfile(shapedir+shapefile,"r")

names=shape->NCRA_name
names2=str_sub_str(names," ","_")

opt             = True
opt@return_mask = True

opt@shape_var = "NCRA_name"

do i=0,dimsizes(names)-1
  opt@shape_names=names(i)
  mask2=shapefile_mask_data(mask1,shapedir+shapefile,opt)
  copy_VarMeta(mask1,mask2)

  outfile="mask_NCRA_"+names2(i)+"_0.05deg.nc"
  b=addfile(shapedir+outfile,"c")
  b->landmask=mask2
  delete(mask2)
end do

;write_table("basin_names_nospace.txt","w",[/names2/],"%s")


