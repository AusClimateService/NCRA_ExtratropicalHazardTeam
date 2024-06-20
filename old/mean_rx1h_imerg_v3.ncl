load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

years=ispan(2001,2022,1)
adir="/scratch/eg3/asp561/IMERG/"
a=addfile(adir+"IMERG_aust_rx1h_2022.nc","r")
lat=a->lat
lon=a->lon

pr=new((/dimsizes(years),dimsizes(lat),dimsizes(lon)/),"float")

do y=0,dimsizes(years)-1
 print(years(y))
 a=addfile(adir+"IMERG_aust_rx1h_"+years(y)+".nc","r")
 pr(y,:,:)=a->pr
 delete(a)
end do

pr!0="time"
pr&time=years
pr!1="lat"
pr!2="lon"
pr&lon=lon
pr&lat=lat

pr2=dim_avg_n_Wrap(pr,0)

  res                      = True               ; plot mods desired
  res@cnFillOn             = True               ; turn on color fill
  res@cnFillDrawOrder = "Predraw"
  res@cnLineDrawOrder = "Predraw"
  res@cnLevelSelectionMode = "ExplicitLevels"
res@cnLevels             = (/8.,10.,12.,14.,16.,18.,20.,25.,30.,35.,40./)
  res@gsnAddCyclic = False
  res@gsnDraw  = False                          ; don't draw
  res@gsnFrame = False                          ; don't advance frame
  res@mpFillOn              = True
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


wks_type = "pdf"
;wks_type@wkOrientation = "landscape"
wks_type@wkPaperWidthF = 4
wks_type@wkPaperHeightF = 4.6


  res@mpFillAreaSpecifiers        = (/"land", "water"/)
  res@mpSpecifiedFillColors       = (/"transparent","white"/)
  res@mpOceanFillColor      = "white"
  res@mpLandFillColor             = "transparent"

  wks = gsn_open_wks(wks_type,"Rx1H_mean_20022022_IMERG")             ; send graphics to PNG file

  gsn_define_colormap(wks,"precip_11lev")
;  gsn_reverse_colormap(wks)

;    tmp=where(land2.lt.0.5,pr2@_FillValue,pr2)
;  copy_VarMeta(pr2,tmp)
   plot = gsn_csm_contour_map(wks,pr2, res)     ; create plot

draw(wks)
delete(wks)

tmp3=mask(pr,ismissing(mval),False)
I=ind(lon.ge.135)
tmp4=dim_avg_n_Wrap(tmp3(:,:,I),(/1,2/))



