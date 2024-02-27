!/bin/sh
# Get all the FFDI

dir=/g/data/ob53/BARRA2/output/reanalysis/AUS-11/BOM/ERA5/historical/hres/BARRA-R2/v1/1hr/pr/v20231001/
odir=/scratch/eg3/asp561/BARRA2/

for year in {1991..2022}; do
for month in 01 02 03 04 05 06 07 08 09 10 11 12 ; do
 cdo timmax ${dir}/pr_AUS-11_ERA5_historical_hres_BOM_BARRA-R2_v1_1hr_${year}${month}*.nc ${odir}/tmp_${year}${month}.nc
done

 cdo mergetime ${odir}/tmp_${year}??.nc ${odir}/RX1H_BARRA_monthly_${year}.nc
 rm ${odir}/tmp_${year}??.nc
done




