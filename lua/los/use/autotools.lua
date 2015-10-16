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

function autotools.envmake(target, env, ...)
	return api.executein(path.src.dir, conf["build.make"], env, target, ...)
end

function autotools.make(target, ...)
	return autotools.envmake(target, nil, ...)
end

function autotools.configure(...)
	local args = {...}
	local opts =
	{
		CFLAGS = "-I"..path.install.inc.." "..conf["gcc.cflags"],
		CXXFLAGS = "-I"..path.install.inc.." "..conf["gcc.ccflags"],
		LDFLAGS = "-L"..path.install.lib.." "..conf["gcc.ldflags"]
	}
	local extra = args[1]
	if type(extra) == "table" then
		for i, v in pairs(extra) do
			if opts[i] then
				opts[i] = opts[i].." "..v
			else
				opts[i] = v
			end
		end
		table.remove(args, 1)
	end
	for i, v in pairs(opts) do
		table.insert(args, i.."="..v)
	end

	local env = api.mkenv{
		PATH = os.getenv("PATH")..conf["build.pathsep"]..path.install.bin,
		PKG_CONFIG_PATH = api.makepath(path.install.lib, "pkgconfig")
	}
	if type(args[1]) == "table" then
		table.fastcopy(args[1], env)
		table.remove(args, 1)
	end
	return api.executein(path.src.dir, "sh", env, "configure", "--prefix="..path.install.dir, unpack(args))
end

local installdirs = {"bin", "lib", "include", "man/man1"}

local function createinstalldirs()
	for _, dir in ipairs(installdirs) do
		local directory = lfs.concatfilenames(path.install.dir, dir)
		log.d("deleteifempty", directory)
		local ok, err = lfs.mkdir(directory)
		if not ok then
			return nil, err
		end
	end
end

local function deleteinstalldirsifempty()
	for _, dir in ipairs(installdirs) do
		local directory = lfs.concatfilenames(path.install.dir, dir)
		log.d("deleteifempty", directory)
		lfs.deleteifempty(lfs.concatfilenames(path.install.dir, dir))
	end
	return true
end

function autotools.install()
	log.i("install")
	local ok, err = build()
	if not ok then
		return nil, err
	end
	rollback.push("deleteinstalldirsifempty", deleteinstalldirsifempty)
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
