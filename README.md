fetus
=====

*fetus* is a package management system building libraries from scratch including building the compiler twice, as the compiler have to be built with clean compiler as well.

Installing
----------

### binary distribution

### source distribution

Installation is composed by the following steps:

1. prepare host development and runtime environment _stage 0_
2. install luarocks configured with predefined rock repository
3. install los via luarocks
4. install development and runtime environment _stage 1_ via los
5. switch to _stage 1_
6. install luarocks and los via _stage 1_ environment (repeat step 2 and 3)
7. install development and runtime environment _stage 2_ via los (repeat step 4)
8. start dependency _clean_ development in the scope of _stage 2_ environment

  * install required packages

      gcc, lua, lua-devel, curl, tar, unzip, zzlib, zziplib, zziplib-devel

  * bootstraping

   Edit run-bootstrap.sh and configure 
   
```
TARGET_DIR=<location where to install luarocks and los packages>
```

```
LOS_REPO_USER=<username to los repository>
```

```
LOS_REPO_PASS=<password to los repository>
```

   $sh run-bootstrap.sh

   Add the following vars to your environment

```
PATH=$PATH:$TARGET_DIR/bin
```

```
LUA_PATH=$TARGET_DIR/share/lua/5.1/?.lua
```

```
$luarocks install los
```

License
-------

Copyright (c) 2015 Intelibo Ltd.
MIT licensed. See LICENSE for details.
