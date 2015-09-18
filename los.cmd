@echo off
set OPATH=%PATH%
set PATH=D:\Tools\Platform\Lua\LuaRocks\2.2;D:\Tools;D:\Tools\GnuWin32\bin;D:\Tools\CMake\bin;D:\Projects\AVIQ\LRun\rocks\bin;C:\MinGW\bin;c:\msys\1.0\bin
set LOS_HOME=d:\Projects\AVIQ\LRun\projects\lua\los
set LUA_PATH=d:\Tools\Platform\Lua\LuaRocks\2.2\lua\?.lua;%LOS_HOME%\lua\?\init.lua;%LOS_HOME%\lua\?.lua
lua5.1 -lluarocks.require %LOS_HOME%\bin\los -Dhost.system=mingw32,repo.username=alek,repo.password=aviqa2 %*
set PATH=%OPATH%
