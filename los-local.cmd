@echo off
set OPATH=%PATH%

set PATH=C:\Users\alekm\los\tree\bin;C:\Users\alekm\los\2.2;\mingw\bin;D:\TDM-GCC-64\msys\1.0\bin;d:\TDM-GCC-64\bin;c:\Program Files (x86)\Git\bin\;c:\Windows\System32;d:\Tools\Platform\Python\2.6.6;D:\los\stage_32\bin
set LOS_HOME=D:\Projects\AVIQ\LRun\projects\lua\los
set LUA_PATH=C:\Users\alekm\los\2.2\lua\?.lua;%LOS_HOME%\lua\?\init.lua;%LOS_HOME%\lua\?.lua
lua -lluarocks.require %LOS_HOME%\bin\los -v -Ddir.base=D:/los,build.system=mingw,build.arch=i686,repo.username=guest,repo.password=guest %*
set PATH=%OPATH%
