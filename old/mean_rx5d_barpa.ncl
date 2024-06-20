load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

years=ispan(1991,2060,1)
ssp="ssp370"
bdir="/g/data/ia39/australian-climate-service/test-data/CORDEX-CMIP6/output/AUS-15/BOM/"
a=addfile(bdir+"CMCC-CMCC-ESM2/historical/r1i1p1f1/BOM-BARPA-R/v1/day/pr/pr_AUS-15_CMCC-CMCC-ESM2_historical_r1i1p1f1_BOM-BARPA-R_v1_day_201401-201412.nc","r")
lat=a->lat
lon=a->lon

models=(/"CMCC-CMCC-ESM2","CSIRO-ACCESS-ESM1-5","CSIRO-ARCCSS-ACCESS-CM2","EC-Earth-Consortium-EC-Earth3","NCAR-CESM2","NCC-NorESM2-MM"/)

member=(/"r1i1p1f1","r6i1p1f1","r4i1p1f1","r1i1p1f1","r11i1p1f1","r1i1p1f1"/)

pr=new((/dimsizes(models),dimsizes(years),dimsizes(lat),dimsizes(lon)/),"float")

do m=0,dimsizes(models)-1
print(models(m))
do y=0,dimsizes(years)-1
 print(years(y))
 if(years(y).le.2014) then
   ssp2="historical"
 else
   ssp2=ssp
 end if

 a=addfile(systemfunc("ls -1 " + bdir+models(m)+"/"+ssp2+"/"+member(m)+"/BOM-BARPA-R/v1/day/pr/pr_*_day_"+years(y)+"??-*.nc"),"r")

 tmp=a->pr
 tmp=tmp*60*60*24 ; Convert to daily

 b=dimsizes(tmp)
 tmp2=new((/b(0)+4,b(1),b(2)/),typeof(tmp))
 tmp2(4:(b(0)+3),:,:)=tmp
 delete([/tmp,a/])

 if(years(y).le.2015) then
   ssp2="historical"
 else
   ssp2=ssp
 end if

 a=addfile(systemfunc("ls -1 " + bdir+models(m)+"/"+ssp2+"/"+member(m)+"/BOM-BARPA-R/v1/day/pr/pr_*_day_"+(years(y)-1)+"??-*.nc"),"r")

 tmp=a->pr
 tmp=tmp*60*60*24 ; Convert to daily
 b=dimsizes(tmp)
 tmp2(0:3,:,:)=tmp((b(0)-4):(b(0)-1),:,:)
 tmp3=dim_acumrun_n(tmp2,5,0,0)
 pr(m,y,:,:)=dim_max_n(tmp3,0)
 delete([/tmp,a,tmp2,tmp3/])
end do
end do

  res                      = True               ; plot mods desired
  res@cnFillOn             = True               ; turn on color fill
  res@cnLevelSelectionMode = "ExplicitLevels"
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

wks_type = "pdf"
;wks_type@wkOrientation = "landscape"
wks_type@wkPaperWidthF = 4
wks_type@wkPaperHeightF = 4.6

; Get BARPA mask

;a=addfile("/g/data/py18/BARPA/output/CMIP6/DD/AUS-15/BOM/ERA5/evaluation/r1i1p1f1/BARPA-R/v1-r1/fx/sftlf/v20231001/sftlf_AUS-15_ERA5_evaluation_r1i1p1f1_BOM_BARPA-R_v1-r1_fx.nc","r")
a=addfile("/g/data/ia39/australian-climate-service/release/CORDEX-CMIP6/output/AUS-15/BOM/ECMWF-ERA5/evaluation/r1i1p1f1/BOM-BARPA-R/v1/fx/sftlf/sftlf_AUS-15_ECMWF-ERA5_evaluation_r1i1p1f1_BOM-BARPA-R_v1.nc","r")
land=a->sftlf
mval=where(land.lt.0.5,land@_FillValue,1)


ymin=(/1991,2011,2041/)
ymax=(/2020,2030,2060/)

do y=0,dimsizes(ymin)-1
 Y=ind(years.ge.ymin(y).and.years.le.ymax(y))
 pr2=dim_avg_n_Wrap(pr(:,Y,:,:),1)
 pr3=dim_avg_n_Wrap(pr2,0)
 pr3=where(land.lt.0.5,pr3@_FillValue,pr3)

 pr3!0="lat"
 pr3&lat=lat
 pr3!1="lon"
 pr3&lon=lon

  wks = gsn_open_wks(wks_type,"Rx5D_mean_"+ymin(y)+ymax(y)+"_BARPA6")             ; send graphics to PNG file

  gsn_define_colormap(wks,"precip_11lev")
;  gsn_reverse_colormap(wks)

   plot = gsn_csm_contour_map(wks,pr3, res)     ; create plot

draw(wks)
delete(wks)
delete([/Y,pr2,pr3/])
end do

Y1=ind(years.ge.1991.and.years.le.2020)
Y2=ind(years.ge.2041.and.years.le.2060)

pr2a=dim_avg_n_Wrap(pr(:,Y1,:,:),1)
pr2b=dim_avg_n_Wrap(pr(:,Y2,:,:),1)

pr3=dim_avg_n_Wrap(pr2b-pr2a,0)
pr3a=dim_avg_n_Wrap(where(pr2b.gt.pr2a,1,0),0)
 pr3=where(land.lt.0.5,pr3@_FillValue,pr3)
 pr3a=where(land.lt.0.5,pr3a@_FillValue,pr3a)

pr3!0="lat"
pr3&lat=lat
pr3!1="lon"
pr3&lon=lon

copy_VarMeta(pr3,pr3a)

delete(res@cnLevels)
  res@cnLevels = (/-50,-20,-10,-5,-2,-1,0,1,2,5,10,20,50/)

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
  opts_psl@cnLevels = (/0.2,0.8/)
  opts_psl@cnFillPatterns = (/6,-1,6/)
  opts_psl@cnLinesOn            = False
  opts_psl@lbLabelBarOn        = False
opts_psl@cnLineLabelsOn = False

  wks = gsn_open_wks(wks_type,"Rx5D_change_19912020_20412060_BARPA6")             ; send graphics to PNG file

  gsn_define_colormap(wks,"MPL_RdBu")
;  gsn_reverse_colormap(wks)

   plot = gsn_csm_contour_map(wks,pr3, res)     ; create plot

   contour_psl = gsn_csm_contour(wks,pr3a,opts_psl)
   overlay(plot, contour_psl)

draw(wks)
delete(wks)


I=ind(lat.ge.-45.and.lat.le.-10)
J=ind(lon.ge.110.and.lon.le.155)

print(dim_avg_n_Wrap(pr2b(:,I,J)-pr2a(:,I,J),(/1,2/)))
print(avg(pr3(I,J)))
print(avg(pr3a(I,J)))

 pr3=dim_avg_n_Wrap(pr2a,0)
 pr3=where(land.lt.0.5,pr3@_FillValue,pr3)

copy_VarMeta(pr3a,pr3)
delete(res@cnLevels)
  res@cnLevels = (/25,50,75,100,125,150,175,200,250,300,400/)

  wks = gsn_open_wks(wks_type,"Rx5D_change_20412060_BARPA6_changev19912020")             ; send graphics to PNG file
  gsn_define_colormap(wks,"precip_11lev")

   plot = gsn_csm_contour_map(wks,pr3, res)     ; create plot

  opts_psl@cnLevels = (/0.2,0.8/)
  opts_psl@cnFillPatterns = (/17,-1,6/)

   contour_psl = gsn_csm_contour(wks,pr3a,opts_psl)
   overlay(plot, contour_psl)

draw(wks)
delete(wks)

