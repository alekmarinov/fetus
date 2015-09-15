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

# downloads the bootstrap script and start it
if [ -z "$BOOTSTRAP_SCRIPT" ]; then
	wget -q -O $TARGET_DIR/bootstrap.sh http://$LOS_REPO_USER:$LOS_REPO_PASS@storage.intelibo.com/los/bootstrap.sh && \
	LOS_REPO_USER=$LOS_REPO_USER LOS_REPO_PASS=$LOS_REPO_PASS sh $TARGET_DIR/bootstrap.sh
else
	cp -f $BOOTSTRAP_SCRIPT $TARGET_DIR/bootstrap.sh && \
	LOS_REPO_USER=$LOS_REPO_USER LOS_REPO_PASS=$LOS_REPO_PASS sh $TARGET_DIR/bootstrap.sh
fi

die() { echo -e "error: $*" ; exit 1 ; }
# autorun lua rocks
export PATH=$PATH:$TARGET_DIR/bin
export LUA_PATH=$TARGET_DIR/share/lua/5.1/?.lua
luarocks install los || die "luarocks install failed."

chmod 0755 $TARGET_DIR/var/lib/rocks/bin/los
ln -sf $TARGET_DIR/var/lib/rocks/bin/los $TARGET_DIR/bin/los
echo -e "\n\n==========================================="
echo -e "Add the following vars to your environment:\nPATH=\$PATH:$TARGET_DIR/bin"
