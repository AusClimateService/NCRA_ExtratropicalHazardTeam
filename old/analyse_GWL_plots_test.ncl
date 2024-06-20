load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

; First, lets get the masks and grids

mfile=addfile("/g/data/eg3/asp561/Shapefiles/mask_australia_0.05deg.nc","r")
mval=mfile->landmask
mval=where(mval.eq.0,mval@_FillValue,mval)
mlat=mfile->latitude
mlon=mfile->longitude

a=addfile("/g/data/py18/BARPA/output/CMIP6/DD/AUS-15/BOM/ERA5/evaluation/r1i1p1f1/BARPA-R/v1-r1/fx/sftlf/v20231001/sftlf_AUS-15_ERA5_evaluation_r1i1p1f1_BOM_BARPA-R_v1-r1_fx.nc","r")
bval=a->sftlf
blat=a->lat
blon=a->lon

a=addfile("/g/data/hq89/CCAM/output/CMIP6/DD/AUS-10i/CSIRO/ERA5/evaluation/r1i1p1f1/CCAM-v2203-SN/v1-r1/fx/sftlf/v20231206/sftlf_AUS-10i_ERA5_evaluation_r1i1p1f1_CSIRO_CCAM-v2203-SN_v1-r1.nc","r")
cval=a->sftlf
clat=a->lat
clon=a->lon
delete(a)

; Step two - list all the models and members

rcm=new(13,"string")
rcm(0:6)="BARPA"
rcm(7:12)="CCAM"

model=(/"CMCC-ESM2","ACCESS-ESM1-5","ACCESS-CM2","EC-Earth3","MPI-ESM1-2-HR","CESM2","NorESM2-MM","CMCC-ESM2","ACCESS-ESM1-5","ACCESS-CM2","CESM2","EC-Earth3","CNRM-ESM2-1"/)

; Step three - Get the years for each GWL
dir="/scratch/eg3/asp561/NCRA/"

filename=dir+"ACS_GWLs.csv"
  read_data= asciiread(filename,-1,"string")
  header    = read_data(0)        ; Header. Use for variable names.
  data      = read_data(1:)       ; Get rid of first line which is a header.
  delim=","

mname=str_get_field(data,1,delim)

GWlist=(/"historical","current","GWL1","GWL1.5","GWL2","GWL3"/)

GWL=new((/dimsizes(mname),dimsizes(GWlist),2/),"integer")
GWL(:,0,0)=1991
GWL(:,0,1)=2020
GWL(:,1,0)=2011
GWL(:,1,1)=2030

do i=0,3
 GWL(:,i+2,0)=tointeger(str_get_field(data,i*2+4,delim))
 GWL(:,i+2,1)=tointeger(str_get_field(data,i*2+5,delim))
end do

; Step four
; For each model, load all years for hist + ssp370
; Calculate means for the 6 periods
; Convert those means onto the AWAP grid
; Save a grid of 691x886x13 membersx6 periods
; Ready to make plots

alldata=new((/dimsizes(mlat),dimsizes(mlon),dimsizes(rcm),dimsizes(GWlist)/),"float")
alldata!0="lat"
alldata&lat=mlat
alldata!1="lon"
alldata&lon=mlon

 Opt                = True
 Opt@SrcRegional    = True             ; These are necessary
 Opt@DstRegional    = True
 Opt@DstGridLat = mlat
 Opt@DstGridLon = mlon
 Opt@ForceOverwrite = True
 Opt@InterpMethod="bilinear"

do m=0,dimsizes(model)-1
 print(model(m))
 a=addfiles(systemfunc("ls "+dir+rcm(m)+"/RX5D_"+rcm(m)+"_"+model(m)+"*.nc"),"r")
 time=cd_calendar(a[:]->time,0)
 tmp=a[:]->pr
 MM=ind(mname.eq.model(m))

 if(rcm(m).eq."CCAM") then
  Opt@SrcGridLat = clat
  Opt@SrcGridLon = clon
 else
  Opt@SrcGridLat = blat
  Opt@SrcGridLon = blon
 end if

 do y=0,dimsizes(GWlist)-1
  I=ind(time(:,0).ge.GWL(MM,y,0).and.time(:,0).le.GWL(MM,y,1))
  tmp2=dim_avg_n_Wrap(tmp(I,:,:),0)
  alldata(:,:,m,y)=ESMF_regrid(tmp2,Opt)
  delete([/I,tmp2/])
 end do
 delete([/a,time,tmp,MM,Opt@SrcGridLat,Opt@SrcGridLon/])
end do

  res                      = True               ; plot mods desired
  res@cnFillOn             = True               ; turn on color fill
  res@cnLevelSelectionMode = "ExplicitLevels"
;  res@cnLevels             = (/8.,10.,12.,14.,16.,18.,20.,25.,30.,35.,40./); ispan(20,120,10)
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

  wks = gsn_open_wks(wks_type,dir+"RX5D_13ACSRCMs_GWLpanel")             ; send graphics to PNG file

  gsn_define_colormap(wks,"precip_11lev")

 plots=new(6,graphic)

 do p=0,dimsizes(GWlist)-1
 res@gsnLeftString=GWlist(p)

  tmp1=where(mval.eq.1,dim_avg_n_Wrap(alldata(:,:,:,p),2),alldata@_FillValue)
  copy_VarMeta(mval,tmp1)

   plots(p) = gsn_csm_contour_map(wks,tmp1, res)     ; create plot
 end do


  resP                  = True                   ; modify the panel plot
  resP@gsnMaximize      = True                   ; use full page
resP@gsnPaperOrientation = "portrait"
  resP@lbTitleFontHeightF=0.012
  resP@lbTitleString="Wettest day per year (RX1D), mm"
  resP@lbTitleOn        =  True                ; turn on title
  resP@lbTitlePosition  = "Bottom"              ; title position
  resP@lbTitleDirection = "Across"             ; title direction
  resP@pmLabelBarOrthogonalPosF = -0.02
  resP@gsnPanelLabelBar    = True
  resP@lbLabelFontHeightF =.01
 resP@gsnPanelYWhiteSpacePercent = 5
  gsn_panel(wks,plots,(/2,3/),resP)
delete(wks)


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



wks_type = "pdf"
;wks_type@wkOrientation = "landscape"
wks_type@wkPaperWidthF = 10
wks_type@wkPaperHeightF = 4

  wks = gsn_open_wks(wks_type,dir+"RX5D_13ACSRCMs_GWLchange_vsGWL1")             ; send graphics to PNG file

  gsn_define_colormap(wks,"MPL_RdBu")

;  gsn_define_colormap(wks,"precip_11lev")

delete(res@cnLevels)
  res@cnLevels = (/-50,-20,-10,-5,-2,-1,0,1,2,5,10,20,50/)
; res@cnLevels = ispan(-6,6,1)
;   res@cnLevels=(/-28,-21,-14,-7,-5,-3,0,3,5,7,14,21,28/)
; res@cnLevels             = (/8.,10.,12.,14.,16.,18.,20.,25.,30.,35.,40./)

 delete(plots)
 plots=new(3,graphic)
 cont=plots

 do p=0,2
 res@gsnLeftString=GWlist(p+3)

  tmp1=where(mval.eq.1,dim_avg_n_Wrap(alldata(:,:,:,p+3)-alldata(:,:,:,2),2),alldata@_FillValue)
  ;tmp1=dim_avg_n_Wrap(alldata(:,:,:,p+3)/alldata(:,:,:,2),2)
  ;tmp1=where(mval.eq.1,100*(tmp1-1),alldata@_FillValue)
  copy_VarMeta(mval,tmp1)

   tmp2=dim_avg_n_Wrap(where(alldata(:,:,:,p+3).gt.alldata(:,:,:,2),1,0),2)
   tmp2=where(mval.eq.1,tmp2,alldata@_FillValue)
   copy_VarMeta(mval,tmp2)

   plots(p) = gsn_csm_contour_map(wks,tmp1, res)     ; create plot
   cont(p) = gsn_csm_contour(wks,tmp2,opts_psl)
   overlay(plots(p), cont(p))

 end do

 delete(resP)
  resP                  = True                   ; modify the panel plot
  resP@gsnMaximize      = True                   ; use full page
resP@gsnPaperOrientation = "portrait"
  resP@lbTitleFontHeightF=0.012
  resP@lbTitleString="Change in (RX5D) relative to GWL1, mm"
  resP@lbTitleOn        =  True                ; turn on title
  resP@lbTitlePosition  = "Bottom"              ; title position
  resP@lbTitleDirection = "Across"             ; title direction
  resP@pmLabelBarOrthogonalPosF = -0.02
  resP@gsnPanelLabelBar    = True
  resP@lbLabelFontHeightF =.01
 resP@gsnPanelYWhiteSpacePercent = 5
  gsn_panel(wks,plots,(/1,3/),resP)
delete(wks)






