rm(list=ls())
source("~/Code/CycloneTracking/init_cyclones.R")

library(raster)
library(sp)
library(ncdf4)
library(abind)
library(geosphere)
library(oz)
library(viridisLite)
library(RColorBrewer)


## Supply a grid, a list of points based on their location within the grid,
### And a spread to overlay
spreadeffect_simple<-function(lats,lons,glats,glons,spread,winwid=NaN)
{
  grid<-array(0,c(length(glons),length(glats)))
  
  ## How big is the spread matrix? We assume it & the glats are the same resolution
  dx=(dim(spread)[1]-1)/2
  dy=(dim(spread)[2]-1)/2
  
  for(j in 1:length(lats))
  {
    x=which.min(abs(lons[j] - glons))
    y=which.min(abs(lats[j] - glats))
    
    ### Find location of low centre. If it's at least winwid from the boundary, then add a circle
    if(x>dx & x<(length(glons)-dx) & y>dy & y<(length(glats)-dy))
    {
      XX=seq(x-dx,x+dx)
      YY=seq(y-dy,y+dy)
      grid[XX,YY]=grid[XX,YY]+spread
    }
  }
  grid[grid>0]=1
  return(grid)
}



bdir="/g/data/eg3/asp561/CycloneTracking/"
odir="/scratch/eg3/asp561/NCRA/"

reanalysis="BARRA-R2"
projS="proj100_lows_rad2cv0.5_ob53"
projU=paste0("500hPa_z/","proj100_lows_rad2cv1_ob53")

ssp="evaluation"
year1=1979
year2=2022

#year1=c(rep(1951,6),rep(1960,7))
thresh=c(5,0.6) ## Deep surface lows ONLY
dist=500
closed=c(T,T)
duration=c(1,2)
winwid=5

lat=seq(-50.5,-0.5)
lon=seq(90.5,180.5)
dx<-dy<-1
lat2=seq(min(lat)-2*winwid,max(lat)+2*winwid,dy)
lon2=seq(min(lon)-2*winwid,max(lon)+2*winwid,dx)
jlat=which(lat2>=min(lat) & lat2<=max(lat))
ilon=which(lon2>=min(lon) & lon2<=max(lon))

tmplat=seq(-winwid,winwid,dy)
tmplon=seq(-winwid,winwid,dx)
i=which.min(abs(tmplon))
j=which.min(abs(tmplat))

tmp=array(0,c(length(tmplon),length(tmplat)))
tmp[i,j]=1
cycreg=focalWeight(raster(tmp,xmn=-winwid,xmx=winwid,ymn=-winwid,ymx=winwid),winwid,type="circle")
cycreg[cycreg>0]=1

i=1
  print(i)
  years=seq(year1[i],year2[i])
  cycgrid<-array(0,c(length(lon),length(lat),length(years)*12))
  
  datelist=seq.POSIXt(as.POSIXct(paste0(min(years),"-01-01 00:00"),tz="GMT"), as.POSIXct(paste0(max(years),"-12-31 18:00"),tz="GMT"),by="6 hours")
  datelist=data.frame(Date=datelist,Year=as.numeric(format(datelist,"%Y")),Month=as.numeric(format(datelist,"%m")),YYYYMMDD=as.numeric(format(datelist,"%Y%m%d")))
  
  datelist2=seq.POSIXt(as.POSIXct(paste0(min(years),"0115 09:00"),format="%Y%m%d %H:%M",tz="GMT"),as.POSIXct(paste0(max(years),"1231 09:00"),format="%Y%m%d %H:%M",tz="GMT"),by="1 month")
  datelist2=data.frame(Date=datelist2,Year=as.numeric(format(datelist2,"%Y")),Month=as.numeric(format(datelist2,"%m")),YYYYMMDD=as.numeric(format(datelist2,"%Y%m%d")))
  
  for(y in 1:length(years))
  {
    year=years[y]
    
    ##Upper
      udir=paste0(bdir,reanalysis[i],"/",projU[i])

      fixesU=read.table(paste0(udir,"/tracks_",year,".dat"), sep="",skip=0)
      colnames(fixesU)<-c("ID","Fix","Date","Time","Open", "Lon","Lat","MSLP","CV","Depth","Radius","Up","Vp")
      ##Clean up dates
      yy=floor(fixesU$Date/10000)
      yy2=unique(yy)
      if(length(yy2)>1) fixesU=fixesU[yy==yy2[2],]
      fixesU$Date=(fixesU$Date%%10000) + year*10000
      fixesU$Date2=as.POSIXct(paste(fixesU$Date,fixesU$Time,sep=""),format="%Y%m%d %H:%M",tz="GMT")
      fixesU$Year=floor(fixesU$Date/10000)
      fixesU$Month=floor(fixesU$Date/100)%%100
      
      ## Add a minimum duration criterion of 2 fixes
      
      if(duration[1]>1)
      {
        x<-rle(fixesU[,1])
        events<-cbind(x$values,x$lengths,matrix(data=0,nrow=length(x$values),ncol=10))
        
        I<-which(events[,2]>=duration[1])
        J=which(fixesU[,1]%in%events[I,1])
        fixesU=fixesU[J,]
      }
      
      ## Select only lows above intensity threshold
      
      if(closed[1]) fixesU=fixesU[fixesU$Open%in%c(0,10),]
      fixesU=fixesU[fixesU$CV>=thresh[1],]
      fixesU$Lat2=floor(fixesU$Lat)
      fixesU$Lon2=floor(fixesU$Lon)%%360
      
      ##Surface
      sdir=paste0(bdir,reanalysis[i],"/",projS[i])

      fixesS=read.table(paste0(sdir,"/tracks_",year,".dat"), sep="",skip=0)
      colnames(fixesS)<-c("ID","Fix","Date","Time","Open", "Lon","Lat","MSLP","CV","Depth","Radius","Up","Vp")
      ##Clean up dates
      yy=floor(fixesS$Date/10000)
      yy2=unique(yy)
      if(length(yy2)>1) fixesS=fixesS[yy==yy2[2],]
      fixesS$Date=(fixesS$Date%%10000) + year*10000
      fixesS$Date2=as.POSIXct(paste(fixesS$Date,fixesS$Time,sep=""),format="%Y%m%d %H:%M",tz="GMT")
      fixesS$Year=floor(fixesS$Date/10000)
      fixesS$Month=floor(fixesS$Date/100)%%100
      
      ## Add a minimum duration criterion of 2 fixes
      
      if(duration[2]>1)
      {
        x<-rle(fixesS[,1])
        events<-cbind(x$values,x$lengths,matrix(data=0,nrow=length(x$values),ncol=10))
        
        I<-which(events[,2]>=duration[2])
        J=which(fixesS[,1]%in%events[I,1])
        fixesS=fixesS[J,]
      }
      
      ## Select only lows above intensity threshold
      
      if(closed[2]) fixesS=fixesS[fixesS$Open%in%c(0,10),]
      fixesS=fixesS[fixesS$CV>=thresh[2],]
      fixesS$Lat2=floor(fixesS$Lat)
      fixesS$Lon2=floor(fixesS$Lon)%%360
      
      ## Deep
      fixesS$Lon3=fixesS$Lon
      fixesS$Lon3[fixesS$Lon>180]=fixesS$Lon[fixesS$Lon>180]-360
      fixesU$Lon3=fixesU$Lon
      fixesU$Lon3[fixesU$Lon>180]=fixesU$Lon[fixesU$Lon>180]-360
      fixesS$UpperCV2<-fixesS$UpperCV<-0
      for(j in 1:length(fixesS[,1]))
      {
        J=which(fixesU$Date2==fixesS$Date2[j] & sign(fixesU$Lat)==sign(fixesS$Lat[j])) 
        
        if(length(J)>0) 
        {
          tmp=distGeo(cbind(fixesU$Lon3[J],fixesU$Lat[J]),cbind(fixesS$Lon3[j],fixesS$Lat[j]))/1000
          K=which(tmp<dist)
          if(length(K)>0) fixesS$UpperCV[j]=max(fixesU$CV[J[K]])
        }
      }
      IDs=unique(fixesS$ID)
      for(id in IDs)
      {
        I=which(fixesS$ID==id)
        J=which(fixesS$ID==id & !is.na(fixesS$UpperCV))
        if(length(J)>0) fixesS$UpperCV2[I]=max(fixesS$UpperCV[J],na.rm=T)
      }
      
      
      for(m in 1:12)
      {
        Y1=which(datelist$Year==year & datelist$Month==m)
        Y2=which(datelist2$Year==year & datelist2$Month==m)
        
        for(j in Y1)
        {
          I=which(fixesS$Date2==datelist$Date[j] & fixesS$UpperCV2>=thresh[1])
          
          if(length(I)>0) grid2=spreadeffect_simple(fixesS$Lat[I],fixesS$Lon[I],lat,lon,cycreg) else grid2<-array(0,c(length(lon),length(lat)))
          
          cycgrid[,,Y2]=cycgrid[,,Y2]+grid2
          
        }
        
        cycgrid[,,Y2]=cycgrid[,,Y2]/length(Y1)

      }
 
      
  }
  
  
  ### Now, need to turn this into a useful netCDF file
  
  dimX<-ncdim_def("lon","degrees_E",lon)
  dimY<-ncdim_def("lat","degrees_N",lat)
  fillvalue <- 1e32
  dimT<-ncdim_def("time","hours since 1970-1-1 00:00:00",as.numeric(datelist2[,1])/(60*60))
  
  
  cyc_def <- ncvar_def("low_freq","proportion",list(dimX,dimY,dimT),fillvalue,prec="float",
                       paste0("Proportion of 6-hourly observations with a low within a ",winwid," degree radius."))
  
  
  ncout <- nc_create(paste0(odir,"/lows_ERA5_historical_hres_BOM_BARRA-R2_v1_annual.nc"),cyc_def) #force_v4=T)
  
  # put variables
  ncvar_put(ncout,cyc_def,cycgrid)
  
  # put additional attributes into dimension and data variables
  ncatt_put(ncout,"lon","axis","X") #,verbose=FALSE) #,definemode=FALSE)
  ncatt_put(ncout,"lat","axis","Y")
  ncatt_put(ncout,"time","axis","T")
  ncatt_put(ncout,0,"description",paste0("Proportion of 6-hourly observations with a surface low identified within a ",winwid," degree radius. Lows are required to have a mean Laplacian within a 2 degree radius of the cyclone centre of at least ",
                                         thresh[2],"hPa/(deg.lat.)^2, be detected for at least ",duration[2]," consecutive hours, and have a 500hPa low with Laplacian>=",thresh[1],"m/(deg.lat.)^2 within a ",dist,"km radius at least once. ",
                                         "Lows are identified using the University of Melbourne tracking scheme, as per https://github.com/apepler/cyclonetracking. Data is regridded to a polar projection equal to ~ 1.5 degrees at 30S prior to tracking. ", 
                                         "Data is converted to a 1 degree grid by https://github.com/AusClimateService/NCRA_ExtratropicalHazardTeam/extract_gridded_lows.R, with latitude and longitude referring to the centre of the grid box"))
  ncatt_put(ncout,0,"source",sdir)
  ncatt_put(ncout,0,"author","Acacia Pepler <acacia.pepler@bom.gov.au>")
  ncatt_put(ncout,0,"creation_date",Sys.time())

  nc_close(ncout)

#}

