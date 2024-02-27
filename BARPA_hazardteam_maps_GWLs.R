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
rcm=rep("BARPA-R",6)
model=c("ACCESS-CM2","EC-Earth3","NorESM2-MM","ACCESS-ESM1-5","CMCC-ESM2","CESM2")
model2=paste0("BARPA-R-",model)

projU=paste0("500hPa_z/",rep("proj100_lows_rad2cv1_ia39/",6))
projS=rep("proj100_lows_rad2cv0.5_ia39/",6)

## GWL based on table at https://github.com/mathause/cmip_warming_levels/blob/main/warming_levels/cmip6/cmip6_warming_levels_one_ens_1850_1900.yml
cyear=cbind(rep(2020,6),c(2039,2038,2062,2048,2041,2043),c(2062,2063,2089,2069,2063,2066))

winwid=5 # Test

lat=seq(-89.5,-0.5)
lon=seq(0.5,359.5)
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

cyccount<-cycgrid<-array(0,c(length(lon),length(lat),12,length(rcm),3,3)) # Only doing historical for now
thresh=c(5,0.6) ## Deep surface lows ONLY
dist=500
closed=c(T,T)
duration=2
dimnames(cycgrid)[[4]]<-dimnames(cyccount)[[4]]<-model2
dimnames(cycgrid)[[5]]<-type<-c("Surface","Upper","Deep")
dimnames(cycgrid)[[6]]<-period<-c("2011-2030","GWL2","GWL3")

for(p in 3)
for(i in 3:length(model))
{
  print(model2[i])
  years=seq(cyear[i,p]-9,cyear[i,p]+10)
  ssp=rep("historical",length(years))
  ssp[years>=2015]="ssp370"
  
  for(y in 1:length(years))
  {
    print(years[y])
    sdir=paste0(bdir,"/BARPA/BARPA-R/",model[i],"/",ssp[y],"/",projS[i])
    udir=paste0(bdir,"/BARPA/BARPA-R/",model[i],"/",ssp[y],"/",projU[i])
            
            year=years[y]
            #datelist=seq.Date(as.Date(paste0(min(year),"-01-01")), as.Date(paste0(max(year),"-12-31")),by="1 day")
            datelist=seq.POSIXt(as.POSIXct(paste0(min(year),"-01-01 00:00"),tz="GMT"), as.POSIXct(paste0(max(year),"-12-31 18:00"),tz="GMT"),by="6 hours")
            
            datelist=data.frame(Date=datelist,Year=as.numeric(format(datelist,"%Y")),Month=as.numeric(format(datelist,"%m")),YYYYMMDD=as.numeric(format(datelist,"%Y%m%d")))
            
            fixesS=read.table(paste0(sdir,"/tracks_",year,".dat"), sep="",skip=0)
            fixesU=read.table(paste0(udir,"/tracks_",year,".dat"), sep="",skip=0)
            
            colnames(fixesS)<-colnames(fixesU)<-c("ID","Fix","Date","Time","Open",
                                                  "Lon","Lat","MSLP","CV","Depth","Radius","Up","Vp")
            ##Clean up dates
            yy=floor(fixesS$Date/10000)
            yy2=unique(yy)
            if(length(yy2)>1) fixesS=fixesS[yy==yy2[2],]
            yy=floor(fixesU$Date/10000)
            yy2=unique(yy)
            if(length(yy2)>1) fixesU=fixesU[yy==yy2[2],]
            
            fixesS$Date=(fixesS$Date%%10000) + year*10000
            fixesU$Date=(fixesU$Date%%10000) + year*10000
            
            fixesS$Date2=as.POSIXct(paste(fixesS$Date,fixesS$Time,sep=""),
                                    format="%Y%m%d %H:%M",tz="GMT")
            fixesU$Date2=as.POSIXct(paste(fixesU$Date,fixesU$Time,sep=""),
                                    format="%Y%m%d %H:%M",tz="GMT")
            
            ## Load the csv and make sure it has all the columns
            
            fixesU$Year=floor(fixesU$Date/10000)
            fixesU$Month=floor(fixesU$Date/100)%%100  
            fixesS$Year=floor(fixesS$Date/10000)
            fixesS$Month=floor(fixesS$Date/100)%%100
            
            ## Add a minimum duration criterion of 2 fixes
            
            if(duration>1)
            {
              x<-rle(fixesS[,1])
              events<-cbind(x$values,x$lengths,matrix(data=0,nrow=length(x$values),ncol=10))
              
              I<-which(events[,2]>=duration)
              J=which(fixesS[,1]%in%events[I,1])
              fixesS=fixesS[J,]
              
              x<-rle(fixesU[,1])
              events<-cbind(x$values,x$lengths,matrix(data=0,nrow=length(x$values),ncol=10))
              
              I<-which(events[,2]>=duration)
              J=which(fixesU[,1]%in%events[I,1])
              fixesU=fixesU[J,]
            }
            
            ## Select only lows above intensity threshold
            
            if(closed[2]) fixesS=fixesS[fixesS$Open%in%c(0,10),]
            if(closed[1]) fixesU=fixesU[fixesU$Open%in%c(0,10),]
            fixesS=fixesS[fixesS$CV>=thresh[2],]
            fixesU=fixesU[fixesU$CV>=thresh[1],]
            
            fixesS$Lat2=floor(fixesS$Lat)
            fixesS$Lon2=floor(fixesS$Lon)%%360
            fixesU$Lat2=floor(fixesU$Lat)
            fixesU$Lon2=floor(fixesU$Lon)%%360
            
            # Adding depth
            
            fixesS$Lon3=fixesS$Lon
            fixesS$Lon3[fixesS$Lon>180]=fixesS$Lon[fixesS$Lon>180]-360
            fixesU$Lon3=fixesU$Lon
            fixesU$Lon3[fixesU$Lon>180]=fixesU$Lon[fixesU$Lon>180]-360
            
            fixesS$UpperCV2<-fixesS$UpperCV<-0
            
            for(j in 1:length(fixesS[,1]))
            {
              J=which(fixesU$Date2==fixesS$Date2[j]) 
              
              if(length(J)>0) 
              {
                tmp=distGeo(cbind(fixesU$Lon3[J],fixesU$Lat[J]),cbind(fixesS$Lon3[j],fixesS$Lat[j]))/1000
                K=which(tmp<dist)
                if(length(K)>0) fixesS$UpperCV[j]=max(fixesU$CV[J[K]])
              }
            }
            # 
            # fixesU$LowerCV2<-fixesU$LowerCV<-0
            # 
            # for(j in 1:length(fixesU[,1]))
            # {
            #   J=which(fixesS$Date==fixesU$Date[j] & sign(fixesS$Lat)==sign(fixesU$Lat[j]))
            #   if(length(J)>0) {
            #     tmp=distGeo(cbind(fixesS$Lon3[J],fixesS$Lat[J]),cbind(fixesU$Lon3[j],fixesU$Lat[j]))/1000
            #     K=which(tmp<dist)
            #     if(length(K)>0) fixesU$LowerCV[j]=max(fixesS$CV[J[K]])
            #   }
            # }
            # 
            ## Event-based approach
            
            IDs=unique(fixesS$ID)
            for(id in IDs)
            {
              I=which(fixesS$ID==id)
              J=which(fixesS$ID==id & !is.na(fixesS$UpperCV))
              if(length(J)>0) fixesS$UpperCV2[I]=max(fixesS$UpperCV[J],na.rm=T)
            }
            
            # 
            # IDs=unique(fixesU$ID)
            # for(id in IDs)
            # {
            #   I=which(fixesU$ID==id)
            #   J=which(fixesU$ID==id & !is.na(fixesU$LowerCV))
            #   if(length(J)>0) fixesU$LowerCV2[I]=max(fixesU$LowerCV[J],na.rm=T)
            # }
            # 
            
            
            for(j in 1:length(datelist[,1]))
            {
              #print(datelist$YYYYMMDD[i])
              
              #I=which(fixesS$Date==datelist$YYYYMMDD[j])
              I=which(fixesS$Date2==datelist$Date[j])
              
              if(length(I)>0) {
                grid1=table(factor(fixesS$Lon2[I],levels=floor(lon)),
                            factor(fixesS$Lat2[I],levels=floor(lat)))
                grid2=spreadeffect_simple(fixesS$Lat[I],fixesS$Lon[I],lat,lon,cycreg) 
              } else grid1<-grid2<-array(0,c(length(lon),length(lat)))
              
              cycgrid[,,datelist$Month[j],i,1,p]=cycgrid[,,datelist$Month[j],i,1,p]+grid2
              cyccount[,,datelist$Month[j],i,1,p]=cyccount[,,datelist$Month[j],i,1,p]+grid1
              
              I=which(fixesU$Date2==datelist$Date[j])
              
              if(length(I)>0) {
                grid1=table(factor(fixesU$Lon2[I],levels=floor(lon)),
                            factor(fixesU$Lat2[I],levels=floor(lat)))
                grid2=spreadeffect_simple(fixesU$Lat[I],fixesU$Lon[I],lat,lon,cycreg) 
              } else grid1<-grid2<-array(0,c(length(lon),length(lat)))
              
              cycgrid[,,datelist$Month[j],i,2,p]=cycgrid[,,datelist$Month[j],i,2,p]+grid2
              cyccount[,,datelist$Month[j],i,2,p]=cyccount[,,datelist$Month[j],i,2,p]+grid1
              
              I=which(fixesS$Date2==datelist$Date[j] & fixesS$UpperCV2>=thresh[1])
              
              if(length(I)>0) {
                grid1=table(factor(fixesS$Lon2[I],levels=floor(lon)),
                            factor(fixesS$Lat2[I],levels=floor(lat)))
                grid2=spreadeffect_simple(fixesS$Lat[I],fixesS$Lon[I],lat,lon,cycreg) 
              } else grid1<-grid2<-array(0,c(length(lon),length(lat)))
              
              cycgrid[,,datelist$Month[j],i,3,p]=cycgrid[,,datelist$Month[j],i,3,p]+grid2
              cyccount[,,datelist$Month[j],i,3,p]=cyccount[,,datelist$Month[j],i,3,p]+grid1
            }
            # print(sum(cycgrid[151,57,,i]))
            # test[y,]=cycgrid[151,57,,i]
            
  }
  
}

datelist=seq.POSIXt(as.POSIXct(paste0(2011,"-01-01 00:00"),tz="GMT"), as.POSIXct(paste0(2030,"-12-31 18:00"),tz="GMT"),by="6 hours")
datelist=data.frame(Date=datelist,Year=as.numeric(format(datelist,"%Y")),Month=as.numeric(format(datelist,"%m")),YYYYMMDD=as.numeric(format(datelist,"%Y%m%d")))


cyccount=cyccount/20


breaks2=c(seq(0,2,0.25),2.5,3,10000)
cols2=rev(viridis(length(breaks2)-1))

breaks1=c(-10000,seq(-1,1,0.2),10000)
cols1=colorRampPalette(brewer.pal(11,"RdBu"))(length(breaks1)-1)

breaks3=c(seq(0,5,0.5),1000)
cols3=rev(viridis(length(breaks3)-1))

snames=c("Annual","MJJASO","NDJFMA")
mlist=list(1:12,5:10,c(11:12,1:4))

for(m in 1)
{
  cycfreq=apply(cyccount[,,mlist[[m]],,3,],c(1,2,4,5),sum)
  cycfreq2=100*apply(cycgrid[,,mlist[[m]],,3,],c(1,2,4,5),sum)/length(which(datelist$Month%in%mlist[[m]]))
  
  pdf(file=paste0("aust_cyccountpa_freq5_BARPA_surfacedeep_6h_20112030_GWL2_GWL3_",snames[m],".pdf"),width=10,height=3,pointsize=12)
  par(mar=c(2,2,3,1))
  layout(cbind(1,2,3,4),width=c(1,1,1,0.4))
  
  for(j in 1:3)
  {
  image(lon,lat,apply(cycfreq[,,,j],c(1,2),mean),
        breaks=breaks2,col=cols2,main=paste0("BARPA: ",period[j]),
        xlab="",ylab="",xlim=c(110,170),ylim=c(-45,0))
  map("world2",add=T)
  contour(lon,lat,apply(cycfreq2[,,,j],c(1,2),mean),levels=seq(2,20,2),add=T,drawlabels=F)
  }
  ColorBar(brks=breaks2,cols=cols2,vert=T,subsampleg=1)
  dev.off()

  pdf(file=paste0("aust_freq5_BARPA_surfacedeep_6h_20112030_GWL2_GWL3_change_",snames[m],".pdf"),width=11,height=3,pointsize=12)
  par(mar=c(2,2,3,1))
  layout(cbind(1,4,2,3,5),width=c(1,0.4,1,1,0.4))
  
  j=1
  image(lon,lat,apply(cycfreq2[,,,j],c(1,2),mean),
        breaks=breaks3,col=cols3,main=paste0("BARPA: ",period[j]),
        xlab="",ylab="",xlim=c(110,170),ylim=c(-45,0))
  map("world2",add=T)
  
  for(j in 2:3)
  {
  tmp=cycfreq2[,,,j]-cycfreq2[,,,1]
  image(lon,lat,apply(tmp,c(1,2),mean),
        breaks=breaks1,col=cols1,main=paste0("Mean difference: ",period[j]),
        xlab="",ylab="",xlim=c(110,170),ylim=c(-45,0))
  map("world2",add=T)
  I=which(apply(tmp>0,c(1,2),sum)<5 & apply(tmp>0,c(1,2),sum)>1,arr.ind=T)
  points(lon[I[,1]],lat[I[,2]],cex=0.2,pch=16)
  }
  ColorBar(brks=paste0(breaks3,"%"),cols=cols3,vert=T,subsampleg=1)
  ColorBar(brks=paste0(breaks1,"%"),cols=cols1,vert=T,subsampleg=1)
  dev.off()
}


I=which(lon>=110 & lon<=155)
J=which(lat>=-43 & lat<=-33)

tmp=apply(cycgrid[I,J,,,3,],c(4,5),mean,na.rm=T)*12

tmp=apply(cyccount[I,J,,,3,],c(4,5),sum,na.rm=T)

apply(tmp,2,mean)
mean(tmp[,2]>tmp[,1])