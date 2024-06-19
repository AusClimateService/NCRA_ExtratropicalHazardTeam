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
I=which(lat>=-25)
tmp[,I]=NaN
regmask[,,2]=tmp

tmp=mask
I=which(lat<(-25))
tmp[,I]=NaN
regmask[,,3]=tmp

for(r in 4:length(regnames))
{
  a=nc_open(paste0(rdir,"/mask_NCRA_",regnames[r],"_0.05deg.nc"))
  mask=ncvar_get(a,"landmask")
  mask[mask==0]=NaN
  regmask[,,r]=mask
}

fdir="/scratch/eg3/asp561/NCRA/5km/"
years=1960:2099

ssp=c("historical","ssp370")
ssp2=rep("historical",length(years))
ssp2[years>=2015]="ssp370"

var="lows"
var2="low_freq"

regarray=array(0,c(length(years),length(regnames),length(agency)))
dimnames(regarray)=list(years,regnames,paste0(model,"_",member,"_",agency,"_",rcm))

for(s in 1:2)
{
Y=which(ssp2==ssp[s])

for(m in 1:13)
{
    fname=paste0(var,"_AGCD-05i_",model[m],"_",ssp[s],"_",member[m],"_",agency[m],"_",rcm[m],"_v1-r1")
    a=nc_open(paste0(fdir,fname,"_annual.nc"))
    tmp=ncvar_get(a,var2)
    
    for(r in 1:length(regnames))
      for(y in 1:length(Y))
       regarray[Y[y],r,m]=mean(tmp[,,y]*regmask[,,r],na.rm=T)
      
    nc_close(a)
}

for(r in 1:length(regnames))
  write.csv(regarray[Y,r,1:13],paste0(fdir,"/regional_means/",var,"_AGCD-05i_ACS_",ssp[s],"_v1-r1_annual_",regnames[r],".csv"))
}

### Step two - get the GWL data
### Make extra CSVs with the GWL 1.2/1.5/2/3 for each model
### As well as the ensemble median and range
### And do the same for the change factors

GWLfile=read.csv("/scratch/eg3/asp561/NCRA//cmip6_warming_levels_all_ens_1850_1900_grid.csv",skip=4,stringsAsFactors=F)
GWlist=c(1.2,1.5,2,3)
pctiles=c(50,10,90)

GWLarray=array(0,c(13+length(pctiles),length(GWlist)*2,length(regnames)))


dimnames(GWLarray)=list(c(paste0(model[1:13],"_",member[1:13],"_",agency[1:13],"_",rcm[1:13]),paste0(pctiles,"th percentile")),c("1961-1990",paste0("GWL",GWlist),paste0("%change_GWL",GWlist[-1])),regnames)

Y=which(years>=1961 & years<=1990)
GWLarray[1:13,1,]=t(apply(regarray[Y,,1:13],c(2,3),mean))

for(y in 1:length(GWlist))
 for(m in 1:13)
  {
   I=which(GWLfile$model==model[m] & trimws(GWLfile$ensemble)==member[m] & trimws(GWLfile$exp)==ssp[2] & GWLfile$warming_level==GWlist[y])
  Y=which(years>=GWLfile$start_year[I] & years<=GWLfile$end_year[I])
   GWLarray[m,y+1,]=apply(regarray[Y,,m],2,mean)
  }

for(y in 2:length(GWlist)) GWLarray[,y+4,]=100*((GWLarray[,y+1,]/GWLarray[,2,])-1)

for(p in 1:length(pctiles)) GWLarray[13+p,,]=apply(GWLarray[1:13,,],c(2,3),quantile,pctiles[p]/100)

for(r in 1:length(regnames))
  write.csv(GWLarray[,,r],paste0(fdir,"/regional_means/",var,"_AGCD-05i_ACS_",ssp[2],"_v1-r1_GWLs_",regnames[r],".csv"))








