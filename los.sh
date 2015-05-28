#!/bin/sh

LUA=`which lua`
export PATH=""
export LOS_HOME=$(pwd)
export LUA_PATH="$LOS_HOME/lua/?.lua"
export LUA_CPATH="$LOS_HOME/bin/lua/5.1/?.so;$LOS_HOME/bin/lua/5.1/?/?.so;$LOS_HOME/bin/lua/5.1/?/core.so;"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LOS_HOME/bin

$LUA "$LOS_HOME/lua/start.lua" los.main -c "$LOS_HOME/etc/los.conf" $*
