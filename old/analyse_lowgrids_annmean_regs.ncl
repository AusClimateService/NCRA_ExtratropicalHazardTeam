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

a=addfile("/scratch/eg3/asp561/NCRA/BARPA/lows_BARPA_EC-Earth3_historical.nc","r")
lat=a->lat
lon=a->lon
tmp=a->low_freq(0,:,:)

 Opt                = True
 Opt@SrcRegional    = True             ; These are necessary
 Opt@DstRegional    = True
 Opt@SrcGridLat = mlat
 Opt@SrcGridLon = mlon
 Opt@DstGridLat = lat
 Opt@DstGridLon = lon
 Opt@ForceOverwrite = True
 Opt@InterpMethod="bilinear"

 tmp2=ESMF_regrid(mval,Opt)
 landmask=where(tmp2.ge.0.5,1,tmp2@_FillValue)
 copy_VarMeta(tmp,landmask)
 delete([/tmp,tmp2,mfile,mval,mlat,mlon/])

; Step two - list all the models and members

rcm=new(13,"string")
rcm(0:6)="BARPA"
rcm(7:12)="CCAM"

model=(/"CMCC-ESM2","ACCESS-ESM1-5","ACCESS-CM2","EC-Earth3","MPI-ESM1-2-HR","CESM2","NorESM2-MM","CMCC-ESM2","ACCESS-ESM1-5","ACCESS-CM2","CESM2","EC-Earth3","CNRM-ESM2-1"/)

; Step three - Get the NCRA regions
dir="/scratch/eg3/asp561/NCRA/"

regnames=(/"australia","aust_land","saust","saust_land","WA_North","WA_South","NSW","VIC","SA","TAS","NT","QLD_North","QLD_South"/)

regmask=new((/dimsizes(lat),dimsizes(lon),dimsizes(regnames)/),"float")
I=ind(lon.ge.110.and.lon.le.155)
J=ind(lat.ge.-45.and.lat.le.-10)
regmask(J,I,0)=1
regmask(:,:,1)=landmask
delete(J)
J=ind(lat.ge.-45.and.lat.le.-30)
regmask(J,I,2)=1
regmask(J,I,3)=landmask(J,I)
delete([/I,J/])

do i=4,dimsizes(regnames)-1
  a=addfile("/g/data/eg3/asp561/Shapefiles/NCRA/mask_NCRA_"+regnames(i)+"_1deg.nc","r")
  tmp=a->landmask
  regmask(:,:,i)=where(tmp.eq.1,1,regmask@_FillValue)
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

do m=0,dimsizes(model)-1
 print(model(m))
 a=addfiles(systemfunc("ls "+dir+rcm(m)+"/lows_"+rcm(m)+"_"+model(m)+"*.nc"),"r")
 time2=cd_calendar(a[:]->time,0)
 tmp=a[:]->low_freq

 do y=0,dimsizes(years)-1
  I=ind(time2(:,0).eq.years(y))
  if(.not.ismissing(I(0))) then
   do r=0,dimsizes(regnames)-1
    alldata(y,m,r)=avg(dim_avg_n(tmp(I,:,:),0)*regmask(:,:,r))
   end do 
  end if
  delete(I)
 end do
 delete([/a,time2,tmp/])
end do

   ofile=dir+"/annual_lowprop_BARPA_CCAM_NCRAregions.nc"
   a=addfile(ofile,"c")

     nl = integertochar(10)  ; newline character
;
; Define global attributes.
;
; globalAtt can be of any type. Here logical is used by convention.
;
  globalAtt             = True

  globalAtt@history     = systemfunc("date") + ": ncl < /home/561/asp561/Code/NCRA/analyse_grids_annmean_regs.ncl"

     globalAtt@sigma_level = "Regional average proportion of hours with a low within a 5 degree radius are calculated using the annual 1 degree resolution files from "+dir+" and averaged over Australia and Southern Australia as well as the 9 NCRA domains from masks in /g/data/eg3/asp561/Shapefiles/NCRA/"

  globalAtt@title       = "Annual mean low frequency in historical and ssp370 simulations"
  globalAtt@source      = "ACS regional model data in /g/data/py18 and /g/data/hq89"
  fileattdef( a, globalAtt )

 rcm2!0="model"
 regnames!0="region"
 a->pr=alldata
 a->model=rcm2
 a->region=regnames




