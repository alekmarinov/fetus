@ECHO OFF
SET LOS_HOME=D:\Projects\AVIQ\LRun\app\los
SET LUA_PATH=%LOS_HOME%\lua\?.lua
lua51 "%LOS_HOME%\lua\start.lua" los.main -c "%LOS_HOME%/etc/los.conf" %*
