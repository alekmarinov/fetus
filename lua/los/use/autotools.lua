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
	if env then
		local penv = os.environ()
		for n, v in pairs(penv) do
			env[n] = v
		end
	end
	return api.executein(path.src.dir, conf["host.make"], env, target, ...)
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
	local env
	if type(args[1]) == "table" then
		env = args[1]
		table.remove(args, 1)
	end
	return api.executein(path.src.dir, "sh", env, "configure", "--prefix="..path.install.dir, unpack(args))
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
