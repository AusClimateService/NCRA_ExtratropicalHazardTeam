
;infile=addfile("/scratch/eg3/asp561/agcd/awap_percentiles.nc","r")
infile=addfile("/scratch/eg3/asp561/BARRA2/barra_percentiles.nc","r")
percentiles=infile->percentiles_all
quantiles=percentiles&quantile

;mfile=addfile("/g/data/eg3/asp561/Shapefiles/mask_australia_0.05deg.nc","r")
;mval=mfile->landmask
mfile=addfile("/g/data/ob53/BARRA2/output/reanalysis/AUS-11/BOM/ERA5/historical/hres/BARRA-R2/v1/fx/sftlf/v20231001/sftlf_AUS-11_ERA5_historical_hres_BOM_BARRA-R2_v1_fx.nc","r")
mval=mfile->sftlf

  res                      = True               ; plot mods desired
  res@cnFillOn             = True               ; turn on color fill
  res@cnLevelSelectionMode = "ExplicitLevels"
;  res@cnLevels             = (/20,30,40,50,60,70,80,100,120,140,160/); ispan(20,120,10)
  res@cnLevels = (/2.,5.,10.,15.,20.,30.,40.,50.,60.,80.,100./)
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


wks_type = "pdf"
;wks_type@wkOrientation = "landscape"
wks_type@wkPaperWidthF = 4
wks_type@wkPaperHeightF = 4.6

do p=0,2
    wks = gsn_open_wks(wks_type,"BARRA_percentiles_19812010_Q"+quantiles(p))             ; send graphics to PNG file

  gsn_define_colormap(wks,"precip_11lev")
;  gsn_reverse_colormap(wks)
    
    tmp=where(mval.lt.0.5,percentiles@_FillValue,percentiles(p,:,:))
  copy_VarMeta(percentiles(p,:,:),tmp)
   plot = gsn_csm_contour_map(wks,tmp, res)     ; create plot

draw(wks)
delete(wks)
end do

