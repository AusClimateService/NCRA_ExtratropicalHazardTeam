# ACS Hazard Team on Extratropical Storms
Last update: 20/06/2024

## Description
GitHub repository for ACS Hazard Team on Extratropical Storms to store, track and develop code. 

## Indices considered by the hazard team:
- Proportion of observations influenced by a low (low_freq) - this indicates how often an extratropical cyclone and/or East Coast Low occurs
- Highest annual 24 hour total (RX1D) - this is the highest daily rainfall falling at each grid point in a year
- Highest annual 5-day total (RX5D) - this is the highest five-day rainfall total falling at each grid point in a year
- Highest annual hourly total (RX1H) - this is the highest rainfall falling over one hour at each grid point in a year, an indication of short-lived heavy rainfall relevant to flash flooding

## Products:
Status of the NCRA deliverables. 

The three dots (in order from first/top/left to last/bottom/right) represent the datasets used to compute indices:
- Dot 1: Pre-processed BARPA/CCAM – downscaled but NOT bias-corrected, 5 km spatial resolution (deliverable for 30 June)
- Dot 2: Bias-corrected BARPA/CCAM – downscaled AND bias-corrected, 5 km spatial resolution (deliverable for 31 July)
  
Note that bias correction is not available for pressure data 
 
In terms of the colors:
- :green_circle: The data is available in its final official form
- :yellow_circle: The data creation is currently in progress and available soon
- :red_circle: The data processing has not yet started
- :white_circle: Not intended for delivery/not applicable

| Index/metric | time series (ts) | GWLs 2D | MME 2D | MME 2D change | (Notes) |
|-----         | :-:              |:-:      |:-:     |:-:            |:-:    |
| low_freq|:green_circle:<br>|:green_circle:<br>|:green_circle:<br>|:green_circle:<br>|deliverable for 30 June<br>N/A<br>N/A|
| RX1D |:green_circle:<br>:green_circle:|:green_circle:<br>:green_circle:|:green_circle:<br>:green_circle:|:green_circle:<br>:green_circle:|deliverable for 30 June<br>deliverable for 31 July<br>N/A|
| RX5D |:green_circle:<br>:green_circle:|:green_circle:<br>:green_circle:|:green_circle:<br>:green_circle:|:green_circle:<br>:green_circle:|deliverable for 30 June<br>deliverable for 31 July<br>N/A|
| RX1H |:green_circle:<br>:green_circle:|:green_circle:<br>:green_circle:|:green_circle:<br>:green_circle:|:green_circle:<br>:green_circle:|deliverable for 30 June<br>deliverable for 31 July<br>N/A|

## Data location
Raw data: /g/data/ia39/ncra/extratropical_storms/5km/GWLs/
Bias corrected data: /g/data/ia39/ncra/extratropical_storms/bias-corrected/ACS-QME-AGCD-1960-2022/GWLs/
Data for the Queensland 15-member ensemble has also been processed, but has not yet been made available in ia39.

## Summary statistics

This table gives the Australian average of the median % change between values at GWL1.2 and at GWLs 1.5, 2, and 3.

Notes:
- The first column gives our best estimate of the index in the current climate (GWL1.2, 2011-2030) based on the bias corrected datasets. In the case of lows, this has been substituted with the BARRA-R2 climatology during 1991-2020, as the raw ACS data underestimates observed low frequency. 
- For the case of low frequency, "Australian" averages are calculated only for latitudes south of 30S, to avoid contamination by trends in tropical lows
- GWL1.2 represents the "current climate", around 2011-2030. The changes shown represent *future* changes, which are projected to occur on top of changes that have already occurred between a pre-industrial climate and the present.
- Ranges give the 10th-90th percentile of the ACS ensemble. Numbers are shown in bold where at least 65% of ensemble members agree on the sign of the change ("likely"), and italics indicates agreement across at least 90% of the ensemble ("very likely")

| Index/metric | Observations <br>1991-2020| GWL1.5 | GWL2 | GWL3 | Other lines of evidence|
|-----         | :-:                           | :-:    |:-:   |:-:   |-----    |
| low_freq*|1.1% of the time<br>~16 times per year|<b>-2%</b><br>(-13% to +5%)|<b>-8.0%</b><br>(-17% to +6%)|<b><i>-13%</b></i><br>(-24% to -4%)|*calculated for locations south of 30S<br>Current climate is from BARRA-R2 6-hourly data<br>Larger declines are possible based on the Queensland data (GWL3: -19% (-27% to -13%)|
| RX1D |58.8mm|+1%<br>(-3% to +4%)|<b>+6%<br></b>(-4% to +14%)|<b>+12%</b><br>(-2% to +19%)|Best estimate based on the AR&R review is +8% (+2-15%) per degree of warming, implying possible increases of 29% or higher at GWL3|
| RX5D |101.4mm|-1%<br>(-4% to +3%)|+4%<br>(-8% to +11%)|<b>+8%</b><br>(-6% to +14%)|Consistent with the AR&R review, increases of 29% or higher are possible at GWL3|
| RX1H |19.1mm|+1%<br>(-1% to +6%)|<b>+5%<br></b>(-2% to +12%)|<b><i>+13%</b></i><br>(+1% to +19%)|Regional models miss key processes likely to lead to intensification of hourly extremes. The best estimate based on the AR&R review is +15% (+7-28%) per degree of warming, implying increases of 13-56% at GWL3|

| RX1D | Low frequency |
|----- |-----    |
|![RX1D has lots of spatial variability, but increasing (blue) trends are more common than decreases](RX1D_AGCD-05i_MM50_ssp370_v1-r1-ACS-QME-AGCD-1960-2022_GWL15_change.png)
) | ![low frequency decreases in most of southern Australia, particularly in the southeast; trends are messier in northern regions where this index is dominated by tropical lows](lows_AGCD-05i_MM50_ssp370_v1-r1_GWL30_change.png) |
|Multi-model median of the % change in RX1D between GWL1.2 and GWL3 |Multi-model median of the % change in low frequency between GWL1.2 and GWL3 |

## Details on extratropical lows

Lows are initially identified as individual cyclone centres at a single atmospheric level, and can have a range of intensities.
<br>For the purposes of this intial dataset we include:
- Surface lows that have closed circulation and persist for at least 6 hours
- Which have a matching low at 500hPa within 500km at least once
  
Any grid point within a 5 degree (500km radius) of the low centre is considered to be influenced by the low. 
<br>This is used to calculate what proportion of all 6-hourly observations are influenced by a low.
<br>Note that this tracking does not disinguish between extratropial lows or tropical lows (including but not limited to tropical cyclones)

## Details of code 

This is a directory of code developed by the NCRA Extratropical Storm Hazard Team

The early files are a dump of code used to create preliminary maps of extratropical storms and extreme rainfall as part of the NCRA Extratropical Storm Hazard Team 2-pagers

The files uploaded in June 2024 were used to develop the MVP grids stored in /g/data/ia39/ncra/extratropical_storms/

Shell scripts based on cdo are used to extract annual RX1D, RX5D, and RX1H datasets from the raw files. 
- run_rx5d_5km.sh is the main file for the MVP RX1D/RX5D datasets, while run_rx5d_NHP.sh applies the same methods to the older NHP data and run_rx5d_5km_biasadj.sh applies the same methods to the bias corrected datasets (QME and MRNBC)
- As there is no 5km hourly data, the RX1H is first calculated on the native grid (e.g. run_rx1h_barpa_v3.sh, run_rx1h_ccam_v3.sh, run_rx1h_qld.sh) and then regridded to 5km using CDO (regrid_RX1H_5km.sh)
- Lows are tracked using a different set of code from https://github.com/apepler/cyclonetracking, and the raw track files at from https://github.com/apepler/cyclonetracking were converted to annual grids using R, extract_gridded_lows.R. This is performed on a 1 degree grid by default, and regridded to 5km using regrid_lows_5km.sh

In addition, there are preliminary code for calculating GWL grids and generating figures; these are likely to be replaced by python code in future versions.
- extract_grids_annmean_regs_tocsv.R takes annual gridded datasets and converts them to annual timeseries of means for each NCRA region
- generate_GWL_grids_5km.ncl generates netCDF grids for different GWLs using the 13-membr ACS ensemble
- analyse_GWL_plots_5km.ncl uses the same process but generates plots instead of aving the netCDF grids

## Authors and acknowledgment
Hazard team:
- [ ] Acacia Pepler (BOM, lead)
- [ ] James Risbey (CSIRO, alternate lead)
- [ ] Tess Parker


