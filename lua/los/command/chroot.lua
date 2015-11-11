-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      chroot.lua                                         --
-- Description:   chroot into clean build environment                --
--                                                                   --
----------------------------------------------------------------------- 

local lfs         = require "lrun.util.lfs"
local config      = require "lrun.util.config"

local _G, ipairs, os, io, string, assert = _G, ipairs, os, io, string, assert

local print = print

module "los.command.chroot"

local function localpath(dir)
	local basedir = config.get(_G._conf, "dir.sysroot")
	return dir and lfs.concatfilenames(basedir, dir) or basedir
end

local function createfile(filename, content)
	local fd, err = io.open(filename, "w")
	if not fd then
		return nil, err
	end
	fd:write(content)
	fd:close()
	return true
end

function execute(...)
	-- check if we have root permissions
	local isroot
	lfs.execout("id -u", function (uid)
		isroot = uid == "0"
	end)
	if not isroot then
		return nil, "please execute chroot command with root permissions"
	end

	-- creating directories onto which the file systems will be mounted
	for _, dir in ipairs{"dev","proc","sys","run"} do
		lfs.mkdir(localpath(dir))
	end

	-- creating initial device nodes
	lfs.execute("mknod", "-m", "600", localpath("dev/console"), "c", "5", "1")
	lfs.execute("mknod", "-m", "666", localpath("dev/null"), "c", "1", "3")

	-- mounting and populating /dev
	lfs.execute("mount", "-v", "--bind", "/dev", localpath("dev"))

	-- mounting virtual kernel file systems
	lfs.execute("mount", "-vt", "devpts", "devpts", localpath("dev/pts"), "-o", "gid=5,mode=620")
	lfs.execute("mount", "-vt", "proc", "proc", localpath("proc"))
	lfs.execute("mount", "-vt", "sysfs", "sysfs", localpath("sys"))
	lfs.execute("mount", "-vt", "tmpfs", "tmpfs", localpath("run"))

	--[[
			if [ -h $LFS/dev/shm ]; then
			  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
			fi
	]]

	local sysroot = config.get(_G._conf, "dir.sysroot")
	local installdir = config.get(_G._conf, "dir.stage0.install")

	lfs.mkdir(localpath("etc"))
	assert(createfile(localpath("etc/passwd"), "root:x:0:0:root:/root:/bin/bash"))
	assert(createfile(localpath("etc/group"), "root:x:0:"))
	lfs.copy("/etc/resolv.conf", localpath("etc"))

	local rootdir = config.get(_G._conf, "dir.stage0.install")

	lfs.mkdir(localpath("bin"))
	for _, exec in ipairs{"cp", "bash","cat","echo","pwd","stty"} do
		lfs.link(lfs.concatfilenames(rootdir, "bin", exec), localpath("bin"))
	end

	lfs.mkdir(localpath("usr/bin"))
	lfs.link(lfs.concatfilenames(rootdir, "bin/perl"), localpath("usr/bin"))

	lfs.mkdir(localpath("usr/lib"))
	lfs.link(lfs.concatfilenames(rootdir, "lib/libgcc_s.so"), localpath("usr/lib"))
	lfs.link(lfs.concatfilenames(rootdir, "lib/libgcc_s.so.1"), localpath("usr/lib"))
	lfs.link(lfs.concatfilenames(rootdir, "lib/libstdc++.so"), localpath("usr/lib"))
	lfs.link(lfs.concatfilenames(rootdir, "lib/libstdc++.so.6"), localpath("usr/lib"))

	local rootdir2 = rootdir
	if string.sub(rootdir2, 1, 1) == "/" then
		rootdir2 = string.sub(rootdir2, 2)
	end
	lfs.execute("/bin/sed 's/"..rootdir2.."/usr/g' "..lfs.concatfilenames(rootdir, "lib/libstdc++.la").." > "..localpath("usr/lib/libstdc++.la"))
	lfs.link("bash", localpath("/bin/sh"))

	-- chroot
	local ok, err = lfs.execute("/usr/sbin/chroot",
		localpath(),
		rootdir.."/bin/env", "-i",
		"HOME=/root",
		"TERM="..os.getenv("TERM"),
		"PS1=los>\\u:\\w\\$",
		"PATH=/bin:/usr/bin:/sbin:/usr/sbin:"..rootdir.."/bin",
		rootdir.."/bin/bash", "--login", "+h")

	lfs.execute("umount", localpath("dev/pts"))
	lfs.execute("umount", localpath("dev"))
	lfs.delete(localpath("dev/console"))
	lfs.delete(localpath("dev/null"))
	lfs.delete(localpath("dev"))
	lfs.execute("umount", localpath("proc"))
	lfs.delete(localpath("proc"))
	lfs.execute("umount", localpath("sys"))
	lfs.delete(localpath("sys"))
	lfs.execute("umount", localpath("run"))
	lfs.delete(localpath("run"))
	lfs.delete(localpath("etc"))
	lfs.delete(localpath("bin"))
	lfs.delete(localpath("usr"))

	return ok, err
end
