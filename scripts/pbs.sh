#!/bin/bash
# Joshua Smith (smjoshua@umich.edu)
# EECS 470 - Fall 2010
#
# This script is executed to run the synthesis job on the computing node.
# It will copy the project files from the user's home space to local
# space on the computing node, and then run Design Compiler.
# You likely won't need to modify this script at all.

# W'12 moved to scripts dir
pushd ../

# Create a local directory and copy project files from home space
echo "PBS - Copying project files to local tmp..."
mkdir /tmp/${PBS_JOBID}
cd /tmp/${PBS_JOBID}
rsync -avz ~/$WORK_DIR .
if [ "$?" -ne '0' ]; then
  echo "PBS - Error while trying to copy project files to tmp"
  cd
  /bin/rm -rf /tmp/${PBS_JOBID}
  popd
  exit 1
fi

# Run synthesis
MAIN_DIR=`find . type -d -name $ROOT_PROJ_DIR`
if [ "$MAIN_DIR" == "" ]; then
  echo "PBS - Could not find $ROOT_PROJ_DIR directory, aborting"
  cd
  /bin/rm -rf /tmp/${PBS_JOBID}
  popd
  exit 1
fi
cd $MAIN_DIR
echo "PBS - Running synthesis..."
make syn

# To just synthesize pipeline (and not run simulation), comment "make syn"
#  above and uncomment the following line.
#/usr/caen/bin/dc_shell-t -f ./$PROJ_TCL

# Clean up simulation output
make clean

# Copy new synthesis files back to home space
cd /tmp/${PBS_JOBID}
rsync -avz . ~/$WORK_DIR/..
if [ "$?" -ne '0' ]; then
  echo "PBS - Error while trying to copy synthesized files back to home"
  cd
  /bin/rm -rf /tmp/${PBS_JOBID}
  popd
  exit 1
fi

# clean up files
cd
/bin/rm -rf /tmp/${PBS_JOBID}
echo "PBS - Done!"

popd
