#!/bin/sh
##################################################################
##																##
## Copyright (C) 2003-2015, Intelibo Ltd						##
##																##
## Project:       los											##
## Filename:      batch_gcc.sh									##
## Description:   builds gcc from the scratch					##
##																##
##################################################################

los -v install binutils_pass1 gcc_pass1 linux glibc libstdc++ binutils_pass2 gcc_pass2 coreutils bash
