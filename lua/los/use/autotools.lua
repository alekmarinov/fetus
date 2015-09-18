-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      autotools.lua                                      --
-- Description:   build implementation with autotools                --
--                                                                   --
-----------------------------------------------------------------------

-- autotool api imported and working in los module environment

function make(target, ...)
	local cmd = "mingw32-make"
	if target then
		cmd = cmd.." "..table.concat({...}, " ").." "..target
	end
	log.i("make ", cmd)
	return lfs.executein(path.src.dir, cmd)
end

function configure(dirname)
	log.i("configure in "..dirname)
	return lfs.executein(dirname, "sh configure --prefix="..path.install.dir.." \"INSTALL=install -c\"")
end

function build()
	print("build")
	local packname, err = download(path.src.url)
	if not packname then
		return nil, err
	end
	local ok, err = unarch(packname)
	if not ok then
		return nil, err
	end
	local dirname = path.src.dir
	ok, err = configure(dirname)
	if not ok then
		return nil, err
	end
	ok, err = make("all")
	if not ok then
		return nil, err
	end

	if type(buildafter) == "function" then
		buildafter()
	end

	return true
end

function createinstalldirs()
	local instdir = path.install.dir
	lfs.mkdir(lfs.concatfilenames(instdir, "bin"))
	lfs.mkdir(lfs.concatfilenames(instdir, "lib"))
	lfs.mkdir(lfs.concatfilenames(instdir, "include"))
	lfs.mkdir(lfs.concatfilenames(instdir, "man/man1"))
end

function install()
	print("install")
	local ok, err = build()
	if not ok then
		return nil, err
	end
	createinstalldirs()
	return make("install")
end
