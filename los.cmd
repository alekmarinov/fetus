@ECHO OFF
SET PATH=
SET LOS_HOME=.
SET LUA_CPATH=%LOS_HOME%\bin\lua\5.1\?.dll
SET LUA_PATH=%LOS_HOME%\lua\?.lua
bin\lua51 "%LOS_HOME%\lua\start.lua" los.main -c "%LOS_HOME%/etc/los.conf" %*
