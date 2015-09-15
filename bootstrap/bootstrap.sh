#!/bin/sh
##################################################################
##																##
## Copyright (C) 2003-2015, Intelibo Ltd						##
##																##
## Project:       los											##
## Filename:      bootstrap.sh									##
## Description:   los bootstrap script							##
##																##
##################################################################

## configure variables
URL_REPO_BASE="http://${LOS_REPO_USER}:${LOS_REPO_PASS}@storage.intelibo.com"
URL_REPO_OPENSOURCE=$URL_REPO_BASE/opensource
URL_REPO_ROCKS=$URL_REPO_BASE/rocks
URL_REPO_LOS=$URL_REPO_BASE/los

LUAROCKS_VERSION="2.2.2"
LUAROCKS_NAME="luarocks-$LUAROCKS_VERSION"
LUAROCKS_PACKAGE="$LUAROCKS_NAME.tar.gz"
LUAROCKS_CONFIGURE_DIFF="$LUAROCKS_NAME-configure.diff"

SCRIPT_PATH_NAME=$(readlink -f $0)
INSTALL_ROOT?=$(dirname $SCRIPT_PATH_NAME)
LUAROCKS_TREE_DIR="$INSTALL_ROOT/var/lib/rocks"
LUAROCKS_CONFIG_LUA="$INSTALL_ROOT/etc/luarocks/config-5.1.lua"

## utility functions

# return current base script name
script_name()
{
	local name=$(readlink -f $0)
	name=$(basename $name 2>/dev/null)
	echo $name
}

# show message and exit with failure
die()
{
	echo "$(script_name): Error! $1"
	echo ""
	exit 1
}

# debug info message
info()
{
	echo "$(script_name): $1"
}

# log command and execute it (for debug purposes only)
execute()
{
	echo "$(script_name) executing: $*"
	$*
}

# log command and execute it without echo (for debug purposes only)
execute_silent()
{
	echo "$(script_name) executing: $*"
	$* > /dev/null
}

# checks last command status and exits on failure with error
check_status()
{
	if [[ $? != 0 ]]; then
		die "$1 failed"
	fi
}

# checks program availability
check_program()
{
	PROGRAM_PATH=$(which $1)
	check_status "locating $1"
	info "found $1 in $PROGRAM_PATH"
}

# file exists or die
expect_file()
{
	[ -f "$1" ] || die "File $1 is expected, but missing!";
}

## entry point

# locate and test lua interpreter
check_program lua
EXPECTED="hi"
ACTUAL=$(lua -e "print \"$EXPECTED\"")
if [[ $ACTUAL == $EXPECTED ]]; then
	info "lua interpreting test passed"
else
	die "lua interpreting test failed"
fi

# locate and test curl
check_program curl
curl --help > /dev/null
check_status "curl execution test failed"

# locate and test tar
check_program tar
tar --help > /dev/null
check_status "tar execution test failed"

# locate and test patch
check_program patch
patch --help > /dev/null
check_status "patch execution test failed"

# cleanup installation dir
rm -rf $INSTALL_ROOT/{$LUAROCKS_PACKAGE,$LUAROCKS_NAME,bin,etc,share,var}
mkdir -p $INSTALL_ROOT
check_status "creating directory $INSTALL_ROOT"

# download luarocks
info "download $URL_REPO_OPENSOURCE/$LUAROCKS_PACKAGE"
curl -f -s $URL_REPO_OPENSOURCE/$LUAROCKS_PACKAGE > $INSTALL_ROOT/$LUAROCKS_PACKAGE
check_status "downloading $URL_REPO_OPENSOURCE/$LUAROCKS_PACKAGE"

# extract luarocks
info "extract $INSTALL_ROOT/$LUAROCKS_PACKAGE"
tar xfz $INSTALL_ROOT/$LUAROCKS_PACKAGE -C $INSTALL_ROOT
check_status "extracting $INSTALL_ROOT/$LUAROCKS_PACKAGE"
rm -f $INSTALL_ROOT/$LUAROCKS_PACKAGE

# fix luarocks configure issue in case LUA_DIR is found in / which makes invaild paths like $LUA_DIR/include -> //include
info "patching $INSTALL_ROOT/$LUAROCKS_NAME/configure"
curl -f -s $URL_REPO_LOS/$LUAROCKS_CONFIGURE_DIFF > $INSTALL_ROOT/$LUAROCKS_NAME/$LUAROCKS_CONFIGURE_DIFF
check_status "downloading $URL_REPO_LOS/$LUAROCKS_CONFIGURE_DIFF"
patch $INSTALL_ROOT/$LUAROCKS_NAME/configure $INSTALL_ROOT/$LUAROCKS_NAME/$LUAROCKS_CONFIGURE_DIFF

# configure luarocks
info "configure $INSTALL_ROOT/$LUAROCKS_NAME"
cd $INSTALL_ROOT/$LUAROCKS_NAME
./configure --prefix=$INSTALL_ROOT --rocks-tree=$LUAROCKS_TREE_DIR --with-downloader=curl > /dev/null
check_status "configuring $INSTALL_ROOT/$LUAROCKS_NAME"

# make luarocks
info "make $INSTALL_ROOT/$LUAROCKS_NAME"
make > /dev/null
check_status "making luarocks"

# install luarocks
info "install $INSTALL_ROOT/$LUAROCKS_NAME"
make install > /dev/null
check_status "installing luarocks"
cd $INSTALL_ROOT
rm -rf $INSTALL_ROOT/$LUAROCKS_NAME

# check luarocks config
expect_file $LUAROCKS_CONFIG_LUA

# configure luarocks repository
info "set luarocks server to $URL_REPO_ROCKS"
echo "rocks_servers = { \"$URL_REPO_ROCKS\" }" >> $LUAROCKS_CONFIG_LUA

echo -e "luarocks installation finished.\nAdd the following vars to your environment:\nPATH=\$PATH:$INSTALL_ROOT/bin\nLUA_PATH=$INSTALL_ROOT/share/lua/5.1/?.lua"
