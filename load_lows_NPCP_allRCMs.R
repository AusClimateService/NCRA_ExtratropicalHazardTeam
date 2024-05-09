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

rcm=c("Reanalysis","Reanalysis",rep("QLD-DES",15),rep("CCAM-CSIRO",6),rep("BARPA",7),rep("CMIP6",5))
model=c("ERA5","JRA55","ACCESS-CM2","ACCESS-ESM1-5","ACCESS-ESM1-5","ACCESS-ESM1-5","CMCC-ESM2","CNRM-CM6-1-HR","CNRM-CM6-1-HR","EC-Earth3","FGOALS-g3","GFDL-ESM4","GISS-E2-1-G","MPI-ESM1-2-LR","MRI-ESM2-0","NorESM2-MM","NorESM2-MM",
        "ACCESS-CM2","ACCESS-ESM1-5","CESM2","CMCC-ESM2","CNRM-ESM2-1","EC-Earth3",
        "ACCESS-CM2","EC-Earth3","NorESM2-MM","ACCESS-ESM1-5","CMCC-ESM2","CESM2","MPI-ESM1-2-HR",
        "NorESM2-MM","EC-Earth3","MRI-ESM2-0","ACCESS-CM2","MPI-ESM1-2-HR")
member=c(NaN,NaN,"r2i1p1f1","r20i1p1f1","r40i1p1f1","r6i1p1f1","r1i1p1f1","r1i1p1f2","r1i1p1f2","r1i1p1f1","r4i1p1f1","r1i1p1f1","r2i1p1f2","r9i1p1f1","r1i1p1f1","r1i1p1f1","r1i1p1f1",
         rep(NaN,6),rep(NaN,7),
         "r1i1p1f1","r1i1p1f1","r1i1p1f1","r4i1p1f1","r1i1p1f1")
version=c(NaN,NaN,"CCAMoc-v2112","CCAMoc-v2112","CCAMoc-v2112","CCAM-v2105","CCAM-v2105","CCAMoc-v2112","CCAM-v2112","CCAM-v2105","CCAM-v2105","CCAM-v2105","CCAM-v2105","CCAM-v2105","CCAM-v2105","CCAMoc-v2112","CCAM-v2112",rep(NaN,2),rep(NaN,7),rep(NaN,5))

projS=c("proj100_lows_rad2cv0.5_rt52/","proj100_lows_rad2cv0.5/",rep("proj100_lows_rad2cv0.5/",15),
        rep("proj100_lows_rad2cv0.5_hq89",6),rep("proj100_lows_rad2cv0.5_ia39",6),"proj100_lows_rad2cv0.5_py18",rep("proj100_lows_rad2cv0.5/",5))
projU=paste0("500hPa_z/",c("proj100_lows_rad2cv2_global/","proj100_lows_rad2cv2/",rep("proj100_lows_rad2cv1/",15),
                           rep("proj100_lows_rad2cv1_hq89",6),rep("proj100_lows_rad2cv1_ia39",6),"proj100_lows_rad2cv1_py18",
                           rep("proj100_lows_rad2cv1/",5)))

years=c(1960:2021,2070:2099)

ssp=rep("historical",length(years))
ssp[years>=2015]="ssp370"
winwid=10 # Test

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

cyccount<-cycgrid<-array(0,c(length(lon),length(lat),length(years),12,length(rcm),3))#,length(ssp))) # Only doing historical for now
dist=500
thresh=c(5,0.6)
#thresh=c(8,1,1028)
closed=c(T,T)
type=c("500hPa lows","Surface lows","Deep lows")
duration=c(1,1)

for(i in 1:length(model))
{
  print(paste(model[i],version[i],member[i]))
  
  for(y in 1:length(years))
  {
    if(years[y]==2100) next
    if(i<=2 & years[y]>=2022) next
    
    year=years[y]
    print(years[y])
    datelist=seq.POSIXt(as.POSIXct(paste0(min(year),"-01-01 00:00"),tz="GMT"), as.POSIXct(paste0(max(year),"-12-31 18:00"),tz="GMT"),by="6 hours")
    datelist=data.frame(Date=datelist,Year=as.numeric(format(datelist,"%Y")),Month=as.numeric(format(datelist,"%m")),YYYYMMDD=as.numeric(format(datelist,"%Y%m%d")))
    
    ##Upper
    if(i<=2) udir=paste0(bdir,model[i],"/",projU[i]) else 
      if(rcm[i]=="QLD-DES") udir=paste0(bdir,"/CCAM-QLD/",model[i],"_",version[i],"/",member[i],"/",ssp[y],"/",projU[i]) else
        if(rcm[i]=="BARPA") udir=paste0(bdir,"/BARPA/BARPA-R/",model[i],"/",ssp[y],"/",projU[i]) else
          if(rcm[i]=="CCAM-CSIRO") udir=paste0(bdir,"/CCAM-CMIP6/",model[i],"/",ssp[y],"/",projU[i]) else
            if(rcm[i]=="CMIP6") udir=paste0(bdir,"CMIP6/",model[i],"/",ssp[y],"/",member[i],"/",projU[i])
    
    fixesU=read.table(paste0(udir,"/tracks_",year,".dat"), sep="",skip=0)
    colnames(fixesU)<-c("ID","Fix","Date","Time","Open", "Lon","Lat","MSLP","CV","Depth","Radius","Up","Vp")
    ##Clean up dates
    yy=floor(fixesU$Date/10000)
    yy2=unique(yy)
    if(length(yy2)>1) fixesU=fixesU[yy==yy2[2],]
    fixesU$Date=(fixesU$Date%%10000) + year*10000
    if((rcm[i]=="CMIP6" & model[i]=="NorESM2-MM" & ssp[y]=="historical") | (rcm[i]=="CMIP6" & model[i]=="CMCC-ESM2" & ssp[y]=="ssp370")) fixesU$Date2=as.POSIXct(paste(fixesU$Date,fixesU$Time,sep=""),format="%Y%m%d %H:%M",tz="GMT")-3*60*60 else 
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
    if(i<=2) sdir=paste0(bdir,model[i],"/",projS[i]) else 
      if(rcm[i]=="QLD-DES") sdir=paste0(bdir,"/CCAM-QLD/",model[i],"_",version[i],"/",member[i],"/",ssp[y],"/",projS[i]) else
        if(rcm[i]=="BARPA") sdir=paste0(bdir,"/BARPA/BARPA-R/",model[i],"/",ssp[y],"/",projS[i]) else
          if(rcm[i]=="CCAM-CSIRO") sdir=paste0(bdir,"/CCAM-CMIP6/",model[i],"/",ssp[y],"/",projS[i]) else
            if(rcm[i]=="CMIP6") sdir=paste0(bdir,"CMIP6/",model[i],"/",ssp[y],"/",member[i],"/",projS[i])
    
    fixesS=read.table(paste0(sdir,"/tracks_",year,".dat"), sep="",skip=0)
    colnames(fixesS)<-c("ID","Fix","Date","Time","Open", "Lon","Lat","MSLP","CV","Depth","Radius","Up","Vp")
    ##Clean up dates
    yy=floor(fixesS$Date/10000)
    yy2=unique(yy)
    if(length(yy2)>1) fixesS=fixesS[yy==yy2[2],]
    fixesS$Date=(fixesS$Date%%10000) + year*10000
    if((rcm[i]=="CMIP6" & model[i]=="NorESM2-MM" & ssp[y]=="historical") | (rcm[i]=="CMIP6" & model[i]=="CMCC-ESM2" & ssp[y]=="ssp370")) fixesS$Date2=as.POSIXct(paste(fixesS$Date,fixesS$Time,sep=""),format="%Y%m%d %H:%M",tz="GMT")-3*60*60 else 
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
    
    
    for(j in 1:length(datelist[,1]))
    {
      #I=which(fixesU$Date==datelist$YYYYMMDD[j])
      I=which(fixesU$Date2==datelist$Date[j])
      
      if(length(I)>0) {
        grid1=table(factor(fixesU$Lon2[I],levels=floor(lon)),
                    factor(fixesU$Lat2[I],levels=floor(lat)))
        grid2=spreadeffect_simple(fixesU$Lat[I],fixesU$Lon[I],lat,lon,cycreg) 
      } else grid1<-grid2<-array(0,c(length(lon),length(lat)))
      
      cycgrid[,,y,datelist$Month[j],i,1]=cycgrid[,,y,datelist$Month[j],i,1]+grid2
      cyccount[,,y,datelist$Month[j],i,1]=cyccount[,,y,datelist$Month[j],i,1]+grid1
      
      #I=which(fixesS$Date==datelist$YYYYMMDD[j])
      I=which(fixesS$Date2==datelist$Date[j])
      
      if(length(I)>0) {
        grid1=table(factor(fixesS$Lon2[I],levels=floor(lon)),
                    factor(fixesS$Lat2[I],levels=floor(lat)))
        grid2=spreadeffect_simple(fixesS$Lat[I],fixesS$Lon[I],lat,lon,cycreg) 
      } else grid1<-grid2<-array(0,c(length(lon),length(lat)))
      
      cycgrid[,,y,datelist$Month[j],i,2]=cycgrid[,,y,datelist$Month[j],i,2]+grid2
      cyccount[,,y,datelist$Month[j],i,2]=cyccount[,,y,datelist$Month[j],i,2]+grid1
      
      
      #I=which(fixesS$Date==datelist$YYYYMMDD[j])
      I=which(fixesS$Date2==datelist$Date[j] & fixesS$UpperCV2>=thresh[1])
      
      if(length(I)>0) {
        grid1=table(factor(fixesS$Lon2[I],levels=floor(lon)),
                    factor(fixesS$Lat2[I],levels=floor(lat)))
        grid2=spreadeffect_simple(fixesS$Lat[I],fixesS$Lon[I],lat,lon,cycreg) 
      } else grid1<-grid2<-array(0,c(length(lon),length(lat)))
      
      cycgrid[,,y,datelist$Month[j],i,3]=cycgrid[,,y,datelist$Month[j],i,3]+grid2
      cyccount[,,y,datelist$Month[j],i,3]=cyccount[,,y,datelist$Month[j],i,3]+grid1
      
      
    }
    # print(sum(cycgrid[151,57,,i]))
    # test[y,]=cycgrid[151,57,,i]
    
  }
  
}

save(list=ls(),file="/scratch/eg3/asp561/NPCP_deeplows_fullyloaded_v2.RData")

