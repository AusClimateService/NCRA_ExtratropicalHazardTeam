!/bin/sh
# Get all the FFDI

dir=/scratch/eg3/ae2105/01day/r001/precip/
odir=/scratch/eg3/asp561/agcd/v2/

for year in {1991..2020}; do
for month in 01 02 03 04 05 06 07 08 09 10 11 12 ; do
 cdo mergetime ${dir}/precip_total_r001_${year}${month}*.nc $odir/tmp.nc
 cdo timmax $odir/tmp.nc ${odir}/tmp_${year}${month}.nc
 rm $odir/tmp.nc
done

 cdo mergetime ${odir}/tmp_${year}??.nc $odir/tmp2.nc
 cdo timmax $odir/tmp2.nc ${odir}/agcd_v2_precip_rx1d_r001_${year}_v2.nc
 rm ${odir}/tmp_${year}??.nc $odir/tmp2.nc
done




