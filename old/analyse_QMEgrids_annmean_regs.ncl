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

; Step two - list all the models and members

rcm=new(28,"string")
rcm(0:6)="BARPA"
rcm(7:12)="CCAM"
rcm(13:27)="CCAM-UQ-DES"

model=(/"CMCC-ESM2","ACCESS-ESM1-5","ACCESS-CM2","EC-Earth3","MPI-ESM1-2-HR","CESM2","NorESM2-MM","CMCC-ESM2","ACCESS-ESM1-5","ACCESS-CM2","CESM2","EC-Earth3","CNRM-ESM2-1","ACCESS-CM2","ACCESS-ESM1-5","ACCESS-ESM1-5","ACCESS-ESM1-5","CMCC-ESM2","CNRM-CM6-1-HR","CNRM-CM6-1-HR","EC-Earth3","FGOALS-g3","GFDL-ESM4","GISS-E2-1-G","MPI-ESM1-2-LR","MRI-ESM2-0","NorESM2-MM","NorESM2-MM"/)

; Only relevant for queensland
member=(/"","","","","","","","","","","","","","_r2i1p1f1_CCAMoc-v2112","_r20i1p1f1_CCAMoc-v2112","_r40i1p1f1_CCAMoc-v2112","_r6i1p1f1_CCAM-v2105","_r1i1p1f1_CCAM-v2105","_r1i1p1f2_CCAMoc-v2112","_r1i1p1f2_CCAM-v2112","_r1i1p1f1_CCAM-v2105","_r4i1p1f1_CCAM-v2105","_r1i1p1f1_CCAM-v2105","_r2i1p1f2_CCAM-v2105","_r9i1p1f1_CCAM-v2105","_r1i1p1f1_CCAM-v2105","_r1i1p1f1_CCAMoc-v2112","_r1i1p1f1_CCAM-v2112"/)

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
rcm2=rcm+"-"+model+member
rcm2!0="member"

do m=0,dimsizes(model)-1
 print(model(m))
 a=addfiles(systemfunc("ls "+dir+rcm(m)+"/QME/RX1D_"+rcm(m)+"-QME-AGCD_"+model(m)+member(m)+"*.nc"),"r")
 time2=cd_calendar(a[:]->time,0)
 tmp=tofloat(a[:]->prAdjust)

 do y=0,dimsizes(years)-1
  I=ind(time2(:,0).eq.years(y))
  if(.not.ismissing(I)) then
   do r=0,dimsizes(regnames)-1
    alldata(y,m,r)=avg(tmp(I,:,:)*regmask(:,:,r))
   end do 
  end if
  delete(I)
 end do
 delete([/a,time2,tmp/])
end do

   ofile=dir+"/annual_RX1D_BARPA_CCAM_QLD_QME_NCRAregions.nc"
   a=addfile(ofile,"c")

     nl = integertochar(10)  ; newline character
;
; Define global attributes.
;
; globalAtt can be of any type. Here logical is used by convention.
;
  globalAtt             = True

  globalAtt@history     = systemfunc("date") + ": ncl < /home/561/asp561/Code/NCRA/analyse_grids_annmean_regs.ncl"

     globalAtt@sigma_level = "Regional average RX1D are calculated using the annual files from "+dir+", which were bias corrected on the AGCD grid using QME, and averaged over Australia as well as the 9 NCRA domains from masks in /g/data/eg3/asp561/Shapefiles/NCRA/"

  globalAtt@title       = "Annual mean QME-adjusted RX1D in historical and ssp370 simulations"
  globalAtt@source      = "ACS regional bias corrected data in /g/data/ia39/australian-climate-service/test-data/CORDEX-CMIP6/bias-adjustment-output/AGCD-05i/"
  fileattdef( a, globalAtt )

 rcm2!0="model"
 regnames!0="region"
 a->pr=alldata
 a->model=rcm2
 a->region=regnames


