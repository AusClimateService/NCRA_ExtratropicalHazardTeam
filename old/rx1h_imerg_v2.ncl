load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

years=ispan(2016,2022,1)
adir="/g/data/ia39/aus-ref-clim-data-nci/gpm/data/V07/"
odir="/scratch/eg3/asp561/IMERG/"
a=addfile(adir+"2001/3B-HHR.MS.MRG.3IMERG.20010101.V07A.nc","r")
lat=a->lat
lon=a->lon
I=ind(lon.ge.110.and.lon.le.155)
J=ind(lat.ge.-45.and.lat.le.-5)
K=ispan(0,47,2)
lat2=lat(J)
lon2=lon(I)

do y=0,dimsizes(years)-1
 print(years(y))
 tmp=systemfunc("ls "+adir+years(y)+"/*.nc")
 len=dimsizes(tmp)
 daily=new((/len,dimsizes(I),dimsizes(J)/),"float")

 do i=0,len-1
;   print(i)
   a=addfile(tmp(i),"r")
   pr2=a->precipitation
   b=dimsizes(pr2)
   K2=K(ind(K.lt.b(0)))
   if(dimsizes(K2).gt.1) then
     daily(i,:,:)=dim_max_n_Wrap(pr2(K2,I,J),0)
   else
     daily(i,:,:)=pr2(K2,I,J)
   end if
   delete([/pr2,a,b,K2/])
 end do

 pr=dim_max_n(daily,0)
 pr!1="lat"
 pr!0="lon"
 pr&lon=lon2
 pr&lat=lat2
 pr2=pr(lat|:,lon|:)

 ofile=addfile(odir+"IMERG_aust_rx1h_"+years(y)+".nc","c")
 ofile->pr=pr2

 delete([/tmp,len,daily,pr,pr2,ofile/])
end do


