library(ncdf4)
setwd("/scratch/eg3/asp561/NCRA/bias-adjusted/")

### Code to calculate regional averages. WIll eventually be replaced by [ython scripts


agency=c('BOM','BOM','BOM','BOM','BOM','BOM','BOM','CSIRO','CSIRO','CSIRO','CSIRO','CSIRO','CSIRO','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES')
model=c('ACCESS-CM2','ACCESS-ESM1-5','CESM2','CMCC-ESM2','EC-Earth3','MPI-ESM1-2-HR','NorESM2-MM','ACCESS-CM2','ACCESS-ESM1-5','CESM2','CMCC-ESM2','CNRM-ESM2-1','EC-Earth3','ACCESS-CM2','ACCESS-ESM1-5','ACCESS-ESM1-5','ACCESS-ESM1-5','CMCC-ESM2','CNRM-CM6-1-HR','CNRM-CM6-1-HR','EC-Earth3','FGOALS-g3','GFDL-ESM4','GISS-E2-1-G','MPI-ESM1-2-LR','MRI-ESM2-0','NorESM2-MM','NorESM2-MM')
member=c('r4i1p1f1','r6i1p1f1','r11i1p1f1','r1i1p1f1','r1i1p1f1','r1i1p1f1','r1i1p1f1','r4i1p1f1','r6i1p1f1','r11i1p1f1','r1i1p1f1','r1i1p1f2','r1i1p1f1','r2i1p1f1','r20i1p1f1','r40i1p1f1','r6i1p1f1','r1i1p1f1','r1i1p1f2','r1i1p1f2','r1i1p1f1','r4i1p1f1','r1i1p1f1','r2i1p1f2','r9i1p1f1','r1i1p1f1','r1i1p1f1','r1i1p1f1')
rcm=c('BARPA-R','BARPA-R','BARPA-R','BARPA-R','BARPA-R','BARPA-R','BARPA-R','CCAM-v2203-SN','CCAM-v2203-SN','CCAM-v2203-SN','CCAM-v2203-SN','CCAM-v2203-SN','CCAM-v2203-SN','CCAMoc-v2112','CCAMoc-v2112','CCAMoc-v2112','CCAM-v2105','CCAM-v2105','CCAMoc-v2112','CCAM-v2112','CCAM-v2105','CCAM-v2105','CCAM-v2105','CCAM-v2105','CCAM-v2105','CCAM-v2105','CCAMoc-v2112','CCAM-v2112')

regnames=c("australia","southern_australia","northern_australia","WA_North","WA_South","NSW","VIC","SA","TAS","NT","QLD_North","QLD_South",
           "SWWA","southeast")

a=nc_open("/g/data/eg3/asp561/Shapefiles/mask_australia_0.05deg.nc")
mask=ncvar_get(a,"landmask")
mask[mask==0]=NaN

lon=ncvar_get(a,"longitude")
lat=ncvar_get(a,"latitude")
I=which(lon>=122 & lon<=132)
J=which(lat>=-30 & lat<=-20)
mask[I,J]=NaN # Removing some dodgy areas 
nc_close(a)

rdir="/g/data/eg3/asp561/Shapefiles/NCRA/"
regmask=array(0,c(length(lon),length(lat),length(regnames)))
regmask[,,1]=mask

## Add my own regions - critical for lows where only saust is appropriate to include
tmp=mask
I=which(lat>=-30)
tmp[,I]=NaN
regmask[,,2]=tmp

tmp=mask
I=which(lat<(-30))
tmp[,I]=NaN
regmask[,,3]=tmp

# Add SEA
tmp=mask
I=which(lat>(-33))
tmp[,I]=NaN
J=which(lon<133)
tmp[J,]=NaN
regmask[,,14]=tmp

for(r in 4:12)
{
  a=nc_open(paste0(rdir,"/mask_NCRA_",regnames[r],"_0.05deg.nc"))
  mask=ncvar_get(a,"landmask")
  mask[mask==0]=NaN
  I=which(lon>=122 & lon<=132)
  J=which(lat>=-30 & lat<=-20)
  mask[I,J]=NaN
  regmask[,,r]=mask
}

# Add SWWA
a=nc_open("/g/data/eg3/asp561/Shapefiles/mask_SWWA_0.05deg.nc")
mask=ncvar_get(a,"landmask")
mask[mask==0]=NaN
regmask[,,13]=mask


## Changing australian region to exclue dodgy area
# mask2=mask
# I=which(lon>=122 & lon<=132)
# J=which(lat>=-30 & lat<=-20)
# mask2[I,J]=NaN # Removing some dodgy areas 
# regmask[,,1]=mask2

#odir="/scratch/eg3/asp561/NCRA/5km/GWLs/"
#indir="/g/data/ia39/ncra/extratropical_storms/5km/GWLs/"
indir="/scratch/eg3/asp561/NCRA/bias-adjusted/GWLs/"
odir=indir
ssp="ssp370"
gwl=c(12,15,20,30)
pctile=c(50,10,90)

var="pr"
var2="prAdjust"
bc=c("QME")#,"MRNBC")
sname="_annual"

meanchange=array(0,c(length(regnames),3,3,3))
dimnames(meanchange)=list(regnames,gwl[2:4],pctile,c("Region.Mean.then.Change","Model.Change.Then.Mean","Cookie-cutter"))

modelarray=array(NaN,c(length(bc)*length(model),length(regnames),7))
dimnames(modelarray)[[3]]=c(paste0("GWL",gwl),paste0("change_",gwl[2:4]))
  
ind=0
for(m in 1:length(model))
  for(b in 1)
  {
    ind=ind+1
    fname=paste0(var,"_AGCD-05i_",model[m],"_",ssp,"_",member[m],"_",agency[m],"_",rcm[m],"_v1-r1-ACS-",bc[b],"-AGCD-1960-2022_GWL")
    
    a=nc_open(paste0(indir,fname,gwl[1],sname,".nc"))
    tmp=ncvar_get(a,var2)
    
    for(r in 1:length(regnames)) modelarray[ind,r,1]=mean(tmp*regmask[,,r],na.rm=T)
    
    for(g in 2:4)
    {
      a=nc_open(paste0(indir,fname,gwl[g],sname,".nc"))
      tmp2=ncvar_get(a,var2)
      for(r in 1:length(regnames)) modelarray[ind,r,g]=mean(tmp2*regmask[,,r],na.rm=T)
      for(r in 1:length(regnames)) modelarray[ind,r,g+3]=mean(100*((tmp2/tmp)-1)*regmask[,,r],na.rm=T)
    }
  }

# 
# for(g in 1:3)
#   for(p in 1:3)
#   {
#     meanchange[,g,p,1]=apply(100*((modelarray[1:ind,,g+1]/modelarray[1:ind,,1])-1),2,quantile,pctile[p]/100,na.rm=T)
#     meanchange[,g,p,2]=apply(modelarray[1:ind,,g+4],2,quantile,pctile[p]/100,na.rm=T)
#     
#     fname=paste0(var,"_AGCD-05i_MM",pctile[p],"_",ssp,"_bias-adjusted_GWL",gwl[g+1],"_change.nc")
# 
#     a=nc_open(paste0(indir,fname))
#     tmp=ncvar_get(a,var2)
#     for(r in 1:length(regnames)) meanchange[r,g,p,3]=mean(tmp*regmask[,,r],na.rm=T)
#   }
# 
# agreement=array(0,c(length(regnames),3,3))
# dimnames(agreement)=list(regnames,gwl[2:4],c("Region.Mean.then.Change","Model.Change.Then.Mean","Cookie-cutter"))
# 
# for(g in 1:3)
#   {
#     tmp=100*((modelarray[1:ind,,g+1]/modelarray[1:ind,,1])-1)
#     agreement[,g,1]=apply(tmp>0,2,mean)
#     agreement[,g,2]=apply(modelarray[1:ind,,g+4]>0,2,mean)
# }
# 
# agreement[,,1]>0.65 | agreement[,,1]<0.35

## Verson two, including queensland


meanchange=array(0,c(length(regnames),3,3,3))
dimnames(meanchange)=list(regnames,gwl[2:4],pctile,c("All","ACS","Qld"))


for(g in 1:3)
  for(p in 1:3)
  {
     meanchange[,g,p,1]=apply(modelarray[1:ind,,g+4],2,quantile,pctile[p]/100,na.rm=T)
     meanchange[,g,p,2]=apply(modelarray[1:13,,g+4],2,quantile,pctile[p]/100,na.rm=T)
     meanchange[,g,p,3]=apply(modelarray[14:ind,,g+4],2,quantile,pctile[p]/100,na.rm=T)
  }


agreement=array(0,c(length(regnames),3,3))
dimnames(agreement)=list(regnames,gwl[2:4],c("All","ACS","Qld"))

for(g in 1:3)
{
  agreement[,g,1]=apply(modelarray[1:ind,,g+4]>0,2,mean)
  agreement[,g,2]=apply(modelarray[1:13,,g+4]>0,2,mean)
  agreement[,g,3]=apply(modelarray[14:ind,,g+4]>0,2,mean)
}
meanchange[1,,,2]
meanchange[,3,,2]

agreement[,,2]




#Table data
tmp=cbind(apply(modelarray[1:ind,,1],2,median),
      meanchange[,,1,2],
      agreement[,2,2],
      meanchange[,2,3,2])

for(i in 1:3)
{
  I=which(agreement[,i,2]<0.65 & agreement[,i,2]>0.35)
  tmp[I,i+1]=NaN
}

tmp
agreement[,,1]<0.35 |  agreement[,,1]>0.65
meanchange[,3,,1]



########### Do for the raw data because of the data holes messing things up!


indir="/g/data/ia39/ncra/extratropical_storms/5km/GWLs/"
odir=indir
ssp="ssp370"
gwl=c(12,15,20,30)
pctile=c(50,10,90)

var="lows"
var2="low_freq"

meanchange=array(0,c(length(regnames),3,3,3))
dimnames(meanchange)=list(regnames,gwl[2:4],pctile,c("Region.Mean.then.Change","Model.Change.Then.Mean","Cookie-cutter"))

modelarray=array(0,c(13,length(regnames),7))
dimnames(modelarray)[[3]]=c(paste0("GWL",gwl),paste0("change_",gwl[2:4]))

ind=0
for(m in 1:13)
  {
    ind=ind+1
    fname=paste0(var,"_AGCD-05i_",model[m],"_",ssp,"_",member[m],"_",agency[m],"_",rcm[m],"_v1-r1_GWL")
    
    a=nc_open(paste0(indir,fname,gwl[1],".nc"))
    tmp=ncvar_get(a,var2)
    
    for(r in 1:length(regnames)) modelarray[ind,r,1]=mean(tmp*regmask[,,r],na.rm=T)
    
    for(g in 2:4)
    {
      a=nc_open(paste0(indir,fname,gwl[g],".nc"))
      tmp2=ncvar_get(a,var2)
      for(r in 1:length(regnames)) modelarray[ind,r,g]=mean(tmp2*regmask[,,r],na.rm=T)
      for(r in 1:length(regnames)) modelarray[ind,r,g+3]=mean(100*((tmp2/tmp)-1)*regmask[,,r],na.rm=T)
    }
  }


for(g in 1:3)
  for(p in 1:3)
  {
    meanchange[,g,p,1]=apply(100*((modelarray[,,g+1]/modelarray[,,1])-1),2,quantile,pctile[p]/100,na.rm=T)
    meanchange[,g,p,2]=apply(modelarray[,,g+4],2,quantile,pctile[p]/100,na.rm=T)
    
    
    fname=paste0(var,"_AGCD-05i_MM",pctile[p],"_",ssp,"_v1-r1_GWL",gwl[g+1],"_change.nc")
    
    a=nc_open(paste0(indir,fname))
    tmp=ncvar_get(a,var2)
    for(r in 1:length(regnames)) meanchange[r,g,p,3]=mean(tmp*regmask[,,r],na.rm=T)
  }

t(meanchange[1,3,,])

agreement=array(0,c(length(regnames),3,3))
dimnames(agreement)=list(regnames,gwl[2:4],c("Region.Mean.then.Change","Model.Change.Then.Mean","Cookie-cutter"))

for(g in 1:3)
{
  tmp=100*((modelarray[1:ind,,g+1]/modelarray[1:ind,,1])-1)
  agreement[,g,1]=apply(tmp>0,2,mean)
  agreement[,g,2]=apply(modelarray[1:ind,,g+4]>0,2,mean)
}

agreement[,,1]>0.65 | agreement[,,1]<0.35


#Table data
tmp=cbind(apply(modelarray[1:ind,,1],2,median),
          meanchange[,,1,2],
          agreement[,2,2],
          meanchange[,2,3,2])

for(i in 1:3)
{
  I=which(agreement[,i,2]<0.65 & agreement[,i,2]>0.35)
  tmp[I,i+1]=NaN
}







