#!/bin/sh
##################################################################
##																##
## Copyright (C) 2003-2015, Intelibo Ltd						##
##																##
## Project:       los											##
## Filename:      run-bootstrap.sh								##
## Description:   los bootstrap script starter					##
##																##
##################################################################

## configure variables
TARGET_DIR="$HOME/los"
LOS_REPO_USER=alek
LOS_REPO_PASS=aviqa2

# bootstrap los cleanly
rm -rf $TARGET_DIR
mkdir -p $TARGET_DIR

# downloads the bootstrap script and start it
wget -q -O $TARGET_DIR/bootstrap.sh http://$LOS_REPO_USER:$LOS_REPO_PASS@storage.intelibo.com/los/bootstrap.sh && \
  LOS_REPO_USER=$LOS_REPO_USER LOS_REPO_PASS=$LOS_REPO_PASS sh $TARGET_DIR/bootstrap.sh
