#!/bin/sh
##################################################################
##																##
## Copyright (C) 2003-2015, Intelibo Ltd						##
##																##
## Project:			los											##
## Filename:		gen-prebuilt-mingw.sh						##
## Description:		generates prebuilt toolchains from 			##
##					Fedora rpms.								##
##					Supported hosts:							##
##						linux-i686 and linux-x86_64				##
##					Supported targets:							##
##						mingw32 and mingw64						##
##					Resulting files:							##
##						prebuilt-mingw32-linux-i686.tar.bz2		##
##						prebuilt-mingw32-linux-x86_64.tar.bz2	##
##						prebuilt-mingw64-linux-i686.tar.bz2		##
##						prebuilt-mingw64-linux-x86_64.tar.bz2	##
##																##
##################################################################

#
generate()
{
	local arch=$1
	local bits=$2
	tmp="
	mingw${bits}-binutils
	mingw${bits}-cpp
	mingw${bits}-gcc-c++
	mingw${bits}-gcc
	mingw${bits}-pkg-config
	mingw${bits}-headers
	mingw${bits}-crt
	mingw${bits}-dlfcn-static
	mingw${bits}-winpthreads-static
	"

	rm -f $(pwd)/*.rpm
	setarch $arch yumdownloader $tmp
	rm -rf $(pwd)/etc
	rm -rf $(pwd)/usr
	for i in *.rpm; do rpm2cpio $i |cpio -idm; done
	rm -rf $(pwd)/etc
	mv usr $arch-mingw${bits}
	tar -cjf ../prebuilt-mingw${bits}-linux-$arch.tar.bz2 $arch-mingw${bits}
}

for arch in i686 x86_64; do
	for bits in 32 64; do
		rm -rf $arch-$bits
		mkdir -p $arch-$bits
		cd $arch-$bits
		generate $arch $bits
		cd ..
	done
done
