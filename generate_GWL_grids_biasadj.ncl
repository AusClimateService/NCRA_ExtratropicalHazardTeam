load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

var="RX5D"
varname="prAdjust"
long_name="Highest annual 60-minute rainfall total"
mult=1 ; If the data needs to be multiplied to convert to useful units   
units="mm" ;

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


;dir="/scratch/eg3/asp561/NCRA/bias-adjusted/"
GWlist=(/1.2,1.5,2,3/)
GWname=(/12,15,20,30/)
ssp="ssp370"
bc="QME"
dir="/g/data/ia39/ncra/extratropical_storms/bias-corrected/ACS-"+bc+"-AGCD-1960-2022/"

; Set up matrix - currently using just 13 ACS models not all RCMs
alldata=new((/dimsizes(mlat),dimsizes(mlon),dimsizes(model),dimsizes(GWlist)/),"float")
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

 print(m)
 a=addfiles(systemfunc("ls "+dir+"/"+var+"_AGCD-05i_"+model(m)+"_*_"+member(m)+"_"+agency(m)+"_"+rcm(m)+"_v1-r1-ACS-"+bc+"-AGCD-1960-2022_annual.nc"),"r")

 time=cd_calendar(a[:]->time,0)

 ; QME doing something weird so need to add the two files separately
 tmp=new((/dimsizes(time(:,0)),dimsizes(mlat),dimsizes(mlon)/),"float")
 tmp(ind(time(:,0).lt.2015),:,:)=tofloat(a[0]->$varname$)
 tmp(ind(time(:,0).ge.2015),:,:)=tofloat(a[1]->$varname$)
 ;tmp=a->low_freq

do y=0,dimsizes(GWlist)-1
 I=ind(mname.eq.model(m).and.mmember.eq.member(m).and.mssp.eq.ssp.and.mgwl.eq.GWlist(y))
 syear=tointeger(str_get_field(data(I),6,delim))
 eyear=tointeger(str_get_field(data(I),7,delim))

 J=ind(time(:,0).ge.syear.and.time(:,0).le.eyear)
 alldata(:,:,m,y)=where(mval.eq.1,dim_avg_n_Wrap(tmp(J,:,:),0),alldata@_FillValue)
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

I2=ispan(0,12,1)
summarydata(:,:,0,:)=dim_median_n(alldata(:,:,I2,:),2)

do i=0,dimsizes(mlat)-1
 do j=0,dimsizes(mlon)-1
  if(.not.ismissing(mval(i,j))) then
  do y=0,dimsizes(GWlist)-1
   tmp=alldata(i,j,I2,y)
   qsort(tmp)

   do p=1,dimsizes(pctiles)-1
    summarydata(i,j,p,y)=(/tmp(round(pctiles(p)*dimsizes(tmp)/100,3))/)
   end do
  end do
  end if
 end do
end do 
delete(tmp)

changedata=alldata(:,:,:,1:3)
do i=0,2
  changedata(:,:,:,i)=100*((changedata(:,:,:,i)/where(alldata(:,:,:,0).eq.0,alldata@_FillValue,alldata(:,:,:,0)))-1)
end do

; Set up matrix - currently using just 13 ACS models not all RCMs
summarychange=new((/dimsizes(mlat),dimsizes(mlon),dimsizes(pctiles),dimsizes(GWlist)-1/),"float")
summarychange!0="lat"
summarychange&lat=mlat
summarychange!1="lon"
summarychange&lon=mlon

I2=ispan(0,12,1)
summarychange(:,:,0,:)=dim_median_n(changedata(:,:,I2,:),2)

do i=0,dimsizes(mlat)-1
 do j=0,dimsizes(mlon)-1
  if(.not.ismissing(mval(i,j)))  then
  do y=0,dimsizes(GWlist)-2
   tmp=changedata(i,j,I2,y)
   qsort(tmp)

   do p=1,dimsizes(pctiles)-1
    summarychange(i,j,p,y)=(/tmp(round(pctiles(p)*dimsizes(tmp)/100,3))/)
   end do
  end do
  end if
 end do
end do
delete(tmp)

     nl = integertochar(10)  ; newline character

do y=0,dimsizes(GWlist)-1
do p=0,dimsizes(pctiles)-1

   ofile=dir+"/GWLs/"+var+"_AGCD-05i_MM"+pctiles(p)+"_"+ssp+"_v1-r1-ACS-"+bc+"-AGCD-1960-2022_GWL"+GWname(y)+".nc"
   a=addfile(ofile,"c")

 globalAtt             = True
globalAtt@sigma_level= "Values for the 20 year period corresponding to Global warming levels are derived for hazard indices from 13 regional models produced by the Australian Climate Service in /g/data/ia39/australian-climate-service/test-data/CORDEX-CMIP6/bias-adjustment-output/AGCD-05i/, which have been regridded to a common 5km grid (using "+bc+" bias correction)"
globalAtt@source      = "ACS hazard data in "+dir
globalAtt@title = pctiles(p)+"th percentile of the ACS ensemble of "+var+" at GWL"+GWlist(y)
globalAtt@history     = systemfunc("date") + ": ncl < /home/561/asp561/Code/NCRA/generate_GWL_grids_bias-adjusted.ncl"

  fileattdef( a, globalAtt )
  tmp=summarydata(:,:,p,y)
  tmp@standard_name=var
  tmp@units=units
  tmp@long_name=long_name

  a->$varname$=tmp
  delete([/ofile,a,tmp,globalAtt/])
end do
end do

do y=0,dimsizes(GWlist)-2
do p=0,dimsizes(pctiles)-1

   ofile=dir+"/GWLs/"+var+"_AGCD-05i_MM"+pctiles(p)+"_"+ssp+"_v1-r1-ACS-"+bc+"-AGCD-1960-2022_GWL"+GWname(y+1)+"_change.nc"
   a=addfile(ofile,"c")

 globalAtt             = True
globalAtt@sigma_level= "Values for the 20 year period corresponding to Global warming levels are derived for hazard indices from 13 regional models produced by the Australian Climate Service in /g/data/ia39/australian-climate-service/test-data/CORDEX-CMIP6/bias-adjustment-output/AGCD-05i/, which have been regridded to a common 5km grid (using "+bc+" bias correction)"
globalAtt@source      = "ACS hazard data in "+dir
globalAtt@title = pctiles(p)+"th percentile of the ensemble percentage change in annual mean "+var+" between GWL1.2 and GWL"+GWlist(y+1)
globalAtt@history     = systemfunc("date") + ": ncl < /home/561/asp561/Code/NCRA/generate_GWL_grids_bias-adjusted.ncl"

  fileattdef( a, globalAtt )
  tmp=summarychange(:,:,p,y)
  tmp@standard_name=var
  tmp@units="%"
  tmp@long_name="Change in "+long_name

  a->$varname$=tmp
  delete([/ofile,a,tmp,globalAtt/])

end do
end do


do y=0,dimsizes(GWlist)-1
do m=0,12

version="v1-r1-ACS-"+bc+"-AGCD-1960-2022"
ofile=dir+"/GWLs/"+var+"_AGCD-05i_"+model(m)+"_ssp370_"+member(m)+"_"+agency(m)+"_"+rcm(m)+"_"+version+"_GWL"+GWname(y)+".nc"

   a=addfile(ofile,"c")     
                                                          globalAtt             = True  
  globalAtt@sigma_level= "Values for the 20 year period corresponding to Global warming levels are derived for hazard indices from 13 regional models produced by the Australian Climate Service in /g/data/ia39/australian-climate-service/test-data/CORDEX-CMIP6/bias-adjustment-output/AGCD-05i/, which have been regridded to a common 5km grid (with "+bc+" correction)"

globalAtt@source      = "ACS hazard data in "+dir
globalAtt@title = "20-year mean "+var+" at GWL"+GWlist(y)+" for "+agency(m)+" "+rcm(m)+" "+model(m)+" "+member(m)
globalAtt@history     = systemfunc("date") + ": ncl < /home/561/asp561/Code/NCRA/generate_GWL_grids_bias-adjusted.ncl"

  fileattdef( a, globalAtt )
  tmp=alldata(:,:,m,y)
  copy_VarMeta(summarydata(:,:,0,y),tmp)
  tmp@standard_name=var
  tmp@units="%"
  tmp@long_name=long_name

  a->$varname$=tmp
  delete([/ofile,a,tmp,globalAtt/])

end do
end do



