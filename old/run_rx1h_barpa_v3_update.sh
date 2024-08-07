#!/bin/sh
# Get all the RX1H and RX1D

dir=/g/data/py18/BARPA/output/CMIP6/DD/AUS-15/BOM/
#ssp=evaluation
#for model in ECMWF-ERA5 ; do
#for year in {1979..2020}; do
# cdo timmax ${dir}/${model}/${ssp}/*/BOM-BARPA-R/v1/1hr/pr/pr_AUS-15_${model}_*_1hr_${year}01-*.nc /scratch/eg3/asp561/BARPA/RX1H_BARPA_${model}_${ssp}_${year}.nc
#done
#done


ssp=ssp370
#for model in ERA5 ; do
for model in CMCC-ESM2 ACCESS-ESM1-5 ACCESS-CM2 EC-Earth3 MPI-ESM1-2-HR CESM2 NorESM2-MM ; do
fout=/scratch/eg3/asp561/NCRA/BARPA/RX1H_BARPA_${model}_${ssp}
cp ${fout}.nc ${fout}_old.nc
rm ${fout}.nc

for year in 2100 ; do
 cdo timmax ${dir}/${model}/${ssp}/*/BARPA-R/v1-r1/day/prhmax/v20231001/prhmax_AUS-15_${model}_*_day_${year}01-*.nc /scratch/eg3/asp561/NCRA/BARPA/RX1H_BARPA_${model}_${ssp}_${year}.nc
done

cdo -b F32 mulc,3600 /scratch/eg3/asp561/NCRA/BARPA/RX1H_BARPA_${model}_${ssp}_${year}.nc /scratch/eg3/asp561/NCRA/BARPA/tmp1.nc
 cdo -setattribute,prhmax@units=mm /scratch/eg3/asp561/NCRA/BARPA/tmp1.nc  /scratch/eg3/asp561/NCRA/BARPA/tmp2.nc
cdo mergetime ${fout}_old.nc /scratch/eg3/asp561/NCRA/BARPA/tmp2.nc ${fout}.nc

rm /scratch/eg3/asp561/NCRA/BARPA/tmp?.nc
rm /scratch/eg3/asp561/NCRA/BARPA/RX1?_BARPA_${model}_${ssp}_????.nc
done

#ssp=ssp370
#for model in CMCC-CMCC-ESM2 CSIRO-ACCESS-ESM1-5 CSIRO-ARCCSS-ACCESS-CM2 EC-Earth-Consortium-EC-Earth3 MPI-M-MPI-ESM1-2-HR NCAR-CESM2 NCC-NorESM2-MM ; do
#for year in {2015..2060}; do
# cdo timmax ${dir}/${model}/${ssp}/*/BOM-BARPA-R/v1/1hr/pr/pr_AUS-15_${model}_*_1hr_${year}01-*.nc /scratch/eg3/asp561/BARPA/RX1H_BARPA_${model}_${ssp}_${year}.nc
#done
#done



