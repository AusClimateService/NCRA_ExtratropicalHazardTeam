#!/bin/sh
# Get all the FFDI

dir=/g/data/ob53/BARRA2/output/reanalysis/AUS-11/BOM/ERA5/historical/hres/BARRA-R2/v1/1hr/pr/latest/

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
for month in 01 02 03 04 05 06 07 08 09 10 11 12 ; do
 cdo timmax ${dir}/pr_AUS-11_ERA5_historical_hres_BOM_BARRA-R2_v1_1hr_${year}${month}*.nc ${odir}/tmp_${year}${month}.nc
done

 cdo mergetime ${odir}/tmp_${year}??.nc ${odir}/tmp1.nc
 cdo timmax ${odir}/tmp1.nc ${odir}/tmp2.nc
 cdo remapbil,/g/data/eg3/asp561/Shapefiles/awapgrid ${odir}/tmp2.nc ${odir}/RX1H_BARRA_${year}.nc

 rm ${odir}/tmp*.nc
done

cdo mergetime ${odir}/RX1H_BARRA_????.nc $odir/RX1H_AGCD-05i_${fname}_annual.nc




