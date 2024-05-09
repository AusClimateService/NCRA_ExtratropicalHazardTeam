load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

adir="/g/data/py18/BARPA/output/CMIP6/DD/AUS-15/BOM/"

years=ispan(1981,2010,1)

quantiles=(/95,99,99.7/)
wthresh=1.

ssp="evaluation"
models=(/"ERA5"/)
member=(/"r1i1p1f1"/)

;ssp="historical"
;models=(/"CMCC-ESM2","ACCESS-ESM1-5","ACCESS-CM2","EC-Earth3","CESM2","NorESM2-MM","MPI-ESM1-2-HR"/)
;member=(/"r1i1p1f1","r6i1p1f1","r4i1p1f1","r1i1p1f1","r11i1p1f1","r1i1p1f1","r11i1p1f1"/)

do i=0,dimsizes(models)-1
print(models(i))

ofile="/scratch/eg3/asp561/BARPA/BARPA-R_"+models(i)+"_percentiles.nc"
dir2=adir+models(i)+"/"+ssp+"/"+member(i)+"/BARPA-R/v1-r1/day/pr/v20231001/"

ifiles=new(dimsizes(years),"string")
do y=0,dimsizes(years)-1
 ifiles(y)=systemfunc("ls "+dir2+"pr_AUS-15_*"+years(y)+"12.nc")
end do

a=addfiles(ifiles,"r")
lat=a[0]->lat
lon=a[0]->lon
tmp=a[:]->pr
delete(a)

percentiles_all=new((/dimsizes(quantiles),dimsizes(lat),dimsizes(lon)/),"float")
percentiles_all!0="quantile"
percentiles_all&quantile=quantiles
percentiles_all!1="lat"
percentiles_all&lat=lat
percentiles_all!2="lon"
percentiles_all&lon=lon
percentiles_all@units="mm"
percentiles_all@standard_name="percentiles"
percentiles_all@long_name="Percentile values calculated using all data from 1981-2010" 

; Don't want 99.7th percentile for wet days, just the other two
percentiles_wetday=percentiles_all(0:1,:,:)
percentiles_wetday@long_name="Percentile values calculated using only wet days (>="+wthresh+"mm from 1981-2010"
percentiles_wetday!0="quantile2"

a=dimsizes(tmp)-1

do jlat=0,a(1)
do ilon=0,a(2)
 tmp2=tofloat((tmp(:,jlat,ilon)*tmp@scale_factor)*60*60*24)
  I=ind(.not.ismissing(tmp2))
  if(dimsizes(I).ge.200) then
    sorted=tmp2(I)
    qsort(sorted)
    do p=0,dimsizes(quantiles)-1
      percentiles_all(p,jlat,ilon)=(/sorted(round(quantiles(p)*dimsizes(sorted)/100,3))/)
    end do
    delete(sorted)
  end if
  delete(I)

  I=ind(tmp2.ge.wthresh)
  if(dimsizes(I).ge.200) then
    sorted=tmp2(I)
    qsort(sorted)
    do p=0,dimsizes(quantiles)-2
      percentiles_wetday(p,jlat,ilon)=(/sorted(round(quantiles(p)*dimsizes(sorted)/100,3))/)
    end do
    delete(sorted)
  end if
  delete(I)
  delete(tmp2)
end do
end do

ncdf=addfile(ofile,"c")
fAtt               = True            ; assign file attributes
fAtt@title         = "Percentiles from BARPA-R "+models(i)
fAtt@source        = adir
fAtt@software      = "calc_percentiles_barra.ncl"
fAtt@author        = "Acacia Pepler <acacia.pepler@bom.gov.au>"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

ncdf->percentiles_all=percentiles_all
ncdf->percentiles_wetday=percentiles_wetday

delete([/tmp,percentiles_all,percentiles_wetday,ncdf,dir2,ofile,ifiles,a/])

end do

