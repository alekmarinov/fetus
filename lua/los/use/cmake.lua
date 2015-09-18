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

local function make(srcdir, target)
	local cmd = "mingw32-make VERBOSE=1"
	if target then
		cmd = cmd.." "..target
	end
	log.i("make ", cmd)
	return lfs.executein(srcdir, cmd)
end

function build()
	log.i("build ")
	local packname, err = download(path.src.url)
	if not packname then
		return nil, err
	end
	local ok, err = unarch(packname)
	if not ok then
		return nil, err
	end
	local dirname = path.src.dir
	local dirbuild = path.src.dir.."-build"
	log.d("mkdir", dirbuild)
	local ok, err = lfs.mkdir(dirbuild)
	if not ok then
		return nil, err
	end
	log.i("building in "..dirbuild.." with cmake")
	local installprefix = path.install.dir

	local cmakegen = conf["cmake.generator"]
	if cmakegen then
		cmakegen = "-G \""..cmakegen.."\" "
	else
		cmakegen = ""
	end

	ok, err = lfs.execute("cd "..lfs.Q(dirbuild).." && cmake "..cmakegen.."-DCMAKE_INSTALL_PREFIX="..lfs.Q(installprefix), lfs.path(dirname))
	if not ok then
		return nil, err
	end
	ok, err = make(dirbuild)
	if not ok then
		return nil, err
	end
	return dirbuild
end

function install()
	log.i("install")
	local ok, err = build()
	if not ok then
		return nil, err
	end
	return make(path.src.dir.."-build", "install")
end

function clean()
	return lfs.delete(builddirfromurl(source))
end
