#!/usr/bin/env bash 
source ~/.bash_profile
module load ncl
cd CESM2-Realtime-Forecast
./bin/getCDASdata.py
export CYLC_TASK_CYCLE_POINT=`date +%Y-%m-%d -d yesterday`
ncl ./bin/create_landforcing_from_NCEPCFC.ncl

./bin/update_land_streams.py --case/glade/scratch/ssfcst/I2000Clm50BgcCrop.002runRealtime/
cd /glade/scratch/ssfcst/I2000Clm50BgcCrop.002runRealtime/
./xmlchange STOP_N=1
./xmlchange STOP_OPTION=ndays
./case.submit
