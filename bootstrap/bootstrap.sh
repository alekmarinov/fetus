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

# default parameters
DEFAULT_LOS_ROOT=$(dirname $(readlink -f $0))

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

# downloads url to file
download_file()
{
	local url=$1
	local file=$2
	info "download $url to $file"

	which curl 2> /dev/null > /dev/null
	if [[ $? == 0 ]]; then
		curl -f -s $url > $file
	else
		which wget 2> /dev/null > /dev/null
		if [ $? == 0 ]; then
			wget -q -O $file $url
		else
			die "Can't locate wget or curl to download files"
		fi
	fi
}

## entry point

USAGE="
LOS bootstrap utility

SYNOPSIS
	$(basename "$0") [--repo-base=...] [--repo-opensource=...] [--repo-rocks=...] [--repo-bootstrap=...] [--los-root=...] [--luarocks-root=...] [--luarocks-rocks=...] [-h | --help]

OPTIONS
    --repo-user=<username>        username to main los repository
    --repo-pass=<password>        password to main los repository
    --repo-base=<url>             base url to los repository, default 
                                  http://<repo_user>:<repo_pass>@storage.intelibo.com/los
    --repo-opensource=<url>       url to los opensource files, default
                                  <repo-base>/opensource
    --repo-rocks=<url>            url to los rock files, default
                                  <repo-base>/rocks
    --repo-bootstrap=<url>        url to los bootstrap files, default
                                  <repo-base>/bootstrap
    --los-root=<directory>        the directory where to install los files, default
                                  $DEFAULT_LOS_ROOT
    --luarocks-root=<directory>   the directory where to install luarocks, default
                                  $DEFAULT_LOS_ROOT/luarocks
    --luarocks-tree=<directory>   luarocks tree directory, default
                                  $DEFAULT_LOS_ROOT/luarocks/tree
    -h|--help                     show this help text"

## parsing command line options

for i in "$@"; do
	case $i in
		--repo-user=*)
			REPO_USER="${i#*=}"
			shift
		;;
		--repo-pass=*)
			REPO_PASS="${i#*=}"
			shift
		;;
		--repo-base=*)
			URL_REPO_BASE="${i#*=}"
			shift
		;;
		--repo-opensource=*)
			URL_REPO_OPENSOURCE="${i#*=}"
			shift
		;;
		--repo-rocks=*)
			URL_REPO_ROCKS="${i#*=}"
			shift
		;;
		--repo-bootstrap=*)
			URL_REPO_BOOTSTRAP="${i#*=}"
			shift
		;;
		--los-root=*)
			LOS_ROOT="${i#*=}"
			shift
		;;
		--luarocks-root=*)
			LUAROCKS_ROOT="${i#*=}"
			shift
		;;
		--luarocks-tree=*)
			LUAROCKS_TREE_DIR="${i#*=}"
			shift
		;;
		-h|--help)
			echo "$USAGE"
			exit 1
		;;
		*)
			die "unknown option $i"
		;;
	esac
done

## configure variables
if [ -z "$URL_REPO_BASE" ]; then
	[ -z "$REPO_USER" ] && die "--repo-user parameter required for the main los repository"
	[ -z "$REPO_PASS" ] && die "--repo-pass parameter required for the main los repository"
	URL_REPO_BASE="http://${REPO_USER}:${REPO_PASS}@storage.intelibo.com/los"
fi

URL_REPO_OPENSOURCE=${URL_REPO_OPENSOURCE:-"$URL_REPO_BASE/opensource"}
URL_REPO_ROCKS=${URL_REPO_ROCKS:-"$URL_REPO_BASE/rocks"}
URL_REPO_BOOTSTRAP=${URL_REPO_BOOTSTRAP:-"$URL_REPO_BASE/bootstrap"}
LOS_ROOT=${LOS_ROOT:-"$DEFAULT_LOS_ROOT"}
LUAROCKS_ROOT=${LUAROCKS_ROOT:-"$LOS_ROOT/luarocks"}
LUAROCKS_TREE_DIR=${LUAROCKS_TREE_DIR:-"$LUAROCKS_ROOT/tree"}
LUAROCKS_VERSION="2.2.2"
ZZIPLIB_NAME="zziplib-0.13.62"
ZZIPLIB_PACKAGE="$ZZIPLIB_NAME.tar.bz2"

echo "Prepare bootstrap in $LOS_ROOT"

# make sure we bootstrap los in existing directory
mkdir -p $LOS_ROOT

if [[ "$WINDIR" != "" ]]; then
	LUAROCKS_NAME="luarocks-$LUAROCKS_VERSION-win32"
	LUAROCKS_PACKAGE="$LUAROCKS_NAME.zip"
else
	LUAROCKS_NAME="luarocks-$LUAROCKS_VERSION"
	LUAROCKS_PACKAGE="$LUAROCKS_NAME.tar.gz"
	LUAROCKS_CONFIGURE_DIFF="$LUAROCKS_NAME-configure.diff"
fi

if [[ "$WINDIR" != "" ]]; then
	LUAROCKS_CONFIG_LUA="$LUAROCKS_ROOT/config.lua"
else
	LUAROCKS_CONFIG_LUA="$LUAROCKS_ROOT/etc/luarocks/config-5.1.lua"
fi

# locate and test lua interpreter
check_program lua
EXPECTED="hi"
ACTUAL=$(lua -e "print \"$EXPECTED\"")
if [[ $ACTUAL == $EXPECTED ]]; then
	info "lua interpreting test passed"
else
	die "lua interpreting test failed"
fi

# locate and test tar
check_program tar
tar --help > /dev/null
check_status "tar execution test failed"

# locate and test patch
check_program patch
patch --help > /dev/null
check_status "patch execution test failed"

# cleanup installation dir
mkdir -p $LOS_ROOT
check_status "creating directory $LOS_ROOT"

# cleanup polluted luarocks files from previous installs
rm -rf $LOS_ROOT/{$LUAROCKS_PACKAGE,$LUAROCKS_NAME,$LUAROCKS_ROOT}

# download luarocks
download_file "$URL_REPO_OPENSOURCE/$LUAROCKS_PACKAGE" "$LOS_ROOT/$LUAROCKS_PACKAGE"
check_status "downloading $URL_REPO_OPENSOURCE/$LUAROCKS_PACKAGE"

# extract luarocks
info "extract $LOS_ROOT/$LUAROCKS_PACKAGE"

if [[ "$WINDIR" != "" ]]; then
	unzip $LOS_ROOT/$LUAROCKS_PACKAGE -d $LOS_ROOT
	check_status "unzip $LOS_ROOT/$LUAROCKS_PACKAGE"
else
	tar xfz $LOS_ROOT/$LUAROCKS_PACKAGE -C $LOS_ROOT
	check_status "tar xfz $LOS_ROOT/$LUAROCKS_PACKAGE"

	# fix luarocks configure issue in case LUA_DIR is found in / which makes invaild paths like $LUA_DIR/include -> //include
	info "patching $LOS_ROOT/$LUAROCKS_NAME/configure"
	download_file "$URL_REPO_BOOTSTRAP/$LUAROCKS_CONFIGURE_DIFF" "$LOS_ROOT/$LUAROCKS_NAME/$LUAROCKS_CONFIGURE_DIFF"
	check_status "downloading $URL_REPO_BOOTSTRAP/$LUAROCKS_CONFIGURE_DIFF"
	patch $LOS_ROOT/$LUAROCKS_NAME/configure $LOS_ROOT/$LUAROCKS_NAME/$LUAROCKS_CONFIGURE_DIFF
fi
rm -f $LOS_ROOT/$LUAROCKS_PACKAGE

cd $LOS_ROOT/$LUAROCKS_NAME

# install luarocks
if [[ "$WINDIR" == "" ]]; then
	# configure luarocks
	info "configure $LOS_ROOT/$LUAROCKS_NAME"
	./configure --prefix=$LUAROCKS_ROOT --rocks-tree=$LUAROCKS_TREE_DIR
	check_status "configuring $LOS_ROOT/$LUAROCKS_NAME"

	# make luarocks
	info "make $LOS_ROOT/$LUAROCKS_NAME"
	make > /dev/null
	check_status "making luarocks"

	# install luarocks
	info "install $LOS_ROOT/$LUAROCKS_NAME"
	make install > /dev/null
	check_status "installing luarocks"
else
	# start luarocks installer with the installed lua
	LUA_DIR=$(dirname $(dirname $($COMSPEC /c "which lua")))

	$COMSPEC //\c install.bat //\P $LUAROCKS_ROOT //\TREE $LUAROCKS_TREE_DIR //\LUA $LUA_DIR //\MW //\F //\NOREG //\NOADMIN //\Q

	# patch config.lua to use compiler named gcc, instead mingw-gcc
	sed -i "s/variables = {/variables = {\n    CC = 'gcc',\n    LD = 'gcc',\n    CFLAGS = '-m32 -O2',\n    LIBFLAG = '-m32 -shared',/" $LUAROCKS_ROOT/config.lua
	EXT_DIR=$(echo $LUA_DIR | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')
	sed -i "s/LUALIB = .*/LUALIB = '-llua',\n    LUA_LIBDIR = '',/" $LUAROCKS_ROOT/config.lua

	# patch cfg.lua getting rid of hardcoded path c:/external/
	sed -i "s/\"c:\/external\/\"/\"$(echo $EXT_DIR | sed -e 's/\\\\/\\\//g')\"/" $LUAROCKS_ROOT/2.2/lua/luarocks/cfg.lua
	EXT_DIR=$(echo $EXT_DIR | sed -e 's/\\\\/\//g')

	# build zziplib for mingw32
	if [ -f $EXT_DIR/lib/libzzip.a ]; then
		info "$ZZIPLIB_NAME is already installed in $EXT_DIR"
	else
		# cleanup polluted files from previous installs
		rm -rf $LOS_ROOT/{build,$ZZIPLIB_NAME,$ZZIPLIB_PACKAGE}

		download_file "$URL_REPO_OPENSOURCE/$ZZIPLIB_PACKAGE" "$LOS_ROOT/$ZZIPLIB_PACKAGE"
		check_status "downloading $URL_REPO_OPENSOURCE/$ZZIPLIB_PACKAGE"
		tar xfj $LOS_ROOT/$ZZIPLIB_PACKAGE -C $LOS_ROOT
		mkdir -p "$LOS_ROOT/build"
		cd "$LOS_ROOT/build"
		sh ../$ZZIPLIB_NAME/configure CFLAGS=-m32 LDFLAGS=-m32 --disable-mmap --disable-builddir --prefix=$EXT_DIR
		check_status "configure $ZZIPLIB_NAME"
		# only the lib is needed to provide
		sed -i "s/^SUBDIRS = .*/SUBDIRS = zzip/" Makefile
		mingw32-make
		check_status "make $ZZIPLIB_NAME"
		mingw32-make install
		check_status "make install $ZZIPLIB_NAME"
		cd $LOS_ROOT

		# zzip sources are no longer needed, cleaning up
		rm -rf $LOS_ROOT/{build,$ZZIPLIB_NAME,$ZZIPLIB_PACKAGE}
	fi
fi

cd $LOS_ROOT
rm -rf $LOS_ROOT/$LUAROCKS_NAME

# check luarocks config
expect_file $LUAROCKS_CONFIG_LUA

# configure luarocks repository
info "set luarocks server to $URL_REPO_ROCKS"
echo -e "rocks_servers = \n{\n\t\"https://luarocks.org/\",\n\t\"$URL_REPO_ROCKS\"\n}" >> $LUAROCKS_CONFIG_LUA

echo -e "luarocks installation finished.\nAdd the following vars to your environment:\nPATH=\$PATH:$LUAROCKS_ROOT/2.2\nLUA_PATH=$LUAROCKS_ROOT/lua/?.lua"

echo "Bootstrap SUCCESS!"
