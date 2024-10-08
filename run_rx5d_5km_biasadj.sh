#!/bin/sh
# Get all the RX1H and RX1D

dir=/g/data/ia39/australian-climate-service/test-data/CORDEX-CMIP6/bias-adjustment-output/AGCD-05i/
odir=/scratch/eg3/asp561/NCRA/bias-adjusted/
export RUNSTAT_DATE=last

agency=('BOM' 'BOM' 'BOM' 'BOM' 'BOM' 'BOM' 'BOM' 'CSIRO' 'CSIRO' 'CSIRO' 'CSIRO' 'CSIRO' 'CSIRO' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'UQ-DES' 'CSIRO')
model=('ACCESS-CM2' 'ACCESS-ESM1-5' 'CESM2' 'CMCC-ESM2' 'EC-Earth3' 'MPI-ESM1-2-HR' 'NorESM2-MM' 'ACCESS-CM2' 'ACCESS-ESM1-5' 'CESM2' 'CMCC-ESM2' 'CNRM-ESM2-1' 'EC-Earth3' 'ACCESS-CM2' 'ACCESS-ESM1-5' 'ACCESS-ESM1-5' 'ACCESS-ESM1-5' 'CMCC-ESM2' 'CNRM-CM6-1-HR' 'CNRM-CM6-1-HR' 'EC-Earth3' 'FGOALS-g3' 'GFDL-ESM4' 'GISS-E2-1-G' 'MPI-ESM1-2-LR' 'MRI-ESM2-0' 'NorESM2-MM' 'NorESM2-MM' 'NorESM2-MM')
member=('r4i1p1f1' 'r6i1p1f1' 'r11i1p1f1' 'r1i1p1f1' 'r1i1p1f1' 'r1i1p1f1' 'r1i1p1f1' 'r4i1p1f1' 'r6i1p1f1' 'r11i1p1f1' 'r1i1p1f1' 'r1i1p1f2' 'r1i1p1f1' 'r2i1p1f1' 'r20i1p1f1' 'r40i1p1f1' 'r6i1p1f1' 'r1i1p1f1' 'r1i1p1f2' 'r1i1p1f2' 'r1i1p1f1' 'r4i1p1f1' 'r1i1p1f1' 'r2i1p1f2' 'r9i1p1f1' 'r1i1p1f1' 'r1i1p1f1' 'r1i1p1f1' 'r1i1p1f1')
rcm=('BARPA-R' 'BARPA-R' 'BARPA-R' 'BARPA-R' 'BARPA-R' 'BARPA-R' 'BARPA-R' 'CCAM-v2203-SN' 'CCAM-v2203-SN' 'CCAM-v2203-SN' 'CCAM-v2203-SN' 'CCAM-v2203-SN' 'CCAM-v2203-SN' 'CCAMoc-v2112' 'CCAMoc-v2112' 'CCAMoc-v2112' 'CCAM-v2105' 'CCAM-v2105' 'CCAMoc-v2112' 'CCAM-v2112' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAM-v2105' 'CCAMoc-v2112' 'CCAM-v2112' 'CCAM-v2203-SN')

ssp=historical

for method in QME ; do
version=v1-r1-ACS-${method}-AGCD-1960-2022

for m in {28..28} ; do

yend=1231
indir=${dir}/${agency[$m]}/${model[$m]}/${ssp}/${member[$m]}/${rcm[$m]}/$version/day/prAdjust/
fname=${model[$m]}_${ssp}_${member[$m]}_${agency[$m]}_${rcm[$m]}_${version}

for year in {1960..2014}; do
 cdo timmax $indir/prAdjust_AGCD-05i_${fname}*${year}${yend}.nc $odir/tmp_RX1D_${year}.nc

 if [[ $year -eq 1960 ]]; then
  cp $indir/prAdjust_AGCD-05i_${fname}*${year}${yend}.nc $odir/tmp1.nc
 else
  cdo mergetime $indir/prAdjust_AGCD-05i_${fname}*${year}${yend}.nc $indir/prAdjust_AGCD-05i_${fname}*$((year-1))${yend}.nc $odir/tmp1.nc
 fi

 cdo -yearmax -selyear,${year} -runsum,5 $odir/tmp1.nc $odir/tmp_RX5D_${year}.nc 
 rm $odir/tmp1.nc
done
cdo mergetime $odir/tmp_RX5D_*.nc $odir/RX5D_AGCD-05i_${fname}_annual.nc
cdo mergetime $odir/tmp_RX1D_*.nc $odir/RX1D_AGCD-05i_${fname}_annual.nc

rm $odir/tmp*.nc
done
done


