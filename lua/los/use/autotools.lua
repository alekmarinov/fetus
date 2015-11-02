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

local function builddir()
	local dir = path.src.dir
	if autotools.opts.build_out_src then
		dir = api.makepath(lfs.dirname(conf["dir.src"]), "build", lfs.basename(path.src.dir))
	end
	return dir
end

function autotools.make(...)
	local args = {...}
	local env = api.mkenv{
		LD_LIBRARY_PATH = path.install.lib
	}
	if type(args[1]) == "table" then
		table.fastcopy(args[1], env)
		table.remove(args, 1)
	end
	return api.executein(builddir(), conf["build.make"], env, unpack(args))
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
	local configurename = autotools.opts.configure or "configure"

	if type(extra) == "table" then
		for i, v in pairs(extra) do
			if opts[i] then
				opts[i] = opts[i].." "..v
			else
				opts[i] = v
			end
		end
		table.remove(args, 1)
	elseif not extra then
		table.remove(args, 1)
	else
		assert(type(extra) == "string")
	end
	opts["--prefix"] = opts["--prefix"] or path.install.dir
	for i, v in pairs(opts) do
		table.insert(args, i.."="..v)
	end

	local env = api.mkenv{
		PATH = os.getenv("PATH")..conf["build.pathsep"]..path.install.bin,
		PKG_CONFIG_PATH = api.makepath(path.install.lib, "pkgconfig")..":"..api.makepath(path.install.dir, "share/pkgconfig"),
		LD_LIBRARY_PATH = path.install.lib
	}
	if type(args[1]) == "table" then
		table.fastcopy(args[1], env)
		table.remove(args, 1)
	elseif not args[1] then
		table.remove(args, 1)
	else
		assert(type(args[1]) == "string")
	end

	local srcdir = path.src.dir
	local blddir = builddir()
	assert(string.sub(srcdir, 1, 1) == string.sub(blddir, 1, 1), "Build directory at "..blddir.." must be at the same drive as source directory at "..srcdir)
	assert(lfs.mkdir(blddir))

	-- finds relative path from build dir to source
	local relpath = {}
	while srcdir ~= blddir do
		srcdir = lfs.dirname(srcdir)
		blddir = lfs.dirname(blddir)
		table.insert(relpath, "..")
	end
	local configurepath = api.makepath(table.concat(relpath, "/"), string.sub(path.src.dir, 1 + string.len(srcdir)))
	return api.executein(builddir(), "sh", env, api.makepath(configurepath, configurename), unpack(args))
end

local installdirs = {"bin", "lib", "include", "man", "man/man1"}

local function createinstalldirs()
	for _, dir in ipairs(installdirs) do
		local directory = lfs.concatfilenames(path.install.dir, dir)
		log.d("mkdir", directory)
		local ok, err = lfs.mkdir(directory)
		if not ok then
			return nil, err
		end
	end
	return true
end

local function deleteinstalldirsifempty()
	for i = #installdirs, 1, -1 do
		local dir = installdirs[i]
		local directory = lfs.concatfilenames(path.install.dir, dir)
		log.d("deleteifempty", directory)
		lfs.deleteifempty(lfs.concatfilenames(path.install.dir, dir))
	end
	return true
end

function autotools.install(...)
	rollback.push("deleteinstalldirsifempty", deleteinstalldirsifempty)
	assert(createinstalldirs())
	assert(autotools.make("install", ...))
	rollback.pop()
end

return autotools
