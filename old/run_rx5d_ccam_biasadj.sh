!/bin/sh
# Get all the RX1H and RX1D

dir=/g/data/ia39/australian-climate-service/test-data/CORDEX-CMIP6/bias-adjustment-output/AGCD-05i/CSIRO/
export RUNSTAT_DATE last

#ssp=evaluation
#for model in ECMWF-ERA5 ; do
#for year in {1979..2020}; do
# cdo timmax ${dir}/${model}/${ssp}/*/BOM-CCAM-v2203-SN/v1/1hr/pr/pr_AUS-15_${model}_*_1hr_${year}01-*.nc /scratch/eg3/asp561/CCAM/RX1H_CCAM_${model}_${ssp}_${year}.nc
#done
#done

ssp=ssp370
for model in CMCC-ESM2 ACCESS-ESM1-5 ACCESS-CM2 CESM2 EC-Earth3 CNRM-ESM2-1 ; do
for year in {2015..2099}; do

 cdo timmax ${dir}/${model}/${ssp}/*/CCAM-v2203-SN/v1-r1-ACS-QME-AGCD-1960-2022/day/prAdjust/prAdjust_AGCD-05i_*${year}1231.nc /scratch/eg3/asp561/NCRA/CCAM/tmp_RX1D_CCAM-QME_${model}_${ssp}_${year}.nc

 if [[ $year -eq 2015 ]]; then
  cp ${dir}/${model}/${ssp}/*/CCAM-v2203-SN/v1-r1-ACS-QME-AGCD-1960-2022/day/prAdjust/prAdjust_AGCD-05i_*${year}1231.nc /scratch/eg3/asp561/NCRA/CCAM/tmp1.nc
 else
  cdo mergetime ${dir}/${model}/${ssp}/*/CCAM-v2203-SN/v1-r1-ACS-QME-AGCD-1960-2022/day/prAdjust/prAdjust_AGCD-05i_*${year}1231.nc ${dir}/${model}/${ssp}/*/CCAM-v2203-SN/v1-r1-ACS-QME-AGCD-1960-2022/day/prAdjust/prAdjust_AGCD-05i_*$((year-1))1231.nc /scratch/eg3/asp561/NCRA/CCAM/tmp1.nc
 fi

 cdo -yearmax -selyear,${year} -runsum,5 /scratch/eg3/asp561/NCRA/CCAM/tmp1.nc /scratch/eg3/asp561/NCRA/CCAM/tmp_RX5D_${year}.nc
 rm /scratch/eg3/asp561/NCRA/CCAM/tmp1.nc
done
cdo mergetime /scratch/eg3/asp561/NCRA/CCAM/tmp_RX1D_CCAM-QME_${model}_${ssp}_????.nc  /scratch/eg3/asp561/NCRA/CCAM/QME/RX1D_CCAM-QME-AGCD_${model}_${ssp}.nc
 cdo mergetime /scratch/eg3/asp561/NCRA/CCAM/tmp_RX5D_????.nc /scratch/eg3/asp561/NCRA/CCAM/QME/RX5D_CCAM-QME-AGCD_${model}_${ssp}.nc

 rm /scratch/eg3/asp561/NCRA/CCAM/tmp_RX5D_????.nc
 rm /scratch/eg3/asp561/NCRA/CCAM/tmp_RX1D_CCAM-QME_${model}_${ssp}_????.nc 
done

#ssp=ssp370
#for model in CMCC-CMCC-ESM2 CSIRO-ACCESS-ESM1-5 CSIRO-ARCCSS-ACCESS-CM2 EC-Earth-Consortium-EC-Earth3 MPI-M-MPI-ESM1-2-HR NCAR-CESM2 NCC-NorESM2-MM ; do
#for year in {2015..2060}; do
# cdo timmax ${dir}/${model}/${ssp}/*/BOM-CCAM-v2203-SN/v1/1hr/pr/pr_AUS-15_${model}_*_1hr_${year}01-*.nc /scratch/eg3/asp561/CCAM/RX1H_CCAM_${model}_${ssp}_${year}.nc
#done
#done



