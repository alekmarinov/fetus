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

STATUS=0
DIR_INSTALL=$(los --config-get dir.install)
mkdir -p $DIR_INSTALL
los list | while read name
do
	dir_install=$DIR_INSTALL/$name
	echo -n "Regenerating $name..."
	los -Ddir.install=$dir_install install $name > $DIR_INSTALL/$name.log 2>&1
	if [[ $? == 0 ]]; then
		echo "OK"
	else
		echo "FAILED"
		STATUS=1
	fi
done
exit $STATUS
