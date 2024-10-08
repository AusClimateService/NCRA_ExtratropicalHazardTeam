load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

;bdir="/g/data/py18/BARPA/output/CMIP6/DD/AUS-15/BOM/NorESM2-MM/historical/r1i1p1f1/BARPA-R/v1-r1/"
adir="/g/data/ob53/BARRA2/output/reanalysis/AUS-11/BOM/ERA5/historical/hres/BARRA-R2/v1/day/pr/v20231001/"
years=ispan(1981,2010,1)

quantiles=(/95,99,99.7/)
wthresh=1.

ofile="/scratch/eg3/asp561/BARRA2/barra_percentiles.nc"

ifiles=new(12*dimsizes(years),"string")
do y=0,dimsizes(years)-1
 ifiles(y*12:(y*12+11))=systemfunc("ls "+adir+"pr_AUS-11_ERA5_historical_hres_BOM_BARRA-R2_v1_day_"+years(y)+"*.nc")
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
fAtt@title         = "Percentiles from BARRA-R2"
fAtt@source        = adir
fAtt@software      = "calc_percentiles_barra.ncl"
fAtt@author        = "Acacia Pepler <acacia.pepler@bom.gov.au>"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

ncdf->percentiles_all=percentiles_all
ncdf->percentiles_wetday=percentiles_wetday

