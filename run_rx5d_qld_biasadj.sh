!/bin/sh
# Get all the RX1H and RX1D

dir=/g/data/ia39/australian-climate-service/test-data/CORDEX-CMIP6/bias-adjustment-output/AGCD-05i/UQ-DES/
export RUNSTAT_DATE last

#ssp=evaluation
#for model in ECMWF-ERA5 ; do
#for year in {1979..2020}; do
# cdo timmax ${dir}/${model}/${ssp}/*/BOM-CCAM-v2203-SN/v1/1hr/pr/pr_AUS-15_${model}_*_1hr_${year}01-*.nc /scratch/eg3/asp561/CCAM/RX1H_CCAM-QLD_${model}_${ssp}_${year}.nc
#done
#done



model=('ACCESS-CM2' 'ACCESS-ESM1-5' 'ACCESS-ESM1-5' 'ACCESS-ESM1-5' 'CMCC-ESM2' 'CNRM-CM6-1-HR' 'CNRM-CM6-1-HR' 'EC-Earth3' 'FGOALS-g3' 'GFDL-ESM4' 'GISS-E2-1-G' 'MPI-ESM1-2-LR' 'MRI-ESM2-0' 'NorESM2-MM' 'NorESM2-MM')
member=('r2i1p1f1' 'r20i1p1f1' 'r40i1p1f1' 'r6i1p1f1' 'r1i1p1f1' 'r1i1p1f2' 'r1i1p1f2' 'r1i1p1f1' 'r4i1p1f1' 'r1i1p1f1' 'r2i1p1f2' 'r9i1p1f1' 'r1i1p1f1' 'r1i1p1f1' 'r1i1p1f1')
version=('CCAMoc-v2112' 'CCAMoc-v2112' 'CCAMoc-v2112' 'CCAM-v2105' 'CCAM-v2105' 'CCAMoc-v2112' 'CCAM-v2112' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAMoc-v2112' 'CCAM-v2112')

ssp=historical
for m in {0..14} ; do
for year in {1960..2014}; do

 cdo timmax ${dir}/${model[$m]}/${ssp}/${member[$m]}/${version[$m]}/v1-r1-ACS-QME-AGCD-1960-2022/day/prAdjust/prAdjust_AGCD-05i_*${year}1231.nc /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp_RX1D_CCAM-QLD-QME_${model}_${ssp}_${year}.nc

 if [[ $year -eq 1960 ]]; then
  cp ${dir}/${model[$m]}/${ssp}/${member[$m]}/${version[$m]}/v1-r1-ACS-QME-AGCD-1960-2022/day/prAdjust/prAdjust_AGCD-05i_*${year}1231.nc /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp1.nc
 else
  cdo mergetime ${dir}/${model[$m]}/${ssp}/${member[$m]}/${version[$m]}/v1-r1-ACS-QME-AGCD-1960-2022/day/prAdjust/prAdjust_AGCD-05i_*${year}1231.nc ${dir}/${model[$m]}/${ssp}/${member[$m]}/${version[$m]}/v1-r1-ACS-QME-AGCD-1960-2022/day/prAdjust/prAdjust_AGCD-05i_*$((year-1))1231.nc /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp1.nc
 fi

 cdo -yearmax -selyear,${year} -runsum,5 /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp1.nc /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp_RX5D_${year}.nc
 rm /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp1.nc
done
cdo mergetime /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp_RX1D_CCAM-QLD_${model}_${ssp}_????.nc  /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/QME/RX1D_CCAM-QLD-QME-AGCD_${model}_${ssp}.nc
 cdo mergetime /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp_RX5D_????.nc /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/QME/RX5D_CCAM-QLD-QME-AGCD_${model}_${ssp}.nc

 rm /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp_RX5D_????.nc
 rm /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp_RX1D_CCAM-QLD_${model}_${ssp}_????.nc 
done

#ssp=ssp370
#for model in CMCC-CMCC-ESM2 CSIRO-ACCESS-ESM1-5 CSIRO-ARCCSS-ACCESS-CM2 EC-Earth-Consortium-EC-Earth3 MPI-M-MPI-ESM1-2-HR NCAR-CESM2 NCC-NorESM2-MM ; do
#for year in {2015..2060}; do
# cdo timmax ${dir}/${model}/${ssp}/*/BOM-CCAM-v2203-SN/v1/1hr/pr/pr_AUS-15_${model}_*_1hr_${year}01-*.nc /scratch/eg3/asp561/CCAM/RX1H_CCAM-QLD_${model}_${ssp}_${year}.nc
#done
#done



