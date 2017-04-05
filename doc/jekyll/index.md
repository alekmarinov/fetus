---
layout: default
---

# [](#what-fetus)What's Fetus?

Fetus is a package management system which uses a code to defines the rules for building software packages from source.
The main project goals include:
* Provisioning a building machine by describing the building Environment as a Code (EaC).
	- Version control your changes of the build envionment.
	- No longer be affraid of polluting your build environment. You can recreate it to clean state with just one command.
* Building a container image described as a code.
	- Creating a base container images is no longer an alchemy.
	- No more 3rd party base container images. The container can be fully defined by Fetus.
* Generating a Linux distribution.
* Package management utility for any Linux distribution.
* High level build definition for your projects.

## [](#howto-fetus)How to use Fetus?

Let start with something simple like intalling a package from source.

> gcc toolchain is required to be installed on the host operating system. 

### [](#gen-gcc)Generate C/C++ building environemnt.

```bash
$fetus install binutils_pass1 gcc_pass1 linux glibc libstdc++ binutils_pass2 gcc_pass2 coreutils bash
```

The command downloads, builds and installs gcc and all its dependent packages.

#### [](#chroot)Chroot in the newly created environment.

```bash
$fetus chroot
```

The command chroots into the directory where gcc has been installed where the enviornment is ready for your builds:

```bash
los>root:/$gcc
gcc: fatal error: no input files
compilation terminated:
```

## [](#install-fetus)How to install Fetus?

Installing fetus is as simple as this command line:

```bash
$curl http://fetus.intelibo.com/bootstrap.sh | sh
```
