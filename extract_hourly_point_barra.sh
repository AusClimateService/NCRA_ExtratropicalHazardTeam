!/bin/sh
# Get all the FFDI

dir=/g/data/ob53/BARRA2/output/reanalysis/AUS-11/BOM/ERA5/historical/hres/BARRA-R2/v1/1hr/pr/v20231001/
odir=/scratch/eg3/asp561/BARRA2/

for year in {1991..2021}; do
for month in 01 02 03 04 05 06 07 08 09 10 11 12 ; do

ncks -v pr -d lon,151.17 -d lat,-33.95 ${dir}/pr_AUS-11_ERA5_historical_hres_BOM_BARRA-R2_v1_1hr_${year}${month}*.nc  ${odir}/sydneyAP_${year}${month}_ncks.nc

ncks -v pr -d lon,130.99 -d lat,-12.42 ${dir}/pr_AUS-11_ERA5_historical_hres_BOM_BARRA-R2_v1_1hr_${year}${month}*.nc  ${odir}/darwinAP_${year}${month}.nc

ncks -v pr -d lon,138.62 -d lat,-34.92 ${dir}/pr_AUS-11_ERA5_historical_hres_BOM_BARRA-R2_v1_1hr_${year}${month}*.nc  ${odir}/adelaideKT_${year}${month}.nc

done
done

cdo mergetime ${odir}/sydneyAP_??????.nc ${odir}/sydneyAP_hourlypr.nc
rm ${odir}/sydneyAP_??????.nc

cdo mergetime ${odir}/darwinAP_??????.nc ${odir}/darwinAP_hourlypr.nc
rm ${odir}/darwinAP_hourlypr.nc

cdo mergetime ${odir}/adelaideKT_??????.nc ${odir}/adelaideKT_hourlypr.nc
rm ${odir}/adelaideKT_??????.nc

