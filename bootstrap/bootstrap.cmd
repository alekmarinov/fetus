@ECHO OFF
SET GIT_BIN=c:\Program Files (x86)\Git\bin\
SET MINGW_DIR=D:\TDM-GCC-64
SET LOS_ROOT=%USERPROFILE%\los

SET MSYS_DIR=%MINGW_DIR%\msys\1.0
SET MINGW_BIN=%MINGW_DIR%\bin
SET MINGW_LIB=%MINGW_DIR%\lib
SET MSYS_BIN=%MSYS_DIR%\bin

for %%F in ("%COMSPEC%") do set SYS32DIR=%%~dpF

if not exist %MINGW_DIR% goto MINGW_NOT_EXIST

SET PATH=%MINGW_BIN%;%MSYS_BIN%;%GIT_BIN%;%SYS32DIR%

if not exist %MSYS_BIN%\sh.exe mingw-get install sh
if not exist %MSYS_BIN%\readlink.exe mingw-get install msys-coreutils
if not exist %MSYS_BIN%\find.exe mingw-get install msys-findutils
if not exist %MSYS_BIN%\unzip.exe mingw-get install msys-unzip
if not exist %MSYS_BIN%\bzip2.exe mingw-get install msys-bzip2
if not exist %MSYS_BIN%\tar.exe mingw-get install msys-tar
if not exist %MSYS_BIN%\patch.exe mingw-get install msys-patch
if not exist %MSYS_BIN%\wget.exe mingw-get install msys-wget
if not exist %MINGW_BIN%\lua.exe mingw-get install "lua<5.2"
if not exist %MSYS_BIN%\which.exe copy %~dp0w32\tools\which.exe %MSYS_BIN%
if not exist %MSYS_BIN%\make.exe copy %~dp0w32\tools\make.exe %MSYS_BIN%

sh bootstrap.sh --los-root=%LOS_ROOT% %*
GOTO END

:MINGW_NOT_EXIST

echo Error! MinGW directory %MINGW_DIR% doesn't exists.

:END
