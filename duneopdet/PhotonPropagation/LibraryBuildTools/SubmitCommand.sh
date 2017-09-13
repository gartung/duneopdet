#!/bin/bash

tarfile=
USER=${USER} #Set the user to the default USER from the environment unless over ridder

##This block handles flags given to the program.
# Allowed flags are:
#    -t | --tar    : Pass a tarfile of a larsoft installation to be setup on the cluster.
#                     User full path to file.
#    -u | --user   : Over ride the user directory to write to on dCache *NOT RECOMENDED
while :; do
  case $1 in
    --tar|-t)
      if [ "$2" ]; then
        tarfile=$2
        shift
      else
        printf 'ERROR: "--tar" requires a path to a tar file of a larsoft installation.\n' >&2
        exit 10
      fi
      ;;
    --tar=?*)
      tarfile=${1#*=}
      ;;
    --user|-u)
      if [ "$2" ]; then
        USER=$2
        shift
      else
        printf 'ERROR: "--user" requires a username to use for the dCache directory.\n' >&2
        exit 10
      fi
      ;;
    --user=?*)
      USER=${1#*=}
      ;;
    --)
      shift
      break
      ;;
    -?*)
      printf 'ERROR: Uknown option\n'
      exit 10
      ;;
    *)
      break
  esac
  shift
done


script=OpticalLibraryBuild_Grid_dune.sh
outdir=/pnfs/dune/scratch/users/${USER}/OpticalLibraries/OpticalLib_dune10kt_v1_1x2x6
fcl=$outdir/dune10kt_v2_1x2x6_buildopticallibrary_grid.fcl

if [ ! -d $outdir/root ]; then
    mkdir -p $outdir/root
    mkdir -p $outdir/fcl
    mkdir -p $outdir/log
fi

if [ ! -e $fcl ]; then
    cp `basename $fcl` $fcl
fi

# 57600 seconds = 16 hours, but it will not be a sharp cut-off
environmentVars="-e IFDH_CP_MAXRETRIES=5"
clientargs="--resource-provides=usage_model=DEDICATED,OPPORTUNISTIC --OS=SL6 --group=dune -f $fcl --role=Analysis --memory=2500MB "
if [ x$tarfile != x ]; then
  echo "Using tarball. Not setting LArSoft environment variables"
  larsoft=
  clientargs="${clientargs} --tar_file_name=dropbox://${tarfile} "
else
  larsoft="${environmentVars} -e mrb_top=$MRB_TOP -e mrb_project=dunetpc -e mrb_version=$MRB_PROJECT_VERSION -e mrb_quals=$MRB_QUALS "
fi

toolsargs="-q -g --opportunistic --OS=SL6 "
fileargs="-dROOT $outdir/root -dFCL $outdir/fcl -dLOG $outdir/log "


#Test job 1 - jobsub_client
#njobs=7200
#nphotons=10
#clientargs="$clientargs --expected-lifetime=600 "
#thisjob="-Q -N 1 file://$PWD/$script $njobs $nphotons"

#Real job - jobsub_client
njobs=6000
nphotons=50000
clientargs="$clientargs --expected-lifetime=16h "
thisjob="-N $njobs file://$PWD/$script $njobs $nphotons"

if [ x$tarfile != x]; then
  echo "jobsub_submit $environmentVars $clientargs $fileargs $thisjob "
  jobsub_submit $environmentVars $clientargs $fileargs $thisjob 
  ret=$?
  printf "Exiting with status $ret\n"
  exit $ret
else
  echo "jobsub_submit $environmentVars $larsoft $clientargs $fileargs $thisjob"
  jobsub_submit $environmentVars $larsoft $clientargs $fileargs $thisjob 
  ret=$?
  printf "Exiting with status $ret\n"
  exit $ret
fi


