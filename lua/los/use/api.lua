-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      api.lua                                            --
-- Description:   exported api to los module                         --
--                                                                   --
-----------------------------------------------------------------------

-- base api imported and working in los module environment

local api = {}

function api.map(f, ...)
	local res = {}
	for _, v in ipairs{...} do
		table.insert(res, f(v))
	end
	return unpack(res)
end

function api.reduce(f, ...)
	local res = nil
	for _, v in ipairs{...} do
		res = f(res, v)
	end
	return res
end

function api.download()
	local url = path.src.url
	log.i("download", url)
	local outfile = path.src.file
	rollback.push("delete "..outfile, lfs.delete, outfile)
	if not lfs.isfile(outfile) then
		local ok, err = lfs.mkdir(lfs.dirname(outfile))
		if not ok then
			return nil, err
		end
		local urlmd5 = url..".md5"
		local outfilemd5 = outfile..".md5"
		log.i("downloading", urlmd5, outfilemd5)
		local srcmd5
		if dw.download(urlmd5, outfilemd5) then
			srcmd5 = assert(api.readfile(outfilemd5))
			srcmd5 = string.upper(string.sub(srcmd5, 1, 32))
		else
			lfs.delete(outfilemd5)
		end

		log.i("downloading", url, outfile)
		assert(dw.download(url, outfile))

		if srcmd5 then
			local md5sum = api.readfile(outfile)
			md5sum = string.upper(md5.sumhexa(md5sum))
			if  srcmd5 ~= md5sum then
				error("invalid md5 sum, expected "..srcmd5..", got "..md5sum)
			end
			log.i(outfile.." matches md5 "..md5sum)
		else
			log.i(urlmd5.." is not available, skipping md5 check")
		end
	else
		log.i("already downloaded file", outfile)
	end
	rollback.pop()
	return outfile
end

function api.unarch()
	log.i("unarch "..path.src.file)
	rollback.push("delete "..path.src.dir, lfs.delete, path.src.dir)
	-- delete any existing directory for clean extraction
	log.d("delete "..path.src.dir)
	lfs.delete(path.src.dir)
	local srcdir = conf["dir.src"]
	if package.archdir == "" then
		srcdir = path.src.dir
		lfs.mkdir(srcdir)
	end
	log.d("unarch "..path.src.file.." in "..srcdir)
	assert(extract.unarch(path.src.file, srcdir))
	rollback.pop()
end

function api.patch(level)
	level = level or 1
	log.i("patch "..path.src.dir)
	local patch = package.patch
	if type(patch) == "string" then
		patch = {patch}
	elseif type(patch) == "table" then
		if patch[conf["build.system"]] then
			patch = {patch}
		end
	else
		assert(nil, "Invalid package.patch value, expected string or table, got "..type(patch))
	end
	for _, p in ipairs(patch) do
		if type(p) == "table" then
			p = p[conf["build.system"]] or p[1]
		end
		if p then
			local patchfile = api.makepath(lfs.dirname(lospecfile), p)
			api.executein(path.src.dir, "patch", nil, "-Np"..level, "-i", patchfile)
		else
			if not p then
				log.i("no patch for build system "..conf["build.system"])
			end
		end
	end
end

function api.dos2unix(dir, ...)
	assert(type(dir) == "string")

	local cmd = "dos2unix -f"
	if table.getn{...} == 0 then
		cmd = cmd .. " *"
	end
	return lfs.executein(dir, cmd, ...)
end

function api.makepathdir(...)
	return lfs.addpathsep(api.makepath(...))
end

function api.catfile(file, text, opentype)
	assert(type(file) == "string")
	assert(type(text) == "string")

	local fd, err = io.open(file, opentype or "w")
	if not fd then
		return nil, err
	end
	local ok, err = fd:write(text)
	fd:close()
	return ok, err
end

function api.appendfile(file, text)
	assert(type(file) == "string")
	assert(type(text) == "string")

	local fd, err = io.open(file, "a+")
	if not fd then
		return nil, err
	end
	local ok, err = fd:write(text)
	fd:close()
	return ok, err
end

function api.readfile(file)
	assert(type(file) == "string")

	local fd, err = io.open(file, "rb")
	if not fd then
		return nil, err
	end
	local ok, err = fd:read("*a")
	fd:close()
	return ok, err
end

function api.copy(src, dst)
	assert(type(src) == "string")
	assert(type(dst) == "string")

	if lfs.isfile(src) then
		lfs.mkdir(lfs.dirname(dst))
	else
		lfs.mkdir(dst)
	end

	log.i("copy ", src, dst)
	assert(lfs.copy(src, dst))
end

function api.executein(dir, filename, env, ...)
	assert(not dir or type(dir) == "string", "expected string for argument 1, got "..type(dir))
	assert(type(filename) == "string", "expected string for argument 2, got "..type(filename))
	assert(not env or type(env) == "table", "expected table for argument 3, got "..type(env))
	for i, v in ipairs{...} do
		assert(type(v) == "string", "expected string for argument "..(i + 3)..", got "..type(v))
	end

	local cdir = lfs.currentdir()
	if dir then
		lfs.chdir(dir)
	end
	local cmd = table.concat({filename, api.map(function(v) return lfs.Q(v) end, ...)}, " ")
	-- log environment
	if env then
		local envlog = {}
		for i, v in pairs(env) do
			if table.indexof({"PKG_CONFIG_PATH","LD_LIBRARY_PATH","PATH"}, i) then
				table.insert(envlog, i.."="..v)
			end
		end
		cmd = table.concat(envlog, " ").." "..cmd
	end

	log.i(dir..":", cmd)
	local pid = assert(os.spawn(filename, {args={...}, env=env}))
	lfs.chdir(cdir)
	local exitcode = pid:wait(pid)
	if exitcode ~= 0 then
		error("Command "..cmd.." failed")
	end
	return true
end

function api.execute(...)
	return api.executein(nil, ...)
end

function api.isinstalled(files)
	local installed = true
	for filetype, instfiles in pairs(files) do
		if type(instfiles) == "string" then
			instfiles = {instfiles}
		end
		for _, file in ipairs(instfiles) do
			-- if file specified as absolute path
			if not lfs.isfile(file) then
				local instdir, filex
				if filetype == "h" then
					instdir = path.install.inc
				elseif filetype == "pc" then
					instdir = {
						api.makepath(path.install.lib, "pkgconfig"),
						api.makepath(path.install.dir, "share/pkgconfig")
					}
					filex = file..".pc"
				elseif filetype == "dynamic" then
					if conf["host.system"] == "mingw" then
						instdir = path.install.bin
					else
						instdir = path.install.lib
					end
					filex = string.format(conf["host.dynamic.format"], file)
				elseif filetype == "static" then
					instdir = path.install.lib
					filex = string.format(conf["host.static.format"], file)
				elseif filetype == "exec" then
					instdir = path.install.bin
					filex = string.format(conf["host.exec.format"], file)
				end

				if instdir then
					if type(instdir) == "string" then
						instdir = {instdir}
					end
					local any = false
					local missing = {}
					for _, instdir in ipairs(instdir) do
						local instfile = lfs.concatfilenames(instdir, file)
						local instfilex
						if filex then
							instfilex = lfs.concatfilenames(instdir, filex)
						end
						if not (lfs.isfile(file) or lfs.isfile(instfile) or (instfilex and lfs.isfile(instfilex))) then
							if instfilex then
								instfile = instfile.." or "..instfilex
							end
							table.insert(missing, filetype.." file "..file.." or "..instfile.." is not installed")
						else
							any = true
						end
					end
					if not any then
						log.d(table.concat(missing, "\n"))
					end
					installed = installed and any
				else
					log.w("Unknown file type "..filetype.." for file "..file)
				end
			end
		end
	end
	return installed
end

api.makepath = lfs.concatfilenames
api.system = lfs.osname

function api.staticname(name)
	return string.format(conf["host.static.format"], name)
end

function api.dynamicname(name)
	return string.format(conf["host.dynamic.format"], name)
end

function api.execname(name)
	return string.format(conf["host.exec.format"], name)
end

function api.gsubfile(filename, ...)
	local args = {...}
	local gsubargs = {}
	if type(args[1]) == "table" then
		gsubargs = args
	else
		gsubargs = {args}
	end
	for _, a in ipairs(gsubargs) do
		assert(type(a) == "table")
	end

	local linesiter, err = io.lines(filename)
	if not linesiter then
		return nil, err
	end
	local tmpname = os.tmpname()
	local tmp, err = io.open(tmpname, "w")
	if not tmp then
		return nil, err
	end
	for line in linesiter do
		for _, gsuba in ipairs(gsubargs) do
			line = string.gsub(line, unpack(gsuba))
		end
		tmp:write(line)
		tmp:write("\n")
	end
	tmp:close()
	lfs.delete(filename)
	lfs.move(tmpname, filename)
end

function api.isarch32(arch)
	arch = tostring(arch)
	return arch == "i686" or arch == "32"
end

function api.mkenv(env)
	if not env then
		return nil
	end
	local penv = os.environ()
	for n, v in pairs(penv) do
		if not env[n] then
			env[n] = v
		end
	end
	return env
end

return api 
