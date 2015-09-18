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

function make(srcdir, target)
	local cmd = "mingw32-make"
	if target then
		cmd = cmd.." "..target
	end
	log.i("making ", target)
	return lfs.executein(srcdir, cmd)
end

function configure(dirname)
	print("configure in "..dirname)
	return lfs.executein(dirname, "sh configure --prefix="..installdir().." \"INSTALL=install -c\"")
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
	ok, err = configure(dirname)
	if not ok then
		return nil, err
	end
	ok, err = make(dirname, "all")
	if not ok then
		return nil, err
	end

	if type(buildafter) == "function" then
		buildafter()
	end

	return true
end

function createinstalldirs()
	local instdir = installdir()
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
	return make(assert(srcdirfromurl(source, archdir)), "install")
end
