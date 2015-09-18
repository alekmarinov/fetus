#!/bin/sh
NAME=los
VERSION=0.1-1
echo building $NAME $VERSION
luarocks make $NAME-$VERSION.rockspec
luarocks pack $NAME $VERSION
