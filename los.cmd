@ECHO OFF
SET LOS_ARGS=--config-dump -Dhost.system=mingw,host.arch=32,repo.username=guest,repo.password=guest
SET PATH=c:\Users\alekm\los\luarocks\tree\bin;c:\TDM-GCC-32\bin;c:\TDM-GCC-32\msys\1.0\bin;c:\windows\system32
SET LOS=c:\Users\alekm\los\luarocks\tree\bin\los
%LOS% %LOS_ARGS% %*
