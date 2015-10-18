#!/bin/sh
##################################################################
##																##
## Copyright (C) 2003-2015, Intelibo Ltd						##
##																##
## Project:       los											##
## Filename:      batch_clean_build.sh							##
## Description:   builds all packages from the scratch			##
##																##
##################################################################

LOS=los.bat

DIR_INSTALL=$($LOS --config-get dir.install)

# $LOS list
cat list.test | while read name
do
	dir_install=$DIR_INSTALL/$name
	echo -n "Regenerating $dir_install..."
	$LOS -Ddir.install=$dir_install install $name > $DIR_INSTALL/$name.log 2>&1
	if [[ $? == 0 ]]; then
		echo "OK"
	else
		echo "FAILED"
	fi
done
