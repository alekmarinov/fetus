@ECHO OFF
SET LOS_HOME=%LRUN_SRC_HOME%\apps\los
SET LUA_PATH=%LOS_HOME%\lua\?.lua
%LRUN_SRC_HOME%\config\lrun.cmd "%LRUN_SRC_HOME%\modules\lua\lrun\start.lua" los.main -c "%LOS_HOME%/etc/los.conf" %*
