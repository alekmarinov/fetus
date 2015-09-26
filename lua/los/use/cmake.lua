-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      cmake.lua                                          --
-- Description:   build implementation with cmake                    --
--                                                                   --
-----------------------------------------------------------------------

-- cmake api imported and working in los module environment

local cmake = {}

local function make(srcdir, target)
	local cmd = conf["cmake.make"].." VERBOSE=1"
	if target then
		cmd = cmd.." "..target
	end
	log.i(cmd)
	return lfs.executein(srcdir, cmd)
end

function cmake.build()
	log.i("build")
	local dirbuild = path.src.dir.."-build"
	local ok, err = lfs.mkdir(dirbuild)
	if not ok then
		return nil, err
	end
	log.i("building in "..dirbuild.." with cmake")

	local cmakegen = conf["cmake.generator"]
	if cmakegen then
		cmakegen = "-G \""..cmakegen.."\" "
	else
		cmakegen = ""
	end

	ok, err = lfs.execute("cd "..lfs.Q(dirbuild).." && cmake "..cmakegen.."-DCMAKE_INSTALL_PREFIX="..lfs.Q(path.install.dir), path.src.dir)
	if not ok then
		return nil, err
	end
	ok, err = make(dirbuild)
	if not ok then
		return nil, err
	end
	return true
end

function cmake.install()
	log.i("install")
	return make(path.src.dir.."-build", "install")
end

function cmake.clean()
	log.i("clean")
	return lfs.delete(path.src.dir.."-build")
end

return cmake
