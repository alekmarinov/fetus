-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      cmake.lua                                          --
-- Description:   build implementation with cmake                    --
--                                                                   --
-----------------------------------------------------------------------

local function make(srcdir, target)
	local cmd = "mingw32-make"
	if target then
		cmd = cmd.." "..target
	end
	return lfs.execute("cd "..lfs.Q(srcdir).." && "..cmd)
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
	local dirname = extract(packname)
	local dirbuild = dirname.."-build"
	lfs.mkdir(dirbuild)
	print("building in "..dirbuild.." with cmake")
	local installprefix = lfs.path(config.get(_conf, "dir.install"))

	local cmakegen = config.get(_conf, "cmake.generator")
	if cmakegen then
		cmakegen = "-G \""..cmakegen.."\" "
	else
		cmakegen = ""
	end

	lfs.execute("cd "..lfs.Q(dirbuild).." && cmake "..cmakegen.."-DCMAKE_INSTALL_PREFIX="..lfs.Q(installprefix), lfs.path(dirname))
	local ok, err = make(dirbuild)
	if not ok then
		return nil, err
	end
	return dirbuild
end

function install()
	print("install")
	local dirbuild, err = build()
	if not dirbuild then
		return nil, err
	end
	return make(dirbuild, "install")
end
