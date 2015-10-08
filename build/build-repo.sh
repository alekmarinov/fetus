#!/bin/sh
##################################################################
##																##
## Copyright (C) 2003-2015, Intelibo Ltd						##
##																##
## Project:       los											##
## Filename:      build-repo.sh									##
## Description:   Builds bootstrap and luarocks repository		##
## Arguments:     1. <repo_bootstrap_dir>						##
##																##
##################################################################

# return current base script name
script_name()
{
	local name=$(readlink -f $0)
	name=$(basename $name 2>/dev/null)
	echo $name
}

# locate this directory
this_dir()
{
	local THIS_DIR=$(readlink -f "$0")
	local SCRIPT_NAME=$(script_name)
	while [ ! -f "$THIS_DIR/$SCRIPT_NAME" ]; do
		THIS_DIR=$(dirname $THIS_DIR)
	done
	echo $THIS_DIR
}

# locate root directory
root_dir()
{
	local THIS_DIR=$(this_dir)
	# root is the parent directory of this script
	echo $(dirname $THIS_DIR)
}

# show usage info and exit with failure
usage()
{
	echo "Usage: $(script_name) $1"
	exit 1
}

# returns application version description
# param 1: application git repository
app_version()
{
	local git_repo=$1
	local git_ver=$(cd $git_repo && git describe --match "[0-9]*")
	local normal_ver=${git_ver/\-/.}
	local app_ver=${normal_ver/%-*/}
	echo $app_ver
}

# process script arguments
REPO_BOOTSTRAP_DIR=$1
[[ -z $REPO_BOOTSTRAP_DIR ]] && usage "<repo_bootstrap_dir>"

BOOTSTRAP_LOCAL_DIR=$(root_dir)/bootstrap

# FIXME: just simple for now

# copy los bootstrap files
mkdir -p "$REPO_BOOTSTRAP_DIR"
cd $BOOTSTRAP_LOCAL_DIR && zip -r -q "$REPO_BOOTSTRAP_DIR/bootstrap-$(app_version $(root_dir)).zip" *
