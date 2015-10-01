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
[ -z "$TARGET_DIR" ] && TARGET_DIR="$HOME/los"
[ -z "$LOS_REPO_USER" ] && LOS_REPO_USER=alek
[ -z "$LOS_REPO_PASS" ] && LOS_REPO_PASS=aviqa2

# bootstrap los cleanly
rm -rf $TARGET_DIR
mkdir -p $TARGET_DIR

echo "Prepare bootstrap in $TARGET_DIR"

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

# downloads the bootstrap script and start it
if [ -z "$BOOTSTRAP_SCRIPT" ]; then
	download_file http://$LOS_REPO_USER:$LOS_REPO_PASS@storage.intelibo.com/los/bootstrap/bootstrap.sh $TARGET_DIR/bootstrap.sh
else
	cp -f $BOOTSTRAP_SCRIPT $TARGET_DIR/bootstrap.sh
fi

LOS_REPO_USER=$LOS_REPO_USER LOS_REPO_PASS=$LOS_REPO_PASS sh $TARGET_DIR/bootstrap.sh
check_status "bootstrap.sh failed"

# autorun lua rocks
export PATH=$PATH:$TARGET_DIR/bin
export LUA_PATH=$TARGET_DIR/share/lua/5.1/?.lua
luarocks install los
check_status "luarocks install failed."

chmod 0755 $TARGET_DIR/var/lib/rocks/bin/los
ln -sf $TARGET_DIR/var/lib/rocks/bin/los $TARGET_DIR/bin/los
echo -e "\n\n==========================================="
echo -e "Add the following vars to your environment:"
echo -e "export LOS_HOME=$TARGET_DIR"
echo -e "export PATH=\$PATH:\$LOS_HOME/bin"
