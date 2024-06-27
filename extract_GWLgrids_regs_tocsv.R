library(ncdf4)

agency=c('BOM','BOM','BOM','BOM','BOM','BOM','BOM','CSIRO','CSIRO','CSIRO','CSIRO','CSIRO','CSIRO','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES','UQ-DES')
model=c('ACCESS-CM2','ACCESS-ESM1-5','CESM2','CMCC-ESM2','EC-Earth3','MPI-ESM1-2-HR','NorESM2-MM','ACCESS-CM2','ACCESS-ESM1-5','CESM2','CMCC-ESM2','CNRM-ESM2-1','EC-Earth3','ACCESS-CM2','ACCESS-ESM1-5','ACCESS-ESM1-5','ACCESS-ESM1-5','CMCC-ESM2','CNRM-CM6-1-HR','CNRM-CM6-1-HR','EC-Earth3','FGOALS-g3','GFDL-ESM4','GISS-E2-1-G','MPI-ESM1-2-LR','MRI-ESM2-0','NorESM2-MM','NorESM2-MM')
member=c('r4i1p1f1','r6i1p1f1','r11i1p1f1','r1i1p1f1','r1i1p1f1','r1i1p1f1','r1i1p1f1','r4i1p1f1','r6i1p1f1','r11i1p1f1','r1i1p1f1','r1i1p1f2','r1i1p1f1','r2i1p1f1','r20i1p1f1','r40i1p1f1','r6i1p1f1','r1i1p1f1','r1i1p1f2','r1i1p1f2','r1i1p1f1','r4i1p1f1','r1i1p1f1','r2i1p1f2','r9i1p1f1','r1i1p1f1','r1i1p1f1','r1i1p1f1')
rcm=c('BARPA-R','BARPA-R','BARPA-R','BARPA-R','BARPA-R','BARPA-R','BARPA-R','CCAM-v2203-SN','CCAM-v2203-SN','CCAM-v2203-SN','CCAM-v2203-SN','CCAM-v2203-SN','CCAM-v2203-SN','CCAMoc-v2112','CCAMoc-v2112','CCAMoc-v2112','CCAM-v2105','CCAM-v2105','CCAMoc-v2112','CCAM-v2112','CCAM-v2105','CCAM-v2105','CCAM-v2105','CCAM-v2105','CCAM-v2105','CCAM-v2105','CCAMoc-v2112','CCAM-v2112')

regnames=c("australia","southern_australia","northern_australia","WA_North","WA_South","NSW","VIC","SA","TAS","NT","QLD_North","QLD_South")

a=nc_open("/g/data/eg3/asp561/Shapefiles/mask_australia_0.05deg.nc")
mask=ncvar_get(a,"landmask")
mask[mask==0]=NaN
lon=ncvar_get(a,"longitude")
lat=ncvar_get(a,"latitude")
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

for(r in 4:length(regnames))
{
  a=nc_open(paste0(rdir,"/mask_NCRA_",regnames[r],"_0.05deg.nc"))
  mask=ncvar_get(a,"landmask")
  mask[mask==0]=NaN
  regmask[,,r]=mask
}

#odir="/scratch/eg3/asp561/NCRA/5km/GWLs/"
indir="/g/data/ia39/ncra/extratropical_storms/5km/GWLs/"
odir=indir
ssp="ssp370"
gwl=c(15,20,30)
pctile=c(50,10,90)

var="RX1D"
var2="pr"

regarray=array(0,c(length(gwl),length(regnames),length(pctile),3))
dimnames(regarray)=list(paste0("GWL",gwl),regnames,paste0("MM",pctile),c("Mean","Min","Max"))

for(i in 1:length(gwl))
for(j in 1:length(pctile))
{
 fname=paste0(var,"_AGCD-05i_MM",pctile[j],"_",ssp,"_v1-r1_GWL",gwl[i],"_change.nc")
 a=nc_open(paste0(indir,fname))
 tmp=ncvar_get(a,var2)

 for(r in 1:length(regnames))
  {
  regarray[i,r,j,1]=mean(tmp*regmask[,,r],na.rm=T)
  regarray[i,r,j,2]=min(tmp*regmask[,,r],na.rm=T)
  regarray[i,r,j,3]=max(tmp*regmask[,,r],na.rm=T)
  }
  nc_close(a)
}

library(reshape)
for(r in 1:length(regnames))
{
tmp=melt(regarray[,r,,]) # Maybe this is what I save?
colnames(tmp)=c("GWL","Percentile","Summary.Statistic","% change relative to GWL1.2")
write.csv(tmp,paste0(odir,"/regional_means/",var,"_AGCD-05i_ACS_",ssp[2],"_v1-r1_GWLs_",regnames[r],".csv"),row.names=F)
}
#Need to rewrite the writing code

#for(r in 1:length(regnames))
#  write.csv(GWLarray[,,r],paste0(fdir,"/regional_means/",var,"_AGCD-05i_ACS_",ssp[2],"_v1-r1_GWLs_",regnames[r],".csv"))








