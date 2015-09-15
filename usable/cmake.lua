-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      cmake.lua                                          --
-- Description:   build implementation with cmake                    --
--                                                                   --
-----------------------------------------------------------------------

local function builddirfromurl(url)
	return srcdirfromurl(url, archdir).."-build"
end

local function make(srcdir, target)
	local cmd = "mingw32-make"
	if target then
		cmd = cmd.." "..target
	end
	print("making ", target)
	return lfs.executein(srcdir, cmd)
end

function build()
	print("build")
	if __dependencies then
		print("install dependencies")
		for _, pck in ipairs(__dependencies) do
			pck:install()
		end
	end
	local packname, err = download(source)
	if not packname then
		return nil, err
	end
	local ok, err = extract(packname)
	if not ok then
		return nil, err
	end
	local dirname = assert(srcdirfromurl(source, archdir))
	local dirbuild = builddirfromurl(source)
	print("mkdir", dirbuild)
	local ok, err = lfs.mkdir(dirbuild)
	if not ok then
		return nil, err
	end
	print("building in "..dirbuild.." with cmake")
	local installprefix = lfs.path(config.get(_conf, "dir.install"))

	local cmakegen = config.get(_conf, "cmake.generator")
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
	print("install")
	local ok, err = build()
	if not ok then
		return nil, err
	end
	return make(builddirfromurl(source), "install")
end

function clean()
	return lfs.delete(builddirfromurl(source))
end
