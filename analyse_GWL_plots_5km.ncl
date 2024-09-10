load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

varname="RX1D"
var2="pr"

; First, lets get the masks and grids
; Only if regridding to 5km
mfile=addfile("/g/data/eg3/asp561/Shapefiles/mask_australia_0.05deg.nc","r")
mval=mfile->landmask
mval=where(mval.eq.0,mval@_FillValue,mval)
mlat=mfile->latitude
mlon=mfile->longitude

; Step two - list all the models and members

agency=(/"BOM","BOM","BOM","BOM","BOM","BOM","BOM","CSIRO","CSIRO","CSIRO","CSIRO","CSIRO","CSIRO","UQ-DES","UQ-DES","UQ-DES","UQ-DES","UQ-DES","UQ-DES","UQ-DES","UQ-DES","UQ-DES","UQ-DES","UQ-DES","UQ-DES","UQ-DES","UQ-DES","UQ-DES"/)

model=(/"ACCESS-CM2","ACCESS-ESM1-5","CESM2","CMCC-ESM2","EC-Earth3","MPI-ESM1-2-HR","NorESM2-MM","ACCESS-CM2","ACCESS-ESM1-5","CESM2","CMCC-ESM2","CNRM-ESM2-1","EC-Earth3","ACCESS-CM2","ACCESS-ESM1-5","ACCESS-ESM1-5","ACCESS-ESM1-5","CMCC-ESM2","CNRM-CM6-1-HR","CNRM-CM6-1-HR","EC-Earth3","FGOALS-g3","GFDL-ESM4","GISS-E2-1-G","MPI-ESM1-2-LR","MRI-ESM2-0","NorESM2-MM","NorESM2-MM"/)

member=(/"r4i1p1f1","r6i1p1f1","r11i1p1f1","r1i1p1f1","r1i1p1f1","r1i1p1f1","r1i1p1f1","r4i1p1f1","r6i1p1f1","r11i1p1f1","r1i1p1f1","r1i1p1f2","r1i1p1f1","r2i1p1f1","r20i1p1f1","r40i1p1f1","r6i1p1f1","r1i1p1f1","r1i1p1f2","r1i1p1f2","r1i1p1f1","r4i1p1f1","r1i1p1f1","r2i1p1f2","r9i1p1f1","r1i1p1f1","r1i1p1f1","r1i1p1f1"/)

rcm=(/"BARPA-R","BARPA-R","BARPA-R","BARPA-R","BARPA-R","BARPA-R","BARPA-R","CCAM-v2203-SN","CCAM-v2203-SN","CCAM-v2203-SN","CCAM-v2203-SN","CCAM-v2203-SN","CCAM-v2203-SN","CCAMoc-v2112","CCAMoc-v2112","CCAMoc-v2112","CCAM-v2105","CCAM-v2105","CCAMoc-v2112","CCAM-v2112","CCAM-v2105","CCAM-v2105","CCAM-v2105","CCAM-v2105","CCAM-v2105","CCAM-v2105","CCAMoc-v2112","CCAM-v2112"/)


dir="/scratch/eg3/asp561/NCRA/5km/"
GWlist=(/1.2,1.5,2,3/)
ssp="ssp370"

; Set up matrix - currently using just 13 ACS models not all RCMs
alldata=new((/dimsizes(mlat),dimsizes(mlon),13,dimsizes(GWlist)/),"float")
alldata!0="lat"
alldata&lat=mlat
alldata!1="lon"
alldata&lon=mlon

; Step three - Get the years for each GWL

filename="/scratch/eg3/asp561/NCRA//cmip6_warming_levels_all_ens_1850_1900_grid.csv"
  read_data= asciiread(filename,-1,"string")
  header    = read_data(4)        ; Header. Use for variable names.
  data      = read_data(5:)       ; Get rid of first line which is a header.
  delim=", "

mname=str_get_field(data,1,delim)
mmember=str_get_field(data,2,delim)
mssp=str_get_field(data,3,delim)
mgwl=tofloat(str_get_field(data,5,delim))

do m=0,12

; Get years

 print(model(m))
 a=addfiles(systemfunc("ls "+dir+"/"+varname+"_AGCD-05i_"+model(m)+"_*_"+member(m)+"_"+agency(m)+"_"+rcm(m)+"_v1-r1_annual.nc"),"r")

 time=cd_calendar(a[:]->time,0)
 tmp=tofloat(a[:]->$var2$)
 ;tmp=a->low_freq

do y=0,dimsizes(GWlist)-1
 I=ind(mname.eq.model(m).and.mmember.eq.member(m).and.mssp.eq.ssp.and.mgwl.eq.GWlist(y))
 syear=tointeger(str_get_field(data(I),6,delim))
 eyear=tointeger(str_get_field(data(I),7,delim))

 J=ind(time(:,0).ge.syear.and.time(:,0).le.eyear)
 alldata(:,:,m,y)=dim_avg_n_Wrap(tmp(J,:,:),0)
 delete([/I,J/])
 end do
 delete([/a,time,tmp/])
end do

; Next step: calculate the 10, 50 and 90 percentiles for each GWL

pctiles=(/50,10,90/)

; Set up matrix - currently using just 13 ACS models not all RCMs
summarydata=new((/dimsizes(mlat),dimsizes(mlon),dimsizes(pctiles),dimsizes(GWlist)/),"float")
summarydata!0="lat"
summarydata&lat=mlat
summarydata!1="lon"
summarydata&lon=mlon

summarydata(:,:,0,:)=dim_median_n(alldata,2)

do i=0,dimsizes(mlat)-1
 do j=0,dimsizes(mlon)-1
  do y=0,dimsizes(GWlist)-1
   tmp=alldata(i,j,:,y)
   qsort(tmp)

   do p=1,dimsizes(pctiles)-1
    summarydata(i,j,p,y)=(/tmp(round(pctiles(p)*dimsizes(tmp)/100,3))/)
   end do
  end do
 end do
end do 

changedata=alldata(:,:,:,1:3)
do i=0,2
  changedata(:,:,:,i)=100*((changedata(:,:,:,i)/alldata(:,:,:,0))-1)
end do

; Set up matrix - currently using just 13 ACS models not all RCMs
summarychange=new((/dimsizes(mlat),dimsizes(mlon),dimsizes(pctiles),dimsizes(GWlist)-1/),"float")
summarychange!0="lat"
summarychange&lat=mlat
summarychange!1="lon"
summarychange&lon=mlon

summarychange(:,:,0,:)=dim_median_n(changedata,2)

do i=0,dimsizes(mlat)-1
 do j=0,dimsizes(mlon)-1
  do y=0,dimsizes(GWlist)-2
   tmp=changedata(i,j,:,y)
   qsort(tmp)

   do p=1,dimsizes(pctiles)-1
    summarychange(i,j,p,y)=(/tmp(round(pctiles(p)*dimsizes(tmp)/100,3))/)
   end do
  end do
 end do
end do

summarychange_v2=new((/dimsizes(mlat),dimsizes(mlon),dimsizes(pctiles),dimsizes(GWlist)-1/),"float")
summarychange_v2!0="lat"
summarychange_v2&lat=mlat
summarychange_v2!1="lon"
summarychange_v2&lon=mlon

do y=0,dimsizes(GWlist)-2
 summarychange_v2(:,:,:,y)=100*((summarydata(:,:,:,y+1)/summarydata(:,:,:,0))-1)
end do

  res                      = True               ; plot mods desired
  res@cnFillOn             = True               ; turn on color fill
  res@cnLevelSelectionMode = "ExplicitLevels"
  res@cnLevels =(/0.2,0.4,0.6,0.8,1,1.2,1.4,1.6,1.8,2,2.5,3/)
 ; res@cnLevels             = (/20,30,40,50,60,70,80,100,120,140,160/); ispan(20,120,10)
; res@cnLevels             = (/8.,10.,12.,14.,16.,18.,20.,25.,30.,35.,40./)
;  res@cnLevels = (/25,50,75,100,150,200,300,400,500,600,800/)

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
  res@mpGridLineDashPattern = 2
  res@mpGridLineThicknessF = 0.5
  res@mpProjection = "CylindricalEquidistant"
  res@gsnLeftString=""
  res@gsnRightString=""
;  res@cnFillMode = "RasterFill"
  res@cnLinesOn = False
  res@lbLabelBarOn        = False
  res@lbOrientation               = "Vertical"
  res@cnLineLabelsOn = False
  res@gsnMaximize      = True                   ; use full page
  res@gsnPaperOrientation = "portrait"


wks_type = "pdf"
;wks_type@wkOrientation = "landscape"
wks_type@wkPaperWidthF = 10
wks_type@wkPaperHeightF = 8

 wks = gsn_open_wks(wks_type,dir+"lows_39CORDEXRCMs_GWLpanel_range_masked")             ; send graphics to PNG file

 gsn_define_colormap(wks,"precip_11lev")

 plots=new(12,graphic)

 do p=0,2
  do y=0,3
   res@gsnLeftString="GWL"+GWlist(y)+": "+pctiles(p)+"th percentile"
   tmp1=100*summarydata(:,:,p,y)*mval ; lows as %
   ;tmp1=summarydata(:,:,p,y)*mval
   copy_VarMeta(summarydata(:,:,p,y),tmp1)
   plots(p*4+y) = gsn_csm_contour_map(wks,tmp1, res)
   delete(tmp1)
  end do
 end do

  resP                  = True                   ; modify the panel plot
  resP@gsnMaximize      = True                   ; use full page
resP@gsnPaperOrientation = "portrait"
  resP@lbTitleFontHeightF=0.012
;  resP@lbTitleString="RX1H (mm)"
  resP@lbTitleString="% of time influenced by a low"
  resP@lbTitleOn        =  True                ; turn on title
  resP@lbTitlePosition  = "Bottom"              ; title position
  resP@lbTitleDirection = "Across"             ; title direction
  resP@pmLabelBarOrthogonalPosF = -0.02
  resP@gsnPanelLabelBar    = True
  resP@lbLabelFontHeightF =.01
 resP@gsnPanelYWhiteSpacePercent = 5
  gsn_panel(wks,plots,(/3,4/),resP)
delete(wks)


wks_type = "pdf"
;wks_type@wkOrientation = "landscape"
wks_type@wkPaperWidthF = 8
wks_type@wkPaperHeightF = 8

  wks = gsn_open_wks(wks_type,dir+"lows_39CORDEXRCMs_GWLpanel_PCchangevsGWL1.2_range_masked")             ; send graphics to PNG file

  gsn_define_colormap(wks,"MPL_RdBu")
 delete(res@cnLevels)
  res@cnLevels = (/-40,-30,-25,-20,-15,-10,-5,0,5,10,15,20,25,30,40/)

 delete(plots)
 plots=new(9,graphic)

 do p=0,2
  do y=0,2
   res@gsnLeftString="Change at GWL"+GWlist(y+1)+": "+pctiles(p)+"th percentile"
   tmp1=summarychange(:,:,p,y)*mval
   copy_VarMeta(summarydata(:,:,p,y),tmp1)

   plots(p*3+y) = gsn_csm_contour_map(wks,tmp1, res)     ; create plot
  end do
 end do

 delete(resP)
  resP                  = True                   ; modify the panel plot
  resP@gsnMaximize      = True                   ; use full page
resP@gsnPaperOrientation = "portrait"
  resP@lbTitleFontHeightF=0.012
  resP@lbTitleString="% change in low frequency relative to GWL1.2"
;   resP@lbTitleString="% change in RX1H to GWL1.2"
  resP@lbTitleOn        =  True                ; turn on title
  resP@lbTitlePosition  = "Bottom"              ; title position
  resP@lbTitleDirection = "Across"             ; title direction
  resP@pmLabelBarOrthogonalPosF = -0.02
  resP@gsnPanelLabelBar    = True
  resP@lbLabelFontHeightF =.01
 resP@gsnPanelYWhiteSpacePercent = 5
  gsn_panel(wks,plots,(/3,3/),resP)
delete(wks)






