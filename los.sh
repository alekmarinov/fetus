#!/bin/sh
err_exit(){ echo "$*"; exit 1; }

[ -z "$LRUN_SRC_HOME" ] && err_exit "LRUN_SRC_HOME is not set."
[ -e "$LRUN_SRC_HOME/config/lrun" ] || err_exit "'lrun' not found."

export LOS_HOME=${LOS_HOME:-"$LRUN_SRC_HOME/apps/los"}
export LUA_PATH="$LOS_HOME/lua/?.lua"

sh $LRUN_SRC_HOME/config/lrun "$LRUN_SRC_HOME/modules/lua/lrun/start.lua" los.main -c "$LOS_HOME/etc/los.conf" $*
