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
rcm=c("ERA5","BARRA-R2",rep("BARPA-R",7),rep("CMIP6",5))
model=c("ERA5","BARRA-R2","ERA5","ACCESS-CM2","EC-Earth3","NorESM2-MM","ACCESS-ESM1-5","CMCC-ESM2","CESM2","ACCESS-CM2","EC-Earth3","MPI-ESM1-2-HR","MRI-ESM2-0","NorESM2-MM")
model2=c("ERA5","BARRA-R2",paste0("BARPA-R-",model[3:9]),"ACCESS-CM2","EC-Earth3","MPI-ESM1-2-HR","MRI-ESM2-0","NorESM2-MM")
member=c(rep("r0",9),"r4i1p1f1","r1i1p1f1","r1i1p1f1","r1i1p1f1","r1i1p1f1")

projU=paste0("500hPa_z/",c("proj100_lows_rad2cv2_global/","proj100_lows_rad2cv1/",rep("proj100_lows_rad2cv1_ia39/",7),rep("proj100_lows_rad2cv1/",5)))
projS=c("proj100_lows_rad2cv0.5_rt52/","proj100_lows_rad2cv0.5/",rep("proj100_lows_rad2cv0.5_ia39/",7),rep("proj100_lows_rad2cv0.5/",5))


#ystart=c(1991,2008,1991,rep(1985,11))
#yend=c(2020,2008,2020,rep(2014,11))
ylist=1991:2020

ssp=rep("historical",30)
ssp[ylist>=2015]="ssp370"
y2=2008:2021
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

cyccount<-cycgrid<-array(0,c(length(lon),length(lat),12,length(rcm),3))#,length(ssp))) # Only doing historical for now
thresh=c(5,0.6) ## Deep surface lows ONLY
dist=500
closed=c(T,T)
duration=2
dimnames(cycgrid)[[4]]<-dimnames(cyccount)[[4]]<-model2
dimnames(cycgrid)[[5]]<-type<-c("Surface","Upper","Deep")

for(i in 1:length(model))
{
  print(model2[i])
  if(i==2) years=y2 else years=ylist
  
  for(y in 1:length(years))
  {
    print(years[y])
    if(i<=2) sdir=paste0(bdir,model[i],"/",projS[i]) else 
      if(i==3) sdir=paste0(bdir,"/BARPA/BARPA-R/",model[i],"/evaluation/",projS[i]) else 
        if(rcm[i]=="CMIP6") sdir=paste0(bdir,"/CMIP6/",model[i],"/",ssp[y],"/",member[i],"/",projS[i]) else sdir=paste0(bdir,"/BARPA/BARPA-R/",model[i],"/",ssp[y],"/",projS[i])
        
        if(i<=2) udir=paste0(bdir,model[i],"/",projU[i]) else 
          if(i==3) udir=paste0(bdir,"/BARPA/BARPA-R/",model[i],"/evaluation/",projU[i]) else 
            if(rcm[i]=="CMIP6") udir=paste0(bdir,"/CMIP6/",model[i],"/",ssp[y],"/",member[i],"/",projU[i]) else udir=paste0(bdir,"/BARPA/BARPA-R/",model[i],"/",ssp[y],"/",projU[i])
            
            
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
              
              cycgrid[,,datelist$Month[j],i,1]=cycgrid[,,datelist$Month[j],i,1]+grid2
              cyccount[,,datelist$Month[j],i,1]=cyccount[,,datelist$Month[j],i,1]+grid1
              
              I=which(fixesU$Date2==datelist$Date[j])
              
              if(length(I)>0) {
                grid1=table(factor(fixesU$Lon2[I],levels=floor(lon)),
                            factor(fixesU$Lat2[I],levels=floor(lat)))
                grid2=spreadeffect_simple(fixesU$Lat[I],fixesU$Lon[I],lat,lon,cycreg) 
              } else grid1<-grid2<-array(0,c(length(lon),length(lat)))
              
              cycgrid[,,datelist$Month[j],i,2]=cycgrid[,,datelist$Month[j],i,2]+grid2
              cyccount[,,datelist$Month[j],i,2]=cyccount[,,datelist$Month[j],i,2]+grid1
              
              I=which(fixesS$Date2==datelist$Date[j] & fixesS$UpperCV2>=thresh[1])
              
              if(length(I)>0) {
                grid1=table(factor(fixesS$Lon2[I],levels=floor(lon)),
                            factor(fixesS$Lat2[I],levels=floor(lat)))
                grid2=spreadeffect_simple(fixesS$Lat[I],fixesS$Lon[I],lat,lon,cycreg) 
              } else grid1<-grid2<-array(0,c(length(lon),length(lat)))
              
              cycgrid[,,datelist$Month[j],i,3]=cycgrid[,,datelist$Month[j],i,3]+grid2
              cyccount[,,datelist$Month[j],i,3]=cyccount[,,datelist$Month[j],i,3]+grid1
            }
    # print(sum(cycgrid[151,57,,i]))
    # test[y,]=cycgrid[151,57,,i]
            
  }
  
}

datelist=seq.POSIXt(as.POSIXct(paste0(min(ylist),"-01-01 00:00"),tz="GMT"), as.POSIXct(paste0(max(ylist),"-12-31 18:00"),tz="GMT"),by="6 hours")
datelist=data.frame(Date=datelist,Year=as.numeric(format(datelist,"%Y")),Month=as.numeric(format(datelist,"%m")),YYYYMMDD=as.numeric(format(datelist,"%Y%m%d")))

cycgrid[,,,2,]=cycgrid[,,,2,]*length(ylist)/length(y2) # Calibrate to be the same length


snames=c("Annual","MJJASO","NDJFMA")
mlist=list(1:12,5:10,c(11:12,1:4))

breaks2=c(seq(0,15,1),1000)
cols2=rev(viridis(length(breaks2)-1))
breaks=c(-1000,-75,-50,-25,-10,0,10,25,50,75,1000)
col1=brewer.pal(length(breaks)-1,"RdBu")

for(m in 1:3)
  {
    cycfreq=100*apply(cycgrid[,,mlist[[m]],,3],c(1,2,4),sum)/length(which(datelist$Month%in%mlist[[m]]))
    
    pdf(file=paste0("SH_cycfreq_ERA5_CMIP6_surfacedeep_6h_5deg_19912020_",snames[m],".pdf"),width=9,height=6,pointsize=16)
    par(mar=c(2,2,3,1))
    layout(rbind(c(1,3),2:3),width=c(1,0.2))
    
    image(lon,lat,cycfreq[,,1],
          breaks=breaks2,col=cols2,main=paste0("ERA5"),
          xlab="",ylab="",xlim=c(0,360),ylim=c(-90,0))
    map("world2",add=T)
    
    image(lon,lat,apply(cycfreq[,,rcm=="CMIP6"],c(1,2),mean),
          breaks=breaks2,col=cols2,main=paste0("Mean of 5 CMIP6 models"),
          xlab="",ylab="",xlim=c(0,360),ylim=c(-90,0))
    map("world2",add=T)
    ColorBar(brks=paste0(breaks2,"%"),cols=cols2,vert=T,subsampleg=1)
    dev.off()
    
    pdf(file=paste0("aust_cycfreq_ERA5_BARRA2_CMIP6_BARPA_surfacedeep_6h_5deg_19912020",snames[m],".pdf"),width=10,height=6,pointsize=16)
    par(mar=c(2,2,3,1))
    layout(rbind(c(1:3,6),c(7,4,5,6)),width=c(1,1,1,0.5))
    
    for(i in 1:3)
    {
    image(lon,lat,cycfreq[,,i],
          breaks=breaks2,col=cols2,main=model2[i],
          xlab="",ylab="",xlim=c(110,170),ylim=c(-45,0))
    map("world2",add=T)
    }
    
    image(lon,lat,apply(cycfreq[,,rcm=="CMIP6"],c(1,2),mean),
          breaks=breaks2,col=cols2,main=paste0("5 CMIP6 models (hist/ssp370)"),
          xlab="",ylab="",xlim=c(110,170),ylim=c(-45,0))
    map("world2",add=T)
    
      image(lon,lat,apply(cycfreq[,,4:9],c(1,2),mean),
            breaks=breaks2,col=cols2,main=paste0("6 BARPA-CMIP6 models"),
            xlab="",ylab="",xlim=c(110,170),ylim=c(-45,0))
      map("world2",add=T)
      
    ColorBar(brks=paste0(breaks2,"%"),cols=cols2,vert=T,subsampleg=1)
    dev.off()
  }


cyccount[,,,2,]=cyccount[,,,2,]/length(y2) # Calibrate to be the same length
cyccount[,,,-2,]=cyccount[,,,-2,]/length(ylist) # Calibrate to be the same length


breaks2=c(seq(0,2,0.25),2.5,3,10000)
cols2=rev(viridis(length(breaks2)-1))

for(m in 1)
{
  cycfreq=apply(cyccount[,,mlist[[m]],,3],c(1,2,4),sum)
  
  pdf(file=paste0("SH_cyccountpa_ERA5_CMIP6_surfacedeep_6h_5deg_19912020_",snames[m],".pdf"),width=9,height=6,pointsize=16)
  par(mar=c(2,2,3,1))
  layout(rbind(c(1,3),2:3),width=c(1,0.2))
  
  image(lon,lat,cycfreq[,,1],
        breaks=breaks2,col=cols2,main=paste0("ERA5"),
        xlab="",ylab="",xlim=c(0,360),ylim=c(-90,0))
  map("world2",add=T)
  
  image(lon,lat,apply(cycfreq[,,rcm=="CMIP6"],c(1,2),mean),
        breaks=breaks2,col=cols2,main=paste0("Mean of 5 CMIP6 models"),
        xlab="",ylab="",xlim=c(0,360),ylim=c(-90,0))
  map("world2",add=T)
  ColorBar(brks=paste0(breaks2),cols=cols2,vert=T,subsampleg=1)
  dev.off()
  
  pdf(file=paste0("aust_cyccount_ERA5_BARRA2_CMIP6_BARPA_surfacedeep_6h_5deg_19912020",snames[m],".pdf"),width=10,height=6,pointsize=16)
  par(mar=c(2,2,3,1))
  layout(rbind(c(1:3,6),c(7,4,5,6)),width=c(1,1,1,0.5))
  
  for(i in 1:3)
  {
    image(lon,lat,cycfreq[,,i],
          breaks=breaks2,col=cols2,main=model2[i],
          xlab="",ylab="",xlim=c(110,170),ylim=c(-45,0))
    map("world2",add=T)
  }
  
  image(lon,lat,apply(cycfreq[,,rcm=="CMIP6"],c(1,2),mean),
        breaks=breaks2,col=cols2,main=paste0("5 CMIP6 models (hist/ssp370)"),
        xlab="",ylab="",xlim=c(110,170),ylim=c(-45,0))
  map("world2",add=T)
  
  image(lon,lat,apply(cycfreq[,,4:9],c(1,2),mean),
        breaks=breaks2,col=cols2,main=paste0("6 BARPA-CMIP6 models"),
        xlab="",ylab="",xlim=c(110,170),ylim=c(-45,0))
  map("world2",add=T)
  
  ColorBar(brks=breaks2,cols=cols2,vert=T,subsampleg=1)
  dev.off()
}


for(m in 1)
{
  cycfreq=apply(cyccount[,,mlist[[m]],,3],c(1,2,4),sum)
  cycfreq2=100*apply(cycgrid[,,mlist[[m]],,3],c(1,2,4),sum)/length(which(datelist$Month%in%mlist[[m]]))
  
  pdf(file=paste0("SH_cyccountpa_freq5_ERA5_CMIP6_surfacedeep_6h_19912020_",snames[m],"_box.pdf"),width=9,height=6,pointsize=16)
  par(mar=c(2,2,3,1))
  layout(rbind(c(1,3),2:3),width=c(1,0.2))
  
  image(lon,lat,cycfreq[,,1],
        breaks=breaks2,col=cols2,main=paste0("ERA5"),
        xlab="",ylab="",xlim=c(5,355),ylim=c(-85,0))
  contour(lon,lat,cycfreq2[,,1],levels=seq(2,20,2),add=T,drawlabels=F)
  map("world2",add=T)
  polygon(x=c(110,110,170,170,110),y=c(-45,0,0,-45,-45),border="red")
  
  image(lon,lat,apply(cycfreq[,,rcm=="CMIP6"],c(1,2),mean),
        breaks=breaks2,col=cols2,main=paste0("Mean of 5 CMIP6 models"),
        xlab="",ylab="",xlim=c(5,355),ylim=c(-85,0))
  contour(lon,lat,apply(cycfreq2[,,rcm=="CMIP6"],c(1,2),mean),levels=seq(2,20,2),add=T,drawlabels=F)
  map("world2",add=T)
  polygon(x=c(110,110,170,170,110),y=c(-45,0,0,-45,-45),border="red")
  
  ColorBar(brks=paste0(breaks2),cols=cols2,vert=T,subsampleg=1)
  dev.off()


  pdf(file=paste0("aust_cyccountpa_freq5_ERA5_BARRA2_CMIP6_BARPA_surfacedeep_6h_19912020",snames[m],".pdf"),width=10,height=6,pointsize=16)
  par(mar=c(2,2,3,1))
  layout(rbind(c(1:3,6),c(7,4,5,6)),width=c(1,1,1,0.5))
  
  for(i in 1:3)
  {
    image(lon,lat,cycfreq[,,i],
          breaks=breaks2,col=cols2,main=model2[i],
          xlab="",ylab="",xlim=c(110,170),ylim=c(-45,0))
    map("world2",add=T)
    contour(lon,lat,cycfreq2[,,i],levels=seq(2,20,2),add=T,drawlabels=F)
  }
  
  image(lon,lat,apply(cycfreq[,,rcm=="CMIP6"],c(1,2),mean),
        breaks=breaks2,col=cols2,main=paste0("5 CMIP6 models (hist/ssp370)"),
        xlab="",ylab="",xlim=c(110,170),ylim=c(-45,0))
  map("world2",add=T)
  contour(lon,lat,apply(cycfreq2[,,rcm=="CMIP6"],c(1,2),mean),levels=seq(2,20,2),add=T,drawlabels=F)
  
  image(lon,lat,apply(cycfreq[,,4:9],c(1,2),mean),
        breaks=breaks2,col=cols2,main=paste0("6 BARPA-CMIP6 models"),
        xlab="",ylab="",xlim=c(110,170),ylim=c(-45,0))
  map("world2",add=T)
  contour(lon,lat,apply(cycfreq2[,,4:9],c(1,2),mean),levels=seq(2,20,2),add=T,drawlabels=F)
  
  ColorBar(brks=breaks2,cols=cols2,vert=T,subsampleg=1)
  dev.off()
}


for(m in 1)
{
  cycfreq=apply(cyccount[,,mlist[[m]],,3],c(1,2,4),sum)
  cycfreq2=100*apply(cycgrid[,,mlist[[m]],,3],c(1,2,4),sum)/length(which(datelist$Month%in%mlist[[m]]))
  
  pdf(file=paste0("combined_SH_aust_cyccountpa_freq5_ERA5_BARRA2_CMIP6_BARPA_surfacedeep_6h_19912020",snames[m],".pdf"),width=10,height=6,pointsize=16)
  par(mar=c(2,2,3,1))
  layout(rbind(c(1,1,1,5),2:5),width=c(1,1,1,0.5))
  
  image(lon,lat,cycfreq[,,1],
        breaks=breaks2,col=cols2,main=paste0("ERA5, 1991-2020"),
        xlab="",ylab="",xlim=c(5,355),ylim=c(-85,0))
  contour(lon,lat,cycfreq2[,,1],levels=seq(2,20,2),add=T,drawlabels=F)
  map("world2",add=T)
  polygon(x=c(110,110,170,170,110),y=c(-45,0,0,-45,-45),border="red")
  
    image(lon,lat,cycfreq[,,2],
          breaks=breaks2,col=cols2,main="BARRA-R2, 2008-2021",
          xlab="",ylab="",xlim=c(110,170),ylim=c(-45,0))
    map("world2",add=T)
    contour(lon,lat,cycfreq2[,,2],levels=seq(2,20,2),add=T,drawlabels=F)
  
  image(lon,lat,apply(cycfreq[,,rcm=="CMIP6"],c(1,2),mean),
        breaks=breaks2,col=cols2,main=paste0("5 CMIP6 GCMs, 1991-2020"),
        xlab="",ylab="",xlim=c(110,170),ylim=c(-45,0))
  map("world2",add=T)
  contour(lon,lat,apply(cycfreq2[,,rcm=="CMIP6"],c(1,2),mean),levels=seq(2,20,2),add=T,drawlabels=F)
  
  image(lon,lat,apply(cycfreq[,,4:9],c(1,2),mean),
        breaks=breaks2,col=cols2,main=paste0("6 BARPA RCMs, 1991-2020"),
        xlab="",ylab="",xlim=c(110,170),ylim=c(-45,0))
  map("world2",add=T)
  contour(lon,lat,apply(cycfreq2[,,4:9],c(1,2),mean),levels=seq(2,20,2),add=T,drawlabels=F)
  
  ColorBar(brks=breaks2,cols=cols2,vert=T,subsampleg=1)
  dev.off()
}




for(m in 1:3)
{
  cycfreq=100*apply(cycgrid[,,mlist[[m]],,,],c(1,2,4,5,6),sum)/length(which(datelist$Month%in%mlist[[m]]))
  
  # pdf(file=paste0("aust_cycfreq_BARRA2_BARPA_6models_",snames[m],"_closed.pdf"),width=16,height=6,pointsize=16)
  # par(mar=c(2,2,3,1))
  # layout(rbind(c(1:4,9),c(5:9)),width=c(1,1,1,1,0.5))
  # 
  # for(j in 1:2)
  # {
  #   image(lon,lat,cycfreq[,,2,1,j],
  #         breaks=breaks2,col=cols2,main=paste0(type2[j],": BARRA-R2 2008-2021"),
  #         xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
  #   map("world2",add=T)
  #   image(lon,lat,cycfreq[,,3,1,j],
  #         breaks=breaks2,col=cols2,main=paste0(lev[j],": BARPA-R-ERA5 1981-2010"),
  #         xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
  #   map("world2",add=T)
  #   image(lon,lat,apply(cycfreq[,,4:9,1,j],c(1,2),mean),
  #         breaks=breaks2,col=cols2,main=paste0(lev[j],": BARPA 1981-2010"),
  #         xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
  #   map("world2",add=T)
  #   image(lon,lat,apply(cycfreq[,,4:9,2,j],c(1,2),mean),
  #         breaks=breaks2,col=cols2,main=paste0(lev[j],": BARPA 2070-2099"),
  #         xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
  #   map("world2",add=T)
  # }
  # ColorBar(brks=paste0(breaks2,"%"),cols=cols2,vert=T,subsampleg=1)
  # dev.off()
  # 
  # 
  # cychange=100*((cycgrid[,,,2,]/cycgrid[,,,1,])-1)
  # breaks1=c(-1000,seq(-30,30,5),1000)
  
  cychange=cycfreq[,,,2,]-cycfreq[,,,1,]
  breaks1=c(-10000,seq(-10,10,2),10000)
  cols1=colorRampPalette(brewer.pal(11,"RdBu"))(length(breaks1)-1)
  
  
  pdf(file=paste0("aust_cycfreq_BARRA2_BARPA_abschange_vlevel_6models_",snames[m],"_closed.pdf"),width=18,height=6,pointsize=16)
  par(mar=c(2,2,3,1))
  layout(rbind(c(1,2,3,9,4,10),c(5,6,7,9,8,10)),width=c(1,1,1,0.5,1,0.5))
  for(j in 1:2)
  {
    image(lon,lat,cycfreq[,,2,1,j],
          breaks=breaks2,col=cols2,main=paste0(type[j],": BARRA-R2 2008-2021"),
          xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
    map("world2",add=T)
    image(lon,lat,cycfreq[,,3,1,j],
          breaks=breaks2,col=cols2,main=paste0(type[j],": BARPA-R-ERA5 1981-2010"),
          xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
    map("world2",add=T)
    image(lon,lat,apply(cycfreq[,,4:9,1,j],c(1,2),mean),
          breaks=breaks2,col=cols2,main=paste0(type[j],": BARPA 1981-2010"),
          xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
    map("world2",add=T)
    image(lon,lat,apply(cychange[,,4:9,j],c(1,2),mean),
          breaks=breaks1,col=cols1,main=paste0(type[j],": BARPA 2070-2099"),
          xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
    map("world2",add=T)
  }
  ColorBar(brks=paste0(breaks2,"%"),cols=cols2,vert=T,subsampleg=1)
  ColorBar(brks=paste0(breaks1,"%"),cols=cols1,vert=T,subsampleg=1)
  dev.off()
  
  pdf(file=paste0("aust_cycfreq_BARRA2_BARPA_abschange_vdepth_6models_",snames[m],"_closed.pdf"),width=18,height=9,pointsize=16)
  par(mar=c(2,2,3,1))
  layout(rbind(c(1:3,13,4,14),c(5:7,13,8,14),c(9:11,13,12,14)),width=c(1,1,1,0.5,1,0.5))
  for(j in 3:5)
  {
    image(lon,lat,cycfreq[,,2,1,j],
          breaks=breaks2,col=cols2,main=paste0(type[j],": BARRA-R2 2008-2021"),
          xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
    map("world2",add=T)
    image(lon,lat,cycfreq[,,3,1,j],
          breaks=breaks2,col=cols2,main=paste0(type[j],": BARPA-R-ERA5 1981-2010"),
          xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
    map("world2",add=T)
    image(lon,lat,apply(cycfreq[,,4:9,1,j],c(1,2),mean),
          breaks=breaks2,col=cols2,main=paste0(type[j],": BARPA 1981-2010"),
          xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
    map("world2",add=T)
    image(lon,lat,apply(cychange[,,4:9,j],c(1,2),mean),
          breaks=breaks1,col=cols1,main=paste0(type[j],": BARPA 2070-2099"),
          xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
    map("world2",add=T)
  }
  ColorBar(brks=paste0(breaks2,"%"),cols=cols2,vert=T,subsampleg=1)
  ColorBar(brks=paste0(breaks1,"%"),cols=cols1,vert=T,subsampleg=1)
  dev.off()
}

### All models abs change


snames=c("Annual","MJJASO","NDJFMA")
mlist=list(1:12,5:10,c(11:12,1:4))

breaks2=c(-10000,seq(-15,15,2.5),10000)
cols2=colorRampPalette(brewer.pal(11,"RdBu"))(length(breaks2)-1)
breaks3=c(-1000,seq(-50,50,10),1000)
cols3=colorRampPalette(brewer.pal(11,"RdBu"))(length(breaks3)-1)

for(m in 1:3)
{
  cycfreq=100*apply(cycgrid[,,mlist[[m]],,,],c(1,2,4,5,6),sum)/length(which(datelist$Month%in%mlist[[m]]))
  cychange=cycfreq[,,,2,]-cycfreq[,,,1,]
  
  for(j in 1:5)
  {
    pdf(file=paste0("aust_cycfreq_BARPA_abschange_all6models_",type2[j],"_",snames[m],"_closed.pdf"),width=13,height=6,pointsize=16)
    par(mar=c(2,2,3,1))
    layout(rbind(c(1:3,7),c(4:7)),width=c(1,1,1,0.5))
    
    for(i in 4:9)
    {
      
      image(lon,lat,cychange[,,i,j],
            breaks=breaks2,col=cols2,main=model2[i],
            xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
      map("world2",add=T)
    }
    ColorBar(brks=paste0(breaks2,"%"),cols=cols2,vert=T,subsampleg=1)
    dev.off()
  }
  
  cychange=100*((cycfreq[,,,2,]/cycfreq[,,,1,])-1)
  
  for(j in 1:5)
  {
    pdf(file=paste0("aust_cycfreq_BARPA_PCchange_all6models_",type2[j],"_",snames[m],"_closed.pdf"),width=13,height=6,pointsize=16)
    par(mar=c(2,2,3,1))
    layout(rbind(c(1:3,7),c(4:7)),width=c(1,1,1,0.5))
    
    for(i in 4:9)
    {
      
      image(lon,lat,cychange[,,i,j],
            breaks=breaks3,col=cols3,main=model2[i],
            xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
      map("world2",add=T)
    }
    ColorBar(brks=paste0(breaks3,"%"),cols=cols3,vert=T,subsampleg=1)
    dev.off()
  }
}

breaks2=c(-10000,seq(-15,15,2.5),10000)
cols2=colorRampPalette(brewer.pal(11,"RdBu"))(length(breaks2)-1)

pdf(file=paste0("aust_cycfreq_BARPA_abschange_6modelmean_vdepth_vseason_closed.pdf"),width=19,height=6,pointsize=16)
par(mar=c(2,2,3,1))
layout(rbind(c(1:5,11),c(6:11)),width=c(1,1,1,1,1,0.5))

for(m in 2:3)
{
  cycfreq=100*apply(cycgrid[,,mlist[[m]],,,],c(1,2,4,5,6),sum)/length(which(datelist$Month%in%mlist[[m]]))
  cychange=cycfreq[,,,2,]-cycfreq[,,,1,]
  
  for(j in 1:5)
  {
    image(lon,lat,apply(cychange[,,4:9,j],c(1,2),mean),
          breaks=breaks2,col=cols2,main=paste0(type[j]," lows: ",snames[m]),
          xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
    map("world2",add=T)
    
  }
}
ColorBar(brks=paste0(breaks2,"%"),cols=cols2,vert=T,subsampleg=1)
dev.off()


pdf(file=paste0("aust_cycfreq_BARPA_PCchange_6modelmean_vdepth_vseason_closed.pdf"),width=19,height=6,pointsize=16)
par(mar=c(2,2,3,1))
layout(rbind(c(1:5,11),c(6:11)),width=c(1,1,1,1,1,0.5))

for(m in 2:3)
{
  cycfreq=100*apply(cycgrid[,,mlist[[m]],,,],c(1,2,4,5,6),sum)/length(which(datelist$Month%in%mlist[[m]]))
  cychange=100*((cycfreq[,,,2,]/cycfreq[,,,1,])-1)
  
  for(j in 1:5)
  {
    image(lon,lat,apply(cychange[,,4:9,j],c(1,2),mean),
          breaks=breaks3,col=cols3,main=paste0(type[j]," lows: ",snames[m]),
          xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
    map("world2",add=T)
    
  }
}
ColorBar(brks=paste0(breaks3,"%"),cols=cols3,vert=T,subsampleg=1)
dev.off()



snames=c("Annual","MJJASO","NDJFMA")
mlist=list(1:12,5:10,c(11:12,1:4))

breaks2=c(-10000,seq(-15,15,2.5),10000)
cols2=colorRampPalette(brewer.pal(11,"RdBu"))(length(breaks2)-1)

pdf(file=paste0("aust_cycfreq_BARPA_abschangedays_6modelmean_vdepth_vseason_closed.pdf"),width=19,height=6,pointsize=16)
par(mar=c(2,2,3,1))
layout(rbind(c(1:5,11),c(6:11)),width=c(1,1,1,1,1,0.5))

for(m in 2:3)
{
  cycfreq=apply(cycgrid[,,mlist[[m]],,,],c(1,2,4,5,6),sum)
  cychange=cycfreq[,,,2,]-cycfreq[,,,1,]
  
  for(j in 1:5)
  {
    image(lon,lat,apply(cychange[,,4:9,j],c(1,2),mean),
          breaks=breaks2,col=cols2,main=paste0(type[j]," lows: ",snames[m]),
          xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
    map("world2",add=T)
    
    I=which((apply(cychange[,,4:9,j]>0,c(1,2),mean)<0.8 & apply(cychange[,,4:9,j]<0,c(1,2),mean)<0.8),arr.ind=T)
    points(lon[I[,1]],lat[I[,2]],cex=0.2,pch=16)
  }
}
ColorBar(brks=breaks2,cols=cols2,vert=T,subsampleg=1)
dev.off()


### Bias


breaks2=c(-10000,seq(-15,15,2.5),10000)
cols2=colorRampPalette(brewer.pal(11,"RdBu"))(length(breaks2)-1)

for(m in 1:3)
{
  
  cycbias=100*apply(cycgrid[,,mlist[[m]],,1,],c(1,2,4,5),sum)/length(which(datelist$Month%in%mlist[[m]]))
  
  for(i in 2:9) cycbias[,,i,]=cycbias[,,i,]-cycbias[,,1,]
  for(j in 1:5)
  {
    pdf(file=paste0("aust_cycfreq_BARPA_absbiasERA5_v6models_",type2[j],"_",snames[m],"_closed.pdf"),width=16,height=6,pointsize=16)
    par(mar=c(2,2,3,1))
    layout(rbind(c(1:4,9),c(5:9)),width=c(1,1,1,1,0.5))
    for(i in 2:9)
    {
      image(lon,lat,cycbias[,,i,j],
            breaks=breaks2,col=cols2,main=model2[i],
            xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
      map("world2",add=T)
      
    }
    ColorBar(brks=paste0(breaks2,"%"),cols=cols2,vert=T,subsampleg=1)
    dev.off()
  }
}




breaks2=c(-10000,seq(-15,15,2.5),10000)
cols2=colorRampPalette(brewer.pal(11,"RdBu"))(length(breaks2)-1)


pdf(file=paste0("aust_cycfreq_BARPA_absbiasERA5_6modelmean_vdepth_vseason_closed.pdf"),width=19,height=6,pointsize=16)
par(mar=c(2,2,3,1))
layout(rbind(c(1:5,11),c(6:11)),width=c(1,1,1,1,1,0.5))

for(m in 2:3)
{
  cycbias=100*apply(cycgrid[,,mlist[[m]],,1,],c(1,2,4,5),sum)/length(which(datelist$Month%in%mlist[[m]]))
  for(i in 2:9) cycbias[,,i,]=cycbias[,,i,]-cycbias[,,1,]
  
  for(j in 1:5)
  {
    image(lon,lat,apply(cycbias[,,4:9,j],c(1,2),mean),
          breaks=breaks2,col=cols2,main=paste0(type[j]," lows: ",snames[m]),
          xlab="",ylab="",xlim=c(105,180),ylim=c(-45,0))
    map("world2",add=T)
    
  }
}
ColorBar(brks=paste0(breaks2,"%"),cols=cols2,vert=T,subsampleg=1)
dev.off()


