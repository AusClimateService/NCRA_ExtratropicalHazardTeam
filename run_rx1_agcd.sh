!/bin/sh
# Get all the FFDI

dir=/g/data/zv2/agcd/v1-0-2/precip/total/r005/01day/
odir=/scratch/eg3/asp561/NCRA/5km/
export RUNSTAT_DATE=last

for year in {1900..2023}; do
  cdo timmax $dir/agcd_v1_precip_total_r005_daily_${year}.nc ${odir}/agcd_RX1D_${year}.nc

 if [[ $year -eq 1900 ]]; then
  cp $dir/agcd_v1_precip_total_r005_daily_${year}.nc $odir/tmp1.nc
 else
  cdo mergetime $dir/agcd_v1_precip_total_r005_daily_$((year-1)).nc $dir/agcd_v1_precip_total_r005_daily_${year}.nc $odir/tmp1.nc
 fi

 cdo -yearmax -selyear,${year} -runsum,5 $odir/tmp1.nc $odir/agcd_RX5D_${year}.nc
 rm $odir/tmp1.nc
done

cdo mergetime $odir/agcd_RX5D_*.nc $odir/RX5D_AGCD-05i_AGCD_v1-0-2_annual.nc
cdo mergetime $odir/agcd_RX1D_*.nc $odir/RX1D_AGCD-05i_AGCD_v1-0-2_annual.nc

#rm $odir/agcd_*_????.nc



