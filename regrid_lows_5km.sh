!/bin/sh
# Get all the RX1H and RX1D

dir=/scratch/eg3/asp561/NCRA/
export RUNSTAT_DATE last

agency=('BOM' 'BOM' 'BOM' 'BOM' 'BOM' 'BOM' 'BOM' 'CSIRO' 'CSIRO' 'CSIRO' 'CSIRO' 'CSIRO' 'CSIRO' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES')
model=('ACCESS-CM2' 'ACCESS-ESM1-5' 'CESM2' 'CMCC-ESM2' 'EC-Earth3' 'MPI-ESM1-2-HR' 'NorESM2-MM' 'ACCESS-CM2' 'ACCESS-ESM1-5' 'CESM2' 'CMCC-ESM2' 'CNRM-ESM2-1' 'EC-Earth3' 'ACCESS-CM2' 'ACCESS-ESM1-5' 'ACCESS-ESM1-5' 'ACCESS-ESM1-5' 'CMCC-ESM2' 'CNRM-CM6-1-HR' 'CNRM-CM6-1-HR' 'EC-Earth3' 'FGOALS-g3' 'GFDL-ESM4' 'GISS-E2-1-G' 'MPI-ESM1-2-LR' 'MRI-ESM2-0' 'NorESM2-MM' 'NorESM2-MM')
member=('r4i1p1f1' 'r6i1p1f1' 'r11i1p1f1' 'r1i1p1f1' 'r1i1p1f1' 'r1i1p1f1' 'r1i1p1f1' 'r4i1p1f1' 'r6i1p1f1' 'r11i1p1f1' 'r1i1p1f1' 'r1i1p1f2' 'r1i1p1f1' 'r2i1p1f1' 'r20i1p1f1' 'r40i1p1f1' 'r6i1p1f1' 'r1i1p1f1' 'r1i1p1f2' 'r1i1p1f2' 'r1i1p1f1' 'r4i1p1f1' 'r1i1p1f1' 'r2i1p1f2' 'r9i1p1f1' 'r1i1p1f1' 'r1i1p1f1' 'r1i1p1f1')
rcm=('BARPA-R' 'BARPA-R' 'BARPA-R' 'BARPA-R' 'BARPA-R' 'BARPA-R' 'BARPA-R' 'CCAM-v2203-SN' 'CCAM-v2203-SN' 'CCAM-v2203-SN' 'CCAM-v2203-SN' 'CCAM-v2203-SN' 'CCAM-v2203-SN' 'CCAMoc-v2112' 'CCAMoc-v2112' 'CCAMoc-v2112' 'CCAM-v2105' 'CCAM-v2105' 'CCAMoc-v2112' 'CCAM-v2112' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAMoc-v2112' 'CCAM-v2112')
version=v1-r1
ssp=ssp370

for m in {0..12} ; do

if [[ $m -lt 7 ]]; then
 sdir="BARPA"
else
 sdir="CCAM"
fi

fin=$sdir/lows_${sdir}_${model[$m]}_${ssp}.nc
fout=5km/lows_AGCD-05i_${model[$m]}_${ssp}_${member[$m]}_${agency[$m]}_${rcm[$m]}_${version}_annual.nc

cdo yearmean ${dir}/${fin} ${dir}/tmp.nc
cdo remapbil,/g/data/eg3/asp561/Shapefiles/awapgrid ${dir}/tmp.nc ${dir}/${fout}
rm ${dir}/tmp.nc

done



