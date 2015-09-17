@echo off
set LOS_HOME=d:\Projects\AVIQ\LRun\projects\lua\los
set LUA_PATH=d:\Tools\Platform\Lua\LuaRocks\2.2\lua\?.lua;%LOS_HOME%\lua\?\init.lua;%LOS_HOME%\lua\?.lua
lua5.1 -lluarocks.require %LOS_HOME%\bin\los -Dhost.system=mingw32 %*
