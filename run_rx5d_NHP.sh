!/bin/sh
# Get all the RX1H and RX1D

dir=/g/data/wj02/COMPLIANT_PUBLISHED/HMINPUT/output/AUS-5/BoM/
odir=/scratch/eg3/asp561/NCRA/NHP/
export RUNSTAT_DATE last
member=r1i1p1

for ssp in historical rcp85 ; do
for model in CNRM-CERFACS-CNRM-CM5 CSIRO-BOM-ACCESS1-0 MIROC-MIROC5 NOAA-GFDL-GFDL-ESM2M ; do
for bc in r240x120-QME-AWAP r240x120-MRNBC-AWAP r240x120-ISIMIP2b-AWAP r240x120-BEFOREBC-AWAP CSIRO-CCAM-r3355-r240x120-ISIMIP2b-AWAP CSIRO-CCAM-r3355-r240x120-BEFOREBC-AWAP ; do

 fdir=${dir}/${model}/${ssp}/${member}/${bc}/latest/day/pr/
 fname=AUS-5_${model}_${ssp}_${member}_${bc}

 cdo yearmax ${fdir}/pr_${fname}*.nc ${odir}/tmp1.nc
 cdo mulc,86400 ${odir}/tmp1.nc ${odir}/tmp2.nc
 cdo -setattribute,pr@units=mm ${odir}/tmp2.nc ${odir}/RX1D_${fname}_annual.nc
 rm ${odir}/tmp*.nc

 cdo -yearmax -runsum,5 ${fdir}/pr_${fname}*.nc ${odir}/tmp1.nc
 cdo mulc,86400 ${odir}/tmp1.nc ${odir}/tmp2.nc
 cdo -setattribute,pr@units=mm ${odir}/tmp2.nc ${odir}/RX5D_${fname}_annual.nc
 rm ${odir}/tmp*.nc
done
done
done


