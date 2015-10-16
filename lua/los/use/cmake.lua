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
	return api.executein(srcdir, conf["cmake.make"], nil, "VERBOSE=1", target)
end

function cmake.build(...)
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
	opts["-DCMAKE_C_FLAGS"] = opts.CFLAGS
	opts.CFLAGS = nil
	opts["-DCMAKE_CXX_FLAGS"] = opts.CXXFLAGS
	opts.CXXFLAGS = nil
	opts["-DCMAKE_LD_FLAGS"] = opts.LDFLAGS
	opts.LDFLAGS = nil

	for i, v in pairs(opts) do
		table.insert(args, i.."="..v)
	end

	local pathsep = conf["build.pathsep"]
	local env = api.mkenv{
		PATH = os.getenv("PATH")..pathsep..path.install.bin
	}
	if type(args[1]) == "table" then
		table.fastcopy(args[1], env)
		table.remove(args, 1)
	end

	local dirbuild = path.src.dir.."-build"
	assert(lfs.mkdir(dirbuild))

	table.insert(args, "-DCMAKE_INSTALL_PREFIX="..path.install.dir)
	table.insert(args, path.src.dir)

	local cmakegen = conf["cmake.generator"]
	if cmakegen then
		table.insert(args, 1, cmakegen)
		table.insert(args, 1, "-G")
	end
	log.i("building in "..dirbuild.." with cmake")

	local ok = pcall(api.executein, dirbuild, "cmake", env, unpack(args))
	if not ok then
		if conf["host.system"] == "mingw" then
			-- cmake may fail once when find sh.exe in PATH, but next try succeeds
			api.executein(dirbuild, "cmake", env, unpack(args))
		end
	end

	return make(dirbuild)
end

function cmake.install()
	return make(path.src.dir.."-build", "install")
end

function cmake.clean()
	return lfs.delete(path.src.dir.."-build")
end

return cmake
