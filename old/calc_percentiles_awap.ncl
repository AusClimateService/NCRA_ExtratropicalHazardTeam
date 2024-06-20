load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

;bdir="/g/data/py18/BARPA/output/CMIP6/DD/AUS-15/BOM/NorESM2-MM/historical/r1i1p1f1/BARPA-R/v1-r1/"
adir="/g/data/zv2/agcd/v1-0-1/precip/total/r005/01day/"
years=ispan(1981,2010,1)

quantiles=(/95,99,99.7/)
wthresh=1.

ofile="/scratch/eg3/asp561/agcd/awap_percentiles.nc"

ifiles=new(dimsizes(years),"string")
do y=0,dimsizes(years)-1
 ifiles(y)=adir+"agcd_v1-0-1_precip_total_r005_daily_"+years(y)+".nc"
end do

a=addfiles(ifiles,"r")
lat=a[0]->lat
lon=a[0]->lon
tmp=a[:]->precip
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
  I=ind(.not.ismissing(tmp(:,jlat,ilon)))
  if(dimsizes(I).ge.200) then
    sorted=tmp(I,jlat,ilon)
    qsort(sorted)
    do p=0,dimsizes(quantiles)-1
      percentiles_all(p,jlat,ilon)=(/sorted(round(quantiles(p)*dimsizes(sorted)/100,3))/)
    end do
    delete(sorted)
  end if
  delete(I)

  I=ind(tmp(:,jlat,ilon).ge.wthresh)
  if(dimsizes(I).ge.200) then
    sorted=tmp(I,jlat,ilon)
    qsort(sorted)
    do p=0,dimsizes(quantiles)-2
      percentiles_wetday(p,jlat,ilon)=(/sorted(round(quantiles(p)*dimsizes(sorted)/100,3))/)
    end do
    delete(sorted)
  end if
  delete(I)
end do
end do

ncdf=addfile(ofile,"c")
fAtt               = True            ; assign file attributes
fAtt@title         = "Percentiles from AWAP version 1"
fAtt@source        = adir
fAtt@software      = "calc_percentiles_awap.ncl"
fAtt@author        = "Acacia Pepler <acacia.pepler@bom.gov.au>"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

ncdf->percentiles_all=percentiles_all
ncdf->percentiles_wetday=percentiles_wetday

