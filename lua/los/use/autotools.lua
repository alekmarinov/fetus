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

function autotools.builddir()
	local dir = path.src.dir
	if autotools.opts.build_outside then
		dir = api.makepath(lfs.dirname(conf["dir.src"]), "build", lfs.basename(path.src.dir))
	end
	return dir
end

function autotools.make(...)
	local args = {...}
	local env
	if type(args[1]) == "table" then
		env = api.mkenv(args[1])
		table.remove(args, 1)
	end
	return api.executein(autotools.builddir(), conf["build.make"], env, unpack(args))
end

function autotools.configure(...)

	if conf["build.stage"] == 0 then

		--[[ ensure root permissions and install target 
		lfs.execout("id -u", function (uid)
			assert(uid == "0", "Root permissions required during stage 0")
		end)
		]]

		-- link install dir to location which will be available after chrooting in stage 1
		if not lfs.isdir(path.install.dir) then
			local installdir = path.install.dir
			if string.sub(installdir, 1, 1) == "/" then
				installdir = string.sub(installdir, 2)
			end
			local localinstalldir = api.makepath(conf["dir.sysroot"], installdir)
			log.i("mkdir "..localinstalldir)
			lfs.mkdir(localinstalldir)
			log.i("link "..localinstalldir.." -> "..path.install.dir)
			lfs.link(localinstalldir, path.install.dir)
		end
	end

	local args = {...}
	local opts =
	{
		ASFLAGS = conf["gcc.asflags"],
		CFLAGS = "-I"..path.install.inc.." "..conf["gcc.cflags"],
		CXXFLAGS = "-I"..path.install.inc.." "..conf["gcc.ccflags"],
		LDFLAGS = "-L"..path.install.lib.." "..conf["gcc.ldflags"]
	}
	local extra = args[1]
	local configurename = autotools.opts.configure or "configure"

	if type(extra) == "table" then
		-- process name=value args options
		for i, v in pairs(extra) do
			if type(i) == "string" then
				if opts[i] then
					opts[i] = opts[i].." "..v
				else
					opts[i] = v
				end
			else
				assert(type(i) == "number")
				table.insert(args, v)
			end
		end
		table.remove(args, 1)
	elseif not extra then
		table.remove(args, 1)
	else
		assert(type(extra) == "string")
	end
	if not autotools.opts.noprefix then
		opts["--prefix"] = opts["--prefix"] or path.install.dir
	end
	for i, v in pairs(opts) do
		table.insert(args, i.."="..v)
	end

	local env = api.mkenv{
		PKG_CONFIG_PATH = api.makepath(path.install.lib, "pkgconfig")..":"..api.makepath(path.install.dir, "share/pkgconfig")
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
	local blddir = autotools.builddir()
	assert(string.sub(srcdir, 1, 1) == string.sub(blddir, 1, 1), "Build directory at "..blddir.." must be at the same drive as source directory at "..srcdir)
	if autotools.opts.build_outside then
		lfs.delete(blddir)
	end
	assert(lfs.mkdir(blddir))

	-- finds relative path from build dir to source
	local relpath = {}
	while srcdir ~= blddir do
		srcdir = lfs.dirname(srcdir)
		blddir = lfs.dirname(blddir)
		table.insert(relpath, "..")
	end
	local configurepath = api.makepath(table.concat(relpath, "/"), string.sub(path.src.dir, 1 + string.len(srcdir)))
	assert(not env.PATH, "PATH can't be defined in autotools")
	return api.executein(autotools.builddir(), "sh", env, api.makepath(configurepath, configurename), unpack(args))
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

function autotools.install(...)
	local args = {...}
	table.insert(args, "install")
	assert(autotools.make(unpack(args)))
end

return autotools
