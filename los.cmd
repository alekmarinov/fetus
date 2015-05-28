@ECHO OFF
REM SET PATH="%LOS_HOME%/bin
SET LOS_HOME=d:\Projects\AVIQ\LRun\app\los
SET LUA_CPATH=%LOS_HOME%\bin\lua\5.1\?.dll
SET LUA_PATH=%LOS_HOME%\lua\?.lua
bin\lua51 "%LOS_HOME%\lua\start.lua" los.main -c "%LOS_HOME%/etc/los.conf" %*
