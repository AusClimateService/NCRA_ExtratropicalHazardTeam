#!/bin/sh
# Get all the RX1H and RX1D

dir=/g/data/ia39/australian-climate-service/test-data/CORDEX-CMIP6/bias-adjustment-input/AGCD-05i/
odir=/scratch/eg3/asp561/NCRA/5km/
export RUNSTAT_DATE=last

agency=BOM
model=ERA5
ssp=historical
member=hres
rcm=BARRA-R2
version=v1

indir=${dir}/${agency[$m]}/${model[$m]}/${ssp}/${member[$m]}/${rcm[$m]}/$version/day/pr/
fname=${model[$m]}_${ssp}_${member[$m]}_${agency[$m]}_${rcm[$m]}_${version}

for year in {1979..2022}; do
 cdo mergetime ${indir}/pr_AGCD-05i_${fname}_*${year}??.nc ${indir}/pr_AGCD-05i_${fname}_*$((year-1))12.nc $odir/tmp1.nc

 cdo -yearmax -selyear,${year} $odir/tmp1.nc $odir/tmp_RX1D_${year}.nc
 cdo -yearmax -selyear,${year} -runsum,5 $odir/tmp1.nc $odir/tmp_RX5D_${year}.nc 
 rm $odir/tmp1.nc
done
cdo mergetime $odir/tmp_RX5D_*.nc $odir/RX5D_AGCD-05i_${fname}_annual.nc
cdo mergetime $odir/tmp_RX1D_*.nc $odir/RX1D_AGCD-05i_${fname}_annual.nc

rm $odir/tmp*.nc



