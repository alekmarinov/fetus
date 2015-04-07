#!/bin/sh

export PATH=""
export LOS_HOME=$(pwd)
export LUA_PATH="$LOS_HOME/lua/?.lua"
export LUA_CPATH="$LOS_HOME/bin/lua/5.1/?.so;$LOS_HOME/bin/lua/5.1/?/?.so;$LOS_HOME/bin/lua/5.1/?/core.so;"
$LOS_HOME/bin/lua51 "$LOS_HOME/lua/start.lua" los.main -c "$LOS_HOME/etc/los.conf" $*
