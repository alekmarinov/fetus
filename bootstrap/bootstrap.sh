#!/bin/sh
##
##
## Copyright (C) 2003-2017, Intelibo Ltd
##
## Project:       los
## Filename:      bootstrap.sh
## Description:   los bootstrap script
##
##

# make windows path
makewinpath()
{
	echo "$1" | sed -e 's|^/\([a-zA-Z]\)/|\1:/|' -e 's/\//\\/g'
}

makeunixpath()
{
	echo "/$1" | sed -e 's/\\/\//g' -e 's/://' -e 's/\/\//\//'
}

this_script=$(makeunixpath $(readlink -f $0))

makepath()
{
	if [ -z "$WINDIR" ]; then
		makeunixpath $1
	else
		makewinpath $1
	fi
}

# get windows path
getwinpath()
{
	$COMSPEC path
}

# return current base script name
script_name()
{
	local name=$(readlink -f $(makeunixpath $this_script))
	echo $(basename $name 2>/dev/null)
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
	if [ $? -ne 0 ]; then
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
	if [ $? -eq 0 ]; then
		curl -f -s $url > $file
	else
		which wget 2> /dev/null > /dev/null
		if [ $? -eq 0 ]; then
			wget -q -O $file $url
		else
			die "Can't locate wget or curl to download files"
		fi
	fi
}

# add directory to PATH
pathmunge()
{
	if ! echo $PATH | grep -q "(^|:)$1($|:)" ; then
		if [ "$2" = "after" ] ; then
			PATH=$PATH:$1
		else
			PATH=$1:$PATH
		fi
	fi
}

## entry point

# default parameters
DEFAULT_LOS_ROOT="$HOME/los"

USAGE="
LOS bootstrap utility

SYNOPSIS
	$(basename "$(script_name)") [--repo-base=...] [--repo-opensource=...] [--repo-rocks=...] [--repo-bootstrap=...] [--los-root=...] [--luarocks-root=...] [--luarocks-rocks=...] [-h | --help]

OPTIONS
    --repo-user=<username>        username to main los repository, default guest
    --repo-pass=<password>        password to main los repository, default guest
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
                                  <los-root>
    --luarocks-tree=<directory>   luarocks tree directory, default
                                  <luarocks-root>/tree
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

REPO_USER=${REPO_USER:-"guest"}
REPO_PASS=${REPO_USER:-"guest"}
URL_REPO_BASE=${URL_REPO_BASE:-"http://${REPO_USER}:${REPO_PASS}@storage.intelibo.com/los"}
URL_REPO_OPENSOURCE=${URL_REPO_OPENSOURCE:-"$URL_REPO_BASE/opensource"}
URL_REPO_ROCKS=${URL_REPO_ROCKS:-"$URL_REPO_BASE/rocks"}
URL_REPO_BOOTSTRAP=${URL_REPO_BOOTSTRAP:-"$URL_REPO_BASE/bootstrap"}
LOS_ROOT=$(makepath ${LOS_ROOT:-"$DEFAULT_LOS_ROOT"})
LOCAL_CONF="$LOS_ROOT/etc/los-local.conf"
LUAROCKS_ROOT=$(makepath ${LUAROCKS_ROOT:-"$LOS_ROOT"})
LUAROCKS_TREE_DIR=$(makepath ${LUAROCKS_TREE_DIR:-"$LUAROCKS_ROOT/tree"})
LUAROCKS_VERSION="2.2.2"
CMAKE_NAME=cmake-3.3.2-win32-x86
CMAKE_PACKAGE="$CMAKE_NAME.zip"
LUA_EX_API_NAME="lua-ex-api-0.1"
LUA_EX_API_PACKAGE="$LUA_EX_API_NAME.zip"

echo "URL_REPO_OPENSOURCE=$URL_REPO_OPENSOURCE"
echo "URL_REPO_ROCKS=$URL_REPO_ROCKS"
echo "URL_REPO_BOOTSTRAP=$URL_REPO_BOOTSTRAP"
echo "LOS_ROOT=$LOS_ROOT"
echo "LUAROCKS_ROOT=$LUAROCKS_ROOT"
echo "LUAROCKS_TREE_DIR=$LUAROCKS_TREE_DIR"
echo "LUAROCKS_VERSION=$LUAROCKS_VERSION"
echo "CMAKE_NAME=$CMAKE_NAME"
echo "CMAKE_PACKAGE=$CMAKE_PACKAGE"
echo "LUA_EX_API_NAME=$LUA_EX_API_NAME"
echo "LUA_EX_API_PACKAGE=$LUA_EX_API_PACKAGE"

if [ -n "$WINDIR" ]; then
	LUAROCKS_BIN=$LUAROCKS_ROOT/2.2
	LUAROCKS_LUA=$LUAROCKS_ROOT/2.2/lua
else
	LUAROCKS_BIN=$LUAROCKS_ROOT/bin
	LUAROCKS_LUA=$LUAROCKS_ROOT/share/lua/5.1
fi

echo "Prepare bootstrap in $LOS_ROOT"

# make sure we bootstrap los in existing directory
mkdir -p $LOS_ROOT

if [ -n "$WINDIR" ]; then
	LUAROCKS_NAME="luarocks-$LUAROCKS_VERSION-win32"
	LUAROCKS_PACKAGE="$LUAROCKS_NAME.zip"
else
	LUAROCKS_NAME="luarocks-$LUAROCKS_VERSION"
	LUAROCKS_PACKAGE="$LUAROCKS_NAME.tar.gz"
fi

if [ -n "$WINDIR" ]; then
	LUAROCKS_CONFIG_LUA="$LUAROCKS_ROOT/config.lua"
else
	LUAROCKS_CONFIG_LUA="$LUAROCKS_ROOT/etc/luarocks/config-5.1.lua"
fi

# locate and test lua interpreter
check_program lua
EXPECTED="hi"
ACTUAL=$(lua -e "print \"$EXPECTED\"")
if [ "$ACTUAL" = "$EXPECTED" ]; then
	info "lua interpreting test passed"
else
	die "lua interpreting test failed"
fi

# locate and test tar
check_program tar

# locate and test patch
check_program patch

# cleanup installation dir
mkdir -p $LOS_ROOT
check_status "creating directory $LOS_ROOT"

# cleanup polluted luarocks files from previous installs
rm -rf $LOS_ROOT/$LUAROCKS_PACKAGE $LOS_ROOT/$LUAROCKS_NAME $LOS_ROOT/$LUAROCKS_ROOT

# download luarocks
download_file "$URL_REPO_OPENSOURCE/$LUAROCKS_PACKAGE" "$LOS_ROOT/$LUAROCKS_PACKAGE"
check_status "downloading $URL_REPO_OPENSOURCE/$LUAROCKS_PACKAGE"

# extract luarocks
info "extract $LOS_ROOT/$LUAROCKS_PACKAGE"

if [ -n "$WINDIR" ]; then
	unzip -q $LOS_ROOT/$LUAROCKS_PACKAGE -d $LOS_ROOT
	check_status "unzip $LOS_ROOT/$LUAROCKS_PACKAGE"
else
	tar xfz $LOS_ROOT/$LUAROCKS_PACKAGE -C $LOS_ROOT
	check_status "tar xfz $LOS_ROOT/$LUAROCKS_PACKAGE"

	# fix luarocks configure issue in case LUA_DIR is found in / which makes invaild paths like $LUA_DIR/include -> //include
	echo "317a318,320"                                   > "$LOS_ROOT/$LUAROCKS_NAME/configure.diff"
	echo ">       if [ \"$LUA_DIR\" = \"/\" ]; then" >> "$LOS_ROOT/$LUAROCKS_NAME/configure.diff"
	echo ">          LUA_DIR=\"\""                      >> "$LOS_ROOT/$LUAROCKS_NAME/configure.diff"
	echo ">       fi"                                   >> "$LOS_ROOT/$LUAROCKS_NAME/configure.diff"

	info "patching $LOS_ROOT/$LUAROCKS_NAME/configure"
	patch $LOS_ROOT/$LUAROCKS_NAME/configure $LOS_ROOT/$LUAROCKS_NAME/configure.diff
fi
rm -f $LOS_ROOT/$LUAROCKS_PACKAGE

cd $LOS_ROOT/$LUAROCKS_NAME

# remove config.lua if already there to avoid luarocks complains
rm -f $LUAROCKS_ROOT/config.lua

# install luarocks
if [ -z "$WINDIR" ]; then
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

	# remove --tries=1 from wget params to satisfy wget from busybox
	sed -i "s/\.\.\" --tries=1 \"//" $LUAROCKS_LUA/luarocks/fs/unix/tools.lua
	sed -i "s/ok = fs\.execute_quiet(wget_cmd\.\.\" --timestamping \", url)/fs\.delete(filename) ok = fs\.execute_quiet(wget_cmd, url)/" $LUAROCKS_LUA/luarocks/fs/unix/tools.lua
else
	# start luarocks installer with the installed lua
	LUA_DIR=$(dirname $(dirname $($COMSPEC /c "which lua")))

	$COMSPEC //\c install.bat //\P $LUAROCKS_ROOT //\TREE $LUAROCKS_TREE_DIR //\LUA $LUA_DIR //\MW //\F //\NOREG //\NOADMIN //\Q

	# patch config.lua to use compiler named gcc, instead mingw-gcc
	sed -i "s/variables = {/variables = {\n    CC = 'gcc',\n    LD = 'gcc',\n    CFLAGS = '-m32 -O2',\n    LIBFLAG = '-m32 -shared',/" $LUAROCKS_ROOT/config.lua
	EXT_DIR=$(echo $LUA_DIR | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')
	sed -i "s/LUALIB = .*/LUALIB = '-llua',\n    LUA_LIBDIR = '',/" $LUAROCKS_ROOT/config.lua

	# patch cfg.lua getting rid of hardcoded path c:/external/
	sed -i "s/\"c:\/external\/\"/\"$(echo $EXT_DIR | sed -e 's/\\\\/\\\//g')\"/" $LUAROCKS_LUA/luarocks/cfg.lua
	EXT_DIR=$(echo $EXT_DIR | sed -e 's/\\\\/\//g')

	# install cmake for windows
	if [ -f $EXT_DIR/bin/cmake.exe ]; then
		info "$CMAKE_NAME is already installed in $EXT_DIR"
	else
		rm -rf $LOS_ROOT/$CMAKE_PACKAGE $LOS_ROOT/$CMAKE_NAME
		download_file "$URL_REPO_OPENSOURCE/$CMAKE_PACKAGE" "$LOS_ROOT/$CMAKE_PACKAGE"
		check_status "downloading $URL_REPO_OPENSOURCE/$CMAKE_PACKAGE"
		info "extracting $CMAKE_NAME..."
		unzip -q $LOS_ROOT/$CMAKE_PACKAGE -d $LOS_ROOT
		info "installing $CMAKE_NAME to $EXT_DIR..."
		cp -rf --remove-destination $(makeunixpath $LOS_ROOT/$CMAKE_NAME/*) $EXT_DIR
		check_program cmake
		rm -rf $LOS_ROOT/$CMAKE_PACKAGE $LOS_ROOT/$CMAKE_NAME
	fi
fi

cd $LOS_ROOT
rm -rf $LOS_ROOT/$LUAROCKS_NAME

# check luarocks config
expect_file $LUAROCKS_CONFIG_LUA

# configure luarocks repository
info "set luarocks server to $URL_REPO_ROCKS"
echo -e "rocks_servers = \n{\n\t\"https://luarocks.org/\",\n\t\"$URL_REPO_ROCKS\"\n}" >> $LUAROCKS_CONFIG_LUA
sed -i "s/^-e//" $LUAROCKS_CONFIG_LUA
check_status "Editing $LUAROCKS_CONFIG_LUA"

sed -i "s/https/http/" $LUAROCKS_CONFIG_LUA
check_status "Patching $LUAROCKS_CONFIG_LUA"

echo "luarocks installation finished."

# installing lua-ex-api

rm -rf $LOS_ROOT/$LUA_EX_API_PACKAGE $LOS_ROOT/$LUA_EX_API_NAME
download_file "$URL_REPO_OPENSOURCE/$LUA_EX_API_PACKAGE" "$LOS_ROOT/$LUA_EX_API_PACKAGE"
check_status "downloading $URL_REPO_OPENSOURCE/$LUA_EX_API_PACKAGE"
info "extracting $LUA_EX_API_NAME..."
unzip -q $LOS_ROOT/$LUA_EX_API_PACKAGE -d $LOS_ROOT

echo "LUA=$LUAROCKS_TREE_DIR" > $LOS_ROOT/$LUA_EX_API_NAME/conf
echo "LUAINC=" >> $LOS_ROOT/$LUA_EX_API_NAME/conf
echo "LUALIB=-llua" >> $LOS_ROOT/$LUA_EX_API_NAME/conf
echo "POSIX_SPAWN=-DMISSING_POSIX_SPAWN" >> $LOS_ROOT/$LUA_EX_API_NAME/conf
echo "EXTRA=posix_spawn.o" >> $LOS_ROOT/$LUA_EX_API_NAME/conf
cd $LOS_ROOT/$LUA_EX_API_NAME
mkdir -p "$LUAROCKS_TREE_DIR/lib/lua/5.1"
if [ -n "$WINDIR" ]; then
	sed -i "s/TARGET_ARCH=.*/TARGET_ARCH=-m32/g" $LOS_ROOT/$LUA_EX_API_NAME/w32api/Makefile
	CC=gcc make mingw
	[ -f $LOS_ROOT/$LUA_EX_API_NAME/w32api/ex.dll ] || die "Failed compiling ex.dll"
	cp $LOS_ROOT/$LUA_EX_API_NAME/w32api/ex.dll $LUAROCKS_TREE_DIR/lib/lua/5.1
else
	CC="gcc" make linux "CFLAGS=-fpic -I/usr/include/lua5.1" "LDFLAGS=-L/usr/lib"
	[ -f $LOS_ROOT/$LUA_EX_API_NAME/posix/ex.so ] || die "Failed compiling ex.so"
	cp $LOS_ROOT/$LUA_EX_API_NAME/posix/ex.so $LUAROCKS_TREE_DIR/lib/lua/5.1
fi
cd $LOS_ROOT
rm -rf $LOS_ROOT/$LUA_EX_API_PACKAGE $LOS_ROOT/$LUA_EX_API_NAME

# create los-local.conf
mkdir -p "$(dirname $LOCAL_CONF)"

echo "-----------------------------------------------------------------------" > $LOCAL_CONF
echo "--                                                                   --" >> $LOCAL_CONF
echo "-- Copyright (C) 2003-2015,  Intelibo Ltd                            --" >> $LOCAL_CONF
echo "--                                                                   --" >> $LOCAL_CONF
echo "-- Project:       LOS                                                --" >> $LOCAL_CONF
echo "-- Filename:      $(basename $LOCAL_CONF)                                     --" >> $LOCAL_CONF
echo "-- Description:   LOS local configuration                            --" >> $LOCAL_CONF
echo "--                autogenerated by $(basename $this_script)                      --" >> $LOCAL_CONF
echo "--                on $(date -u)                    --" >> $LOCAL_CONF
echo "--                                                                   --" >> $LOCAL_CONF
echo "-----------------------------------------------------------------------" >> $LOCAL_CONF
echo ""  >> $LOCAL_CONF

echo "dir.base=$(echo $LOS_ROOT | sed -e 's/\\/\//g')" >> $LOCAL_CONF
echo "repo.username=$REPO_USER" >> $LOCAL_CONF
echo "repo.password=$REPO_PASS" >> $LOCAL_CONF
if [ -n "$WINDIR" ]]; then
	# default mingw
	echo "build.system=mingw" >> $LOCAL_CONF
else
	# default linux/macos
	OSNAME=$(uname | tr '[:upper:]' '[:lower:]')
	if [ $OSNAME = "darwin" ]; then
		OSNAME="macos"
	fi
	echo "build.system=$OSNAME" >> $LOCAL_CONF
fi
echo "build.arch=$(uname -m)" >> $LOCAL_CONF

if [ -n "$WINDIR" ]; then
	pathmunge $(makeunixpath $LUAROCKS_BIN)
	pathmunge $(makeunixpath $LUAROCKS_TREE_DIR/bin)

	IFS=:
	for dir in $PATH; do
		if [ "$dir" = "/usr/bin" ]; then
			dir="$EXT_DIR/msys/1.0/bin"
		fi
		if [ -n "$winpath" ]; then
			 winpath="$winpath;"
		fi
		 winpath="$winpath$(makewinpath "$dir")"
	done
	echo "@ECHO OFF" > $LOS_ROOT/losvars.cmd
	echo "set PATH=$winpath" >> $LOS_ROOT/losvars.cmd
	echo "set LUA_PATH=$(makewinpath "$LUAROCKS_LUA/?.lua")" >> $LOS_ROOT/losvars.cmd
	info "Run $(makewinpath "$LOS_ROOT/losvars.cmd") to set your environment"
else
	pathmunge $LUAROCKS_BIN
	pathmunge $LUAROCKS_TREE_DIR/bin
	echo "#!/bin/sh" > $LOS_ROOT/losvars.sh
	echo "export PATH=$PATH" >> $LOS_ROOT/losvars.sh
	echo "export LUA_PATH=$LUAROCKS_LUA/?.lua" >> $LOS_ROOT/losvars.sh
	info "source $LOS_ROOT/losvars.sh to set your environment"
fi
info "and then you can type luarocks install los"

echo "Bootstrap SUCCESS!"

