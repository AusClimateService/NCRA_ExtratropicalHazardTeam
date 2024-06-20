!/bin/sh
# Get all the RX1H and RX1D

export RUNSTAT_DATE last

dir=/g/data/ig45/QldFCP-2/CORDEX/CMIP6/DD/AUS-20i/UQ-DES/
#ssp=evaluation
#for model in ECMWF-ERA5 ; do
#for year in {1979..2020}; do
# cdo timmax ${dir}/${model}/${ssp}/*/BOM-CCAM-UQ-DES-R/v1/1hr/pr/pr_AUS-15_${model}_*_1hr_${year}01-*.nc /scratch/eg3/asp561/CCAM-UQ-DES/RX1H_CCAM-QLD_${model}_${ssp}_${year}.nc
#done
#done

model=('ACCESS-CM2' 'ACCESS-ESM1-5' 'ACCESS-ESM1-5' 'ACCESS-ESM1-5' 'CMCC-ESM2' 'CNRM-CM6-1-HR' 'CNRM-CM6-1-HR' 'EC-Earth3' 'FGOALS-g3' 'GFDL-ESM4' 'GISS-E2-1-G' 'MPI-ESM1-2-LR' 'MRI-ESM2-0' 'NorESM2-MM' 'NorESM2-MM')
member=('r2i1p1f1' 'r20i1p1f1' 'r40i1p1f1' 'r6i1p1f1' 'r1i1p1f1' 'r1i1p1f2' 'r1i1p1f2' 'r1i1p1f1' 'r4i1p1f1' 'r1i1p1f1' 'r2i1p1f2' 'r9i1p1f1' 'r1i1p1f1' 'r1i1p1f1' 'r1i1p1f1')
version=('CCAMoc-v2112' 'CCAMoc-v2112' 'CCAMoc-v2112' 'CCAM-v2105' 'CCAM-v2105' 'CCAMoc-v2112' 'CCAM-v2112' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAMoc-v2112' 'CCAM-v2112')

ssp=historical
for m in {0..14} ; do
#for model in CMCC-ESM2 ACCESS-ESM1-5 ACCESS-CM2 EC-Earth3 MPI-ESM1-2-HR CESM2 NorESM2-MM ; do
for year in {1960..2014}; do
 if [[ $year -eq 1960 ]]; then
   cp ${dir}/${model[$m]}/${ssp}/${member[$m]}/${version[$m]}/v1-r1/day/pr/v20231215/pr_AUS-20i_*${year}1231.nc /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp1.nc
 else
   cdo mergetime ${dir}/${model[$m]}/${ssp}/${member[$m]}/${version[$m]}/v1-r1/day/pr/v20231215/pr_AUS-20i_*$((year-1))1231.nc ${dir}/${model[$m]}/${ssp}/${member[$m]}/${version[$m]}/v1-r1/day/pr/v20231215/pr_AUS-20i_*${year}1231.nc /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp1.nc
 fi

 cdo -yearmax -selyear,${year} -runsum,5 /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp1.nc /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp_RX5D_${year}.nc
 rm /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp1.nc
done

 cdo mergetime /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp_RX5D_????.nc /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp1.nc
cdo mulc,86400 /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp1.nc /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp2.nc
 cdo -setattribute,pr@units=mm /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp2.nc /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/RX5D_CCAM-QLD_${model[$m]}_${member[$m]}_${version[$m]}_${ssp}_${year}.nc
 rm /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp?.nc

 rm /scratch/eg3/asp561/NCRA/CCAM-UQ-DES/tmp_RX5D_????.nc 
done

#ssp=ssp370
#for model in CMCC-CMCC-ESM2 CSIRO-ACCESS-ESM1-5 CSIRO-ARCCSS-ACCESS-CM2 EC-Earth-Consortium-EC-Earth3 MPI-M-MPI-ESM1-2-HR NCAR-CESM2 NCC-NorESM2-MM ; do
#for year in {2015..2060}; do
# cdo timmax ${dir}/${model}/${ssp}/*/BOM-CCAM-UQ-DES-R/v1/1hr/pr/pr_AUS-15_${model}_*_1hr_${year}01-*.nc /scratch/eg3/asp561/CCAM-UQ-DES/RX1H_CCAM-UQ-DES_${model}_${ssp}_${year}.nc
#done
#done



