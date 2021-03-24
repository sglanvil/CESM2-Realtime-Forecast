#!/bin/csh -fx
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-smyle/
setenv CESMROOT /glade/work/nanr/cesm_tags/cesm2.1.4-SMYLE

setenv POSTPROCESS_PATH /glade/u/home/mickelso/CESM_postprocessing_3/
setenv POSTPROCESS_PATH_GEYSER /glade/u/home/mickelso/CESM_postprocessing_3/

set COMPSET = BSMYLE
set MACHINE = cheyenne
set RESOLN = f09_g17
set RESUBMIT = 0
set STOP_N=24
set STOP_OPTION=nmonths
set PROJECT=NCGD0047

setenv BASEROOT /glade/work/nanr/CESM2-SMYLE/cases/

set syr = 1958
set eyr = 1958
set syr = 1959
set eyr = 1959
#set syr = 2007
#set eyr = 2007

@ ib = $syr
@ ie = $eyr

foreach year ( `seq $ib $ie` )
#foreach mon ( 02 05 08 11 )
foreach mon ( 11 )


set REFCASE  = b.e21.SMYLE_IC.f09_g17.${year}-${mon}.01
set REFPERT  = b.e21.SMYLE_IC.pert.f09_g17
set REFROOT  = /glade/scratch/nanr/SMYLE/inputdata/cesm2_init/${REFCASE}/${year}-${mon}-01/
set PERTROOT = /glade/scratch/nanr/SMYLE/inputdata/cesm2_init/pert.${year}-${mon}

#setenv CASEROOT /glade/p/cesm/espwg/CESM2-SMYLE/cases/$CASE
setenv INITDIR  /glade/scratch/nanr/SMYLE/test/
setenv DPDIR    /glade/scratch/nanr/SMYLE/
setenv SHORTCASE b.e21.BSMYLE.f09_g17.${year}-${mon}
setenv CYLC_TASK_CYCLE_POINT ${year}-${mon}-01

# generate perturbed cam.i.restarts
cd ${CESM2_TOOLS_ROOT}/scripts/
./generate_cami_ensemble_offline.py

set doThis = 0
if ($doThis == 1) then
cd ~nanr/CESM-WF/
./create_cylc_cesm2-smyle-ensemble --case $BASEROOT$SHORTCASE --res $RESOLN  --compset $COMPSET --project $PROJECT 

# case name counter
set smbr =   1
set embr =  10

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )

# Use restarts created from case 001 for all ensemble members;  pertlim will differentiate runs.
if ($mbr < 10) then
        set CASE = b.e21.BSMYLE.f09_g17.${year}-${mon}.00${mbr}
else
        set CASE = b.e21.BSMYLE.f09_g17.${year}-${mon}.0${mbr}
endif

# cd $CESMROOT/cime/scripts
# ./create_newcase --case $BASEROOT$CASE --res $RESOLN  --compset $COMPSET 

echo 'Year   = ' $year
echo 'Member = ' $mbr
echo 'Case   = ' $CASE


  setenv RUNDIR   /$DPDIR/$CASE/run
  setenv CASEROOT  $BASEROOT$CASE
  cd $CASEROOT
  ./xmlchange CIME_OUTPUT_ROOT=/glade/scratch/$USER/SMYLE 
  ./xmlchange OCN_TRACER_MODULES="iage cfc ecosys"

  ./xmlchange RUN_REFCASE=$REFCASE
  ./xmlchange RUN_REFDATE=${year}-${mon}-01
  ./xmlchange RUN_STARTDATE=${year}-${mon}-01
  ./xmlchange GET_REFCASE=FALSE
  ./xmlchange PROJECT=NCGD0047
  ./xmlchange --append CAM_CONFIG_OPTS=-cosp

  ./xmlchange NTASKS_ICE=36
  ./xmlchange NTASKS_LND=504
  ./xmlchange ROOTPE_ICE=504
# ./xmlchange DOUT_S_ROOT=$ENV{SCRATCH}/SMYLE/archive/$CASE

  ./case.setup


  mv user_nl_cam user_nl_cam.`date +%m%d-%H%M`
  mv user_nl_clm user_nl_clm.`date +%m%d-%H%M`
  mv user_nl_cpl user_nl_cpl.`date +%m%d-%H%M`
  mv user_nl_cice user_nl_cice.`date +%m%d-%H%M`
  #mv SourceMods/ SourceMods/.`date +%m%d-%H%M`
  cp $CESM2_TOOLS_ROOT/SourceMods/src.pop/* $CASEROOT/SourceMods/src.pop/
  cp $CESM2_TOOLS_ROOT/SourceMods/src.cam/* $CASEROOT/SourceMods/src.cam/
  cp $CESM2_TOOLS_ROOT/SourceMods/src.clm/* $CASEROOT/SourceMods/src.clm/

  cp $CESM2_TOOLS_ROOT/user_nl_files/user_nl_cam $CASEROOT/
  cp $CESM2_TOOLS_ROOT/user_nl_files/user_nl_clm $CASEROOT/
  cp $CESM2_TOOLS_ROOT/user_nl_files/user_nl_cpl $CASEROOT/
  cp $CESM2_TOOLS_ROOT/user_nl_files/user_nl_cice $CASEROOT/


  ./xmlchange STOP_N=$STOP_N
  ./xmlchange STOP_OPTION=$STOP_OPTION
  ./xmlchange RESUBMIT=$RESUBMIT

  if ($mbr > 1) then
	./xmlchange EXEROOT="/glade/scratch/nanr/SMYLE/b.e21.BSMYLE.f09_g17.${year}-${mon}.001/bld/"
  endif

echo " Copy Restarts -------------"
if (! -d $RUNDIR) then
        echo 'mkdir ' $RUNDIR
        mkdir -p $RUNDIR
endif

   cp    ${REFROOT}/rpointer* $RUNDIR/
   ln -s ${REFROOT}/b.e21*    $RUNDIR/

echo " End restarts copy -----------"

echo " Add cam.i.perturbation Restarts -------------"
   set doThis = 1
   if ($doThis == 1) then
   if ($mbr > 1) then
   	set ifile = ${REFCASE}.cam.i.${year}-${mon}-01-00000.nc 
   	set ofile = ${REFCASE}.cam.i.${year}-${mon}-01-00000-original.nc
   	mv $RUNDIR/$ifile $RUNDIR/$ofile
   	if ($mbr < 10) then
        	ln -s ${PERTROOT}/pert0${mbr}/${REFPERT}.cam.i* $RUNDIR/$ifile
   	        echo ${PERTROOT}/pert0${mbr}/${REFPERT}.cam.i* $RUNDIR/$ifile
   	else
        	ln -s ${PERTROOT}/pert${mbr}/${REFPERT}.cam.i* $RUNDIR/$ifile
   	        echo ${PERTROOT}/pert${mbr}/${REFPERT}.cam.i* $RUNDIR/$ifile
   	endif
   endif
   endif

#echo $DPDIR/$CASE/run/
#echo $RUNDIR

# ./preview_namelists

# ./case.build >& bld.`date +%m%d-%H%M`
endif		# doThis loop
end             # member loop

exit
