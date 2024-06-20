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

; Step three - Get the NCRA regions
dir="/scratch/eg3/asp561/NCRA/"

regnames=(/"australia","WA_North","WA_South","NSW","VIC","SA","TAS","NT","QLD_North","QLD_South"/)

regmask=new((/dimsizes(mlat),dimsizes(mlon),dimsizes(regnames)/),"float")
regmask(:,:,0)=mval

do i=1,dimsizes(regnames)-1
  a=addfile("/g/data/eg3/asp561/Shapefiles/NCRA/mask_NCRA_"+regnames(i)+"_0.05deg.nc","r")
  tmp=a->landmask
  regmask(:,:,i)=where(tmp.eq.1,mval,mval@_FillValue)
end do
delete([/a,tmp/])

years=ispan(1960,2099,1)
ntim=dimsizes(years)
  tunits     = "hours since 1900-01-01 00:00:00" 
time       = cd_inv_calendar(years,conform_dims(ntim, 1, -1),conform_dims(ntim, 1, -1)  ,conform_dims(ntim, 0, -1),conform_dims(ntim, 0, -1),conform_dims(ntim, 0, -1), tunits, 0)
time!0     = "time"

alldata=new((/dimsizes(years),dimsizes(rcm),dimsizes(regnames)/),"float")
alldata!0="time"
alldata&time=time
alldata!1="member"
alldata!2="region"

regnames!0="region"
rcm2=rcm+"-"+model
rcm2!0="member"

 Opt                = True
 Opt@SrcRegional    = True             ; These are necessary
 Opt@DstRegional    = True
 Opt@DstGridLat = mlat
 Opt@DstGridLon = mlon
 Opt@ForceOverwrite = True
 Opt@InterpMethod="bilinear"

do m=0,dimsizes(model)-1
 print(model(m))
 a=addfiles(systemfunc("ls "+dir+rcm(m)+"/RX1H_"+rcm(m)+"_"+model(m)+"*.nc"),"r")
 time2=cd_calendar(a[:]->time,0)
 tmp=a[:]->prhmax

 if(rcm(m).eq."CCAM") then
  Opt@SrcGridLat = clat
  Opt@SrcGridLon = clon
 else
  Opt@SrcGridLat = blat
  Opt@SrcGridLon = blon
 end if

 do y=0,dimsizes(years)-1
  I=ind(time2(:,0).eq.years(y))
  if(.not.ismissing(I)) then
   tmp2=ESMF_regrid(tmp(y,:,:),Opt)
   do r=0,dimsizes(regnames)-1
    alldata(y,m,r)=avg(tmp2*regmask(:,:,r))
   end do 
   delete(tmp2)
  end if
  delete(I)
 end do
 delete([/a,time2,tmp,Opt@SrcGridLat,Opt@SrcGridLon/])
end do



   ofile=dir+"/annual_RX1H_BARPA_CCAM_NCRAregions.nc"
   a=addfile(ofile,"c")

     nl = integertochar(10)  ; newline character
;
; Define global attributes.
;
; globalAtt can be of any type. Here logical is used by convention.
;
  globalAtt             = True

  globalAtt@history     = systemfunc("date") + ": ncl < /home/561/asp561/Code/NCRA/analyse_grids_annmean_regs.ncl"

     globalAtt@sigma_level = "Regional average RX1H are calculated using the annual files from "+dir+", bilinearly regridded to the AGCD 0.05 degree grid using the ESMF_regrid functionality in NCL, and averaged over Auystralia as well as the 9 NCRA domains from masks in /g/data/eg3/asp561/Shapefiles/NCRA/"

  globalAtt@title       = "Annual mean RX1H in historical and ssp370 simulations"
  globalAtt@source      = "ACS regional model data in /g/data/py18 and /g/data/hq89"
  fileattdef( a, globalAtt )

 rcm2!0="model"
 region!0="region"
 a->pr=alldata
 a->model=rcm2
 a->region=regnames




