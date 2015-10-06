@ECHO OFF
SET GIT_BIN=C:\Program Files (x86)\Git\bin
SET MINGW64_DIR=C:\TDM-GCC-64
SET MSYS_DIR=%MINGW64_DIR%\msys\1.0
SET MINGW_BIN=%MINGW64_DIR%\bin
SET MINGW_LIB=%MINGW64_DIR%\lib
SET MSYS_BIN=%MSYS_DIR%\bin

for %%F in ("%COMSPEC%") do set SYS32DIR=%%~dpF

SET PATH=%MINGW_BIN%;%MSYS_BIN%;%GIT_BIN%;%SYS32DIR%

if not exist %MSYS_BIN%\which.exe copy %~dp0tools-w32\which.exe %MSYS_BIN%
if not exist %MSYS_BIN%\sh.exe mingw-get install sh
if not exist %MSYS_BIN%\readlink.exe mingw-get install msys-coreutils
if not exist %MSYS_BIN%\unzip.exe mingw-get install msys-unzip
if not exist %MSYS_BIN%\tar.exe mingw-get install msys-tar
if not exist %MSYS_BIN%\patch.exe mingw-get install msys-patch
if not exist %MSYS_BIN%\wget.exe mingw-get install msys-wget
if not exist %MINGW_BIN%\lua.exe mingw-get install "lua<5.2"

SET BOOTSTRAP_SCRIPT=bootstrap.sh
sh run-bootstrap.sh %*

:END
