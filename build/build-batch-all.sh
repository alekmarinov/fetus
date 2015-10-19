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

los -q -e $(dirname $(readlink -f $0))/build_batch_all.lua
