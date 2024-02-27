This is a dump of code used to create preliminary maps of extratropical storms and extreme rainfall as part of the NCRA Extratropical Storm Hazard Team 2-pagers

R code BARPA_hazardteam_maps_GWLs.R is used for cyclone mapping. This draws on existing cyclone tracks on NCI at /g/data/eg3/asp561/CycloneTracking, which were tracked using code from https://github.com/apepler/cyclonetracking

NCL scripts are used to plot extreme rainfall indices - the file name should give the index (RX5D/RX1D/RX1H/days over thresholds) as well as the dataset (AWAP/BARRA/BARPA/IMERG). There are some additional pieces of code I used for e.g. converting the raw BARPA output into derived netcdf files that were easier to manipulate
