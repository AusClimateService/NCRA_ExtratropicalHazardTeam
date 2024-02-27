load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

adir="/g/data/zv2/agcd/v1-0-1/precip/total/r005/01day/"
years=ispan(1991,2020,1)

a=addfile(adir+"agcd_v1-0-1_precip_total_r005_daily_2022.nc","r")
lat=a->lat
lon=a->lon
pr=new((/dimsizes(years),dimsizes(lat),dimsizes(lon)/),"float")

do y=0,dimsizes(years)-1
 print(years(y))
 a=addfile(adir+"agcd_v1-0-1_precip_total_r005_daily_"+years(y)+".nc","r")
 tmp=a->precip

; Rx5d version
 b=dimsizes(tmp)
 tmp2=new((/b(0)+4,b(1),b(2)/),typeof(tmp))
 tmp2(4:(b(0)+3),:,:)=tmp
 delete([/tmp,a/])

 a=addfile(adir+"agcd_v1-0-1_precip_total_r005_daily_"+(years(y)-1)+".nc","r")
 tmp=a->precip
 b=dimsizes(tmp)
 tmp2(0:3,:,:)=tmp((b(0)-4):(b(0)-1),:,:)
 tmp3=dim_acumrun_n(tmp2,5,0,0) 
 pr(y,:,:)=dim_max_n(tmp3,0)
 delete([/tmp,a,tmp2,tmp3/])
end do

pr!0="time"
pr&time=years
pr!1="lat"
pr&lat=lat
pr!2="lon"
pr&lon=lon

pr2=dim_avg_n_Wrap(pr,0)

mfile=addfile("/g/data/eg3/asp561/Shapefiles/mask_australia_0.05deg.nc","r")
mval=mfile->landmask
mval=where(mval.eq.0,mval@_FillValue,mval)

  res                      = True               ; plot mods desired
  res@cnFillOn             = True               ; turn on color fill
  res@cnLevelSelectionMode = "ExplicitLevels"
;  res@cnLevels             = (/20,30,40,50,60,70,80,100,120,140,160/); ispan(20,120,10)
  res@cnLevels = (/25,50,75,100,125,150,175,200,250,300,400/)
  res@gsnAddCyclic = False
  res@gsnDraw  = False                          ; don't draw
  res@gsnFrame = False                          ; don't advance frame
  res@mpFillOn              = False
  res@mpDataBaseVersion     = "MediumRes"          ; Default is LowRes
  res@mpOutlineDrawOrder    = "PostDraw"           ; Draw map outlines last
  res@mpGridAndLimbOn       = False                ; Turn off lat/lon lines
  res@pmTickMarkDisplayMode = "Always"             ; Turn on map tickmarks
  res@mpLimitMode        = "Corners"               ; Portion of map to zoom
  res@mpLeftCornerLatF   = -45.
  res@mpLeftCornerLonF   = 110.
  res@mpRightCornerLatF  = -10.
  res@mpRightCornerLonF  = 155.
  res@mpGridLineDashPattern = 2
  res@mpGridLineThicknessF = 0.5
  res@mpProjection = "CylindricalEquidistant"
  res@gsnLeftString=""
  res@gsnRightString=""
;  res@cnFillMode = "RasterFill"
  res@cnLinesOn = False
  res@lbLabelBarOn        = True
res@lbOrientation               = "Vertical"
  res@cnLineLabelsOn = False
  res@gsnMaximize      = True                   ; use full page
  res@gsnPaperOrientation = "portrait"



  opts_psl = True
;     opts_psl@cnLineColor       = "Black"
      opts_psl@cnFillOn = True
     opts_psl@cnInfoLabelOn     = False
;     opts_psl@gsnContourLineThicknessesScale = 2
     opts_psl@gsnDraw         = False
     opts_psl@gsnFrame        = False
     opts_psl@cnLevelSelectionMode = "ExplicitLevels"
;     opts_psl@cnLevels             = (/ -100.,0.05,100./)
;     opts_psl@gsnContourPosLineDashPattern = 2
  opts_psl@cnMonoFillPattern    = False        ; Use multiple fill patterns
  opts_psl@cnMonoFillColor      = True         ; Use single pattern color
  opts_psl@cnLevels = (/0.05/)
  opts_psl@cnFillPatterns =(/6,-1/)
  opts_psl@cnFillOpacityF = 0.5
  opts_psl@cnLinesOn            = False
  opts_psl@lbLabelBarOn        = False
opts_psl@cnLineLabelsOn = False

wks_type = "pdf"
;wks_type@wkOrientation = "landscape"
wks_type@wkPaperWidthF = 4
wks_type@wkPaperHeightF = 4.6

  wks = gsn_open_wks(wks_type,"Rx5D_mean_19912020_AWAP")             ; send graphics to PNG file

  gsn_define_colormap(wks,"precip_11lev")
;  gsn_reverse_colormap(wks)

    tmp=where(ismissing(mval),pr2@_FillValue,pr2)
  copy_VarMeta(pr2,tmp)
   plot = gsn_csm_contour_map(wks,tmp, res)     ; create plot

draw(wks)
delete(wks)

tmp3=mask(pr,ismissing(mval),False)
I=ind(lon.ge.135)
tmp4=dim_avg_n_Wrap(tmp3(:,:,I),(/1,2/))



