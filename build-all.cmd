@ECHO OFF
CALL los-local install termcap
CALL los-local install readline
CALL los-local install lua
CALL los-local install zlib
CALL los-local install libffi
CALL los-local install pthreads
CALL los-local install libiconv
CALL los-local install gettext
CALL los-local install glib
CALL los-local install pkg-config
CALL los-local install libjpeg
CALL los-local install libpng
CALL los-local install pixman
CALL los-local install freetype
CALL los-local install cairo
CALL los-local install "sdl == 1.2.15"
CALL los-local install avgl
CALL los-local install libia
