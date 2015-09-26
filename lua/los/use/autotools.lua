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

local autotools = {}

function autotools.make(target, ...)
	local cmd = conf["host.make"].." "..table.concat({...}, " ")
	if target then
		cmd = cmd.." "..target
	end
	log.i(cmd)
	return lfs.executein(path.src.dir, cmd)
end

function autotools.configure()
	log.i("configure in "..path.src.dir)
	return lfs.executein(path.src.dir, "sh configure --prefix="..path.install.dir.." \"INSTALL=install -c\"")
end

local installdirs = {"bin", "lib", "include", "man/man1"}

local function createinstalldirs()
	for _, dir in ipairs(installdirs) do
		local ok, err = lfs.mkdir(lfs.concatfilenames(path.install.dir, dir))
		if not ok then
			return nil, err
		end
	end
end

local function deleteinstalldirsifempty()
	for _, dir in ipairs(installdirs) do
		lfs.deleteifempty(lfs.concatfilenames(path.install.dir, dir))
	end
end

function autotools.install()
	log.i("install")
	local ok, err = build()
	if not ok then
		return nil, err
	end
	rollback.push(deleteinstalldirsifempty)
	local ok, err = createinstalldirs()
	if not ok then
		return nil, err
	end
	ok, err = make("install")
	if not ok then
		return nil, err
	end
	rollback.pop()
end

return autotools
