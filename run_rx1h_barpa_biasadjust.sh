#!/bin/sh
# Get all the RX1H and RX1D

dir=/g/data/py18/BARPA/output/CMIP6/DD/AUS-15/BOM/

bdir=/g/data/ia39/australian-climate-service/test-data/CORDEX-CMIP6/bias-adjustment-output/AGCD-05i/
odir=/scratch/eg3/asp561/NCRA/bias-adjusted/

agency=('BOM' 'BOM' 'BOM' 'BOM' 'BOM' 'BOM' 'BOM' 'CSIRO' 'CSIRO' 'CSIRO' 'CSIRO' 'CSIRO' 'CSIRO' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES')
model=('ACCESS-CM2' 'ACCESS-ESM1-5' 'CESM2' 'CMCC-ESM2' 'EC-Earth3' 'MPI-ESM1-2-HR' 'NorESM2-MM' 'ACCESS-CM2' 'ACCESS-ESM1-5' 'CESM2' 'CMCC-ESM2' 'CNRM-ESM2-1' 'EC-Earth3' 'ACCESS-CM2' 'ACCESS-ESM1-5' 'ACCESS-ESM1-5' 'ACCESS-ESM1-5' 'CMCC-ESM2' 'CNRM-CM6-1-HR' 'CNRM-CM6-1-HR' 'EC-Earth3' 'FGOALS-g3' 'GFDL-ESM4' 'GISS-E2-1-G' 'MPI-ESM1-2-LR' 'MRI-ESM2-0' 'NorESM2-MM' 'NorESM2-MM')
member=('r4i1p1f1' 'r6i1p1f1' 'r11i1p1f1' 'r1i1p1f1' 'r1i1p1f1' 'r1i1p1f1' 'r1i1p1f1' 'r4i1p1f1' 'r6i1p1f1' 'r11i1p1f1' 'r1i1p1f1' 'r1i1p1f2' 'r1i1p1f1' 'r2i1p1f1' 'r20i1p1f1' 'r40i1p1f1' 'r6i1p1f1' 'r1i1p1f1' 'r1i1p1f2' 'r1i1p1f2' 'r1i1p1f1' 'r4i1p1f1' 'r1i1p1f1' 'r2i1p1f2' 'r9i1p1f1' 'r1i1p1f1' 'r1i1p1f1' 'r1i1p1f1')
rcm=('BARPA-R' 'BARPA-R' 'BARPA-R' 'BARPA-R' 'BARPA-R' 'BARPA-R' 'BARPA-R' 'CCAM-v2203-SN' 'CCAM-v2203-SN' 'CCAM-v2203-SN' 'CCAM-v2203-SN' 'CCAM-v2203-SN' 'CCAM-v2203-SN' 'CCAMoc-v2112' 'CCAMoc-v2112' 'CCAMoc-v2112' 'CCAM-v2105' 'CCAM-v2105' 'CCAMoc-v2112' 'CCAM-v2112' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAMoc-v2112' 'CCAM-v2112')

ssp=historical

for m in {0..6} ; do
yend=1231

indir=${dir}/${model[$m]}/${ssp}/${member[$m]}/${rcm[$m]}/v1-r1/day/
fname=${model[$m]}_${ssp}_${member[$m]}_${agency[$m]}_${rcm[$m]}

for year in {1960..2014} ; do
 cdo -b f32 copy ${indir}/prhmax/v20231001/prhmax_AUS-15_${fname}_v1-r1_day_${year}01*.nc ${odir}/tmp1.nc

 cdo -b f32 mulc,24 ${indir}/pr/v20231001/pr_AUS-15_${fname}_v1-r1_day_${year}01*.nc ${odir}/tmp2.nc

 cdo div ${odir}/tmp1.nc ${odir}/tmp2.nc ${odir}/tmp3.nc

 cdo remapbil,/g/data/eg3/asp561/Shapefiles/awapgrid ${odir}/tmp3.nc ${odir}/tmp4.nc

 cdo setrtoc,1,1e99,1 ${odir}/tmp4.nc ${odir}/tmp5.nc


 for method in MRNBC QME ; do
  version=v1-r1-ACS-${method}-AGCD-1960-2022
  indir2=${bdir}/${agency[$m]}/${model[$m]}/${ssp}/${member[$m]}/${rcm[$m]}/$version/day/prAdjust/

  cdo mul ${odir}/tmp5.nc ${indir2}/prAdjust_AGCD-05i_${fname}_${version}_day_${year}01*.nc ${odir}/tmp6.nc

  cdo yearmax ${odir}/tmp6.nc $odir/tmp_RX1H_${version}_${year}.nc
  rm $odir/tmp6.nc
 done
 rm $odir/tmp?.nc
done

 for method in MRNBC QME ; do
  version=v1-r1-ACS-${method}-AGCD-1960-2022
  cdo mergetime $odir/tmp_RX1H_${version}_*.nc $odir/RX1H_AGCD-05i_${fname}_${version}_annual.nc 
 done

rm $odir/tmp_RX1H_*.nc
done


