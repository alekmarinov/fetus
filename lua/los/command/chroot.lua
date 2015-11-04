-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      chroot.lua                                         --
-- Description:   chroot into clean build environment                --
--                                                                   --
----------------------------------------------------------------------- 

local _conf = _G._conf

module "los.command.chroot"

local function localpath(dir)
	local basedir = config.get(_conf, "dir.base")
	return dir and lfs.concatfilenames(basedir, dir) or basedir
end

function execute(...)
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

	-- chroot
	lfs.execute("chroot",
		localpath(),
		"/tools/bin/env", "-i",
		"HOME=/root",
		"TERM="..os.getenv("TERM"),
		"PS1='\u:\w\$ '",
		"PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin",
		"/tools/bin/bash", "--login", "+h")
end
