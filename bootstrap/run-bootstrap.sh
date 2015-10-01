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
#set -x
## configure variables
[ -z "$LOS_ROOT" ] && LOS_ROOT="$HOME/los"
[ -z "$LOS_REPO_USER" ] && LOS_REPO_USER=alek
[ -z "$LOS_REPO_PASS" ] && LOS_REPO_PASS=aviqa2

# return current base script name
script_name()
{
	local name=$(readlink -f $0)
	name=$(basename $name 2>/dev/null)
	echo $name
}

# show message and exit with failure
die() { echo -e "error: $*" ; exit 1 ; }

# debug info message
info() { echo "$(script_name): $1"; }

# checks last command status and exits on failure with error
check_status()
{
	if [[ $? != 0 ]]; then
		die "$1 failed"
	fi
}

# downloads url to file
download_file()
{
	local url=$1
	local file=$2
	info "download $url to $file"

	which curl 2> /dev/null > /dev/null
	if [[ $? == 0 ]]; then
		curl -f -s $url > $file
		check_status "download with curl failed"
	else
		which wget 2> /dev/null > /dev/null
		if [ $? == 0 ]; then
			wget -q -O $file $url
			check_status "download with wget failed"
		else
			die "Can't locate wget or curl to download files"
		fi
	fi
}

# make sure we bootstrap los cleanly
[ -e $LOS_ROOT ] && die "$LOS_ROOT directory exists. Please install los in non existing directory"
mkdir -p $LOS_ROOT

echo "Prepare bootstrap in $LOS_ROOT"


# downloads the bootstrap script and start it
if [ -z "$BOOTSTRAP_SCRIPT" ]; then
	download_file http://$LOS_REPO_USER:$LOS_REPO_PASS@storage.intelibo.com/los/bootstrap/bootstrap.sh $LOS_ROOT/bootstrap.sh
else
	cp -f $BOOTSTRAP_SCRIPT $LOS_ROOT/bootstrap.sh
fi

sh $LOS_ROOT/bootstrap.sh "--los-root=$LOS_ROOT" "--repo-user=$LOS_REPO_USER" "--repo-pass=$LOS_REPO_PASS" $*
check_status "bootstrap.sh"

# autorun lua rocks
LUAROCKS_DIR=$LOS_ROOT/luarocks/2.2
export PATH=$PATH:$LUAROCKS_DIR
export LUA_PATH=$LUAROCKS_DIR/lua/?.lua

lua $LUAROCKS_DIR/luarocks.lua install los
check_status "luarocks install failed."
chmod 0755 $LUAROCKS_DIR/rocks/bin/los
