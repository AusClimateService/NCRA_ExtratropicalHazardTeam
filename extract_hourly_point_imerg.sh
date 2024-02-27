!/bin/sh
# Get all the FFDI

dir=/g/data/ia39/aus-ref-clim-data-nci/gpm/data/V07/
odir=/scratch/eg3/asp561/IMERG/

for year in {2001..2022}; do
ii=0
for f in $dir/${year}/*.nc ; do

ncks -v precipitation -d lon,151.17 -d lat,-33.95 $f ${odir}/sydneyAP_tmp${ii}.nc
ncks -v precipitation -d lon,130.99 -d lat,-12.42 $f ${odir}/darwinAP_tmp${ii}.nc
ncks -v precipitation -d lon,138.62 -d lat,-34.92 $f ${odir}//adelaideKT_tmp${ii}.nc

ii=$((ii+1))
done

cdo mergetime ${odir}/darwinAP_tmp*.nc ${odir}/darwinAP_${year}.nc
cdo mergetime ${odir}/sydneyAP_tmp*.nc ${odir}/sydneyAP_${year}.nc
cdo mergetime ${odir}/adelaideKT_tmp*.nc ${odir}/adelaideKT_${year}.nc

rm ${odir}/*_tmp*.nc

done

 cdo -outputtab,date,time,lon,lat,value -mergetime ${odir}/sydneyAP_????.nc > ${odir}/sydneyAP_30mprecip.nc 
 cdo -outputtab,date,time,lon,lat,value -mergetime ${odir}/adelaideKT_????.nc > ${odir}/adelaideKT_30mprecip.nc
 cdo -outputtab,date,time,lon,lat,value -mergetime ${odir}/darwinAP_????.nc > ${odir}/darwinAP_30mprecip.nc


