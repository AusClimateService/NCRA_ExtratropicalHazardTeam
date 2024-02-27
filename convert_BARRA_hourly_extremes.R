library(ncdf4)
indir="/g/data/ob53/BARRA2/output/reanalysis/AUS-11/BOM/ERA5/historical/hres/BARRA-R2/v1/1hr/pr/v20231001/"
odir="/scratch/eg3/asp561/BARRA2/"

years=seq(1991,2020)

mfile=nc_open("/g/data/ob53/BARRA2/output/reanalysis/AUS-11/BOM/ERA5/historical/hres/BARRA-R2/v1/fx/sftlf/v20231001/sftlf_AUS-11_ERA5_historical_hres_BOM_BARRA-R2_v1_fx.nc")
lat=ncvar_get(mfile,"lat")
lon=ncvar_get(mfile,"lon")

for(y in 1:length(years))
{
  n=1
  tmp=array(0,c(24*12,length(lon),length(lat)))
  
  h5<-h10<-h20<-array(0,c(length(lon),length(lat)))
  
  for(m in 1:12)
  {
    idate=paste0(years[y],sprintf("%2.2d",m))
    print(idate)
    a=nc_open(paste0(indir,"pr_AUS-11_ERA5_historical_hres_BOM_BARRA-R2_v1_1hr_",idate,"-",idate,".nc"))
    pr=ncvar_get(a,"pr")
    pr2=apply(pr*60*60,c(1,2),sort,decreasing=T)
    tmp[n:(n+23),,]=pr2[1:24,,]
    n=n+24
    
    h5=h5+apply(pr2>=5,c(2,3),sum)
    h10=h10+apply(pr2>=10,c(2,3),sum)
    h20=h20+apply(pr2>=20,c(2,3),sum)
    rm(pr)
    rm(pr2)
  }
  
  tmp2=apply(tmp,c(2,3),sort,decreasing=T)
  r1=tmp2[1,,]
  r24=tmp2[24,,]
  r24m=apply(tmp2[1:24,,],c(2,3),mean)
  
  
  dimX<-ncdim_def("lon","degrees_E",lon)
  dimY<-ncdim_def("lat","degrees_N",lat)
  
  fillvalue <- 1e32
  r1_def <- ncvar_def("RX1H","mm/h",list(dimX,dimY),fillvalue,"Highest hourly total",prec="single")
  r24_def <- ncvar_def("R1H_24","mm/h",list(dimX,dimY),fillvalue,"24th-highest hourly total, ~ 99.7th percentile",prec="single")
  r24m_def <- ncvar_def("R1H_24m","mm/h",list(dimX,dimY),fillvalue,"Average of the 24 highest hourly totals",prec="single")
  h5_def <- ncvar_def("H5mm","count",list(dimX,dimY),fillvalue,"Number of hours with rainfall >= 5mm/h",prec="single")
  h10_def <- ncvar_def("H10mm","count",list(dimX,dimY),fillvalue,"Number of hours with rainfall >= 10mm/h",prec="single")
  h20_def <- ncvar_def("H20mm","count",list(dimX,dimY),fillvalue,"Number of hours with rainfall >= 20mm/h",prec="single")
  
  # create netCDF file and put arrays
  ncfname <- paste(odir,"BARRA2_hourly_top24_",years[y],".nc",sep="")
  ncout <- nc_create(ncfname,list(r1_def,r24_def,r24m_def,h5_def,h10_def,h20_def),force_v4=T)
  
  # put variables
  ncvar_put(ncout,r1_def,r1)
  ncvar_put(ncout,r24_def,r24)
  ncvar_put(ncout,r24m_def,r24m)
  ncvar_put(ncout,h5_def,h5)
  ncvar_put(ncout,h10_def,h10)
  ncvar_put(ncout,h20_def,h20)
  
  # put additional attributes into dimension and data variables
  ncatt_put(ncout,"lon","axis","X") #,verbose=FALSE) #,definemode=FALSE)
  ncatt_put(ncout,"lat","axis","Y")
  
  nc_close(ncout)
}

