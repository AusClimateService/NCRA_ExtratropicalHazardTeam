!/bin/sh
# Get all the RX1H and RX1D
dir=/g/data/hq89/CCAM/output/CMIP6/DD/AUS-10i/CSIRO/
#ssp=evaluation
#for model in ECMWF-ERA5 ; do
#for year in {1979..2020}; do
# cdo timmax ${dir}/${model}/${ssp}/*/BOM-CCAM-R/v1/1hr/pr/pr_AUS-15_${model}_*_1hr_${year}01-*.nc /scratch/eg3/asp561/CCAM/RX1H_CCAM_${model}_${ssp}_${year}.nc
#done
#done


ssp=evaluation
for model in ERA5 ; do
#for model in CMCC-ESM2 ACCESS-ESM1-5 ACCESS-CM2 CESM2 EC-Earth3 CNRM-ESM2-1 ; do
for year in {1979..2020}; do
 cdo timmax ${dir}/${model}/${ssp}/*/CCAM-v2203-SN/v1-r1/day/prhmax/v20231206/prhmax_AUS-10i_${model}_*_day_${year}0101-*.nc /scratch/eg3/asp561/NCRA/CCAM/RX1H_CCAM_${model}_${ssp}_${year}.nc
 cdo timmax ${dir}/${model}/${ssp}/*/CCAM-v2203-SN/v1-r1/day/pr/v20231206//pr_AUS-10i_${model}_*_day_${year}0101-*.nc /scratch/eg3/asp561/NCRA/CCAM/RX1D_CCAM_${model}_${ssp}_${year}.nc
done

cdo mergetime /scratch/eg3/asp561/NCRA/CCAM/RX1H_CCAM_${model}_${ssp}_????.nc  /scratch/eg3/asp561/NCRA/CCAM/tmp1.nc
cdo mulc,3600 /scratch/eg3/asp561/NCRA/CCAM/tmp1.nc /scratch/eg3/asp561/NCRA/CCAM/tmp2.nc
 cdo -setattribute,prhmax@units=mm /scratch/eg3/asp561/NCRA/CCAM/tmp2.nc  /scratch/eg3/asp561/NCRA/CCAM/RX1H_CCAM_${model}_${ssp}.nc
rm /scratch/eg3/asp561/NCRA/CCAM/tmp?.nc

cdo mergetime /scratch/eg3/asp561/NCRA/CCAM/RX1D_CCAM_${model}_${ssp}_????.nc  /scratch/eg3/asp561/NCRA/CCAM/tmp1.nc
cdo mulc,86400 /scratch/eg3/asp561/NCRA/CCAM/tmp1.nc /scratch/eg3/asp561/NCRA/CCAM/tmp2.nc
 cdo -setattribute,pr@units=mm /scratch/eg3/asp561/NCRA/CCAM/tmp2.nc  /scratch/eg3/asp561/NCRA/CCAM/RX1D_CCAM_${model}_${ssp}.nc
rm /scratch/eg3/asp561/NCRA/CCAM/tmp?.nc

rm /scratch/eg3/asp561/NCRA/CCAM/RX1?_CCAM_${model}_${ssp}_????.nc
done




