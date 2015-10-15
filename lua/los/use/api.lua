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
	rollback.push(lfs.delete, outfile)
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
	rollback.push(lfs.delete, path.src.dir)
	assert(extract.unarch(path.src.file, conf["dir.src"]))
	rollback.pop()
end

function api.patch()
	log.i("patch "..path.src.dir)
	local patch = package.patch
	if type(patch) == "table" then
		patch = patch[conf["host.system"]] or patch[1]
	end
	if patch then
		local patchfile = api.makepath(lfs.dirname(lospecfile), patch)
		lfs.executein(path.src.dir, "patch", "-p0", "-i", patchfile)
	else
		if not patch then
			log.i("no patch for host system "..conf["host.system"])
		end
	end
end

function api.dos2unix(dir, ...)
	assert(type(dir) == "string")

	local cmd = "dos2unix"
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

	local cdir = lfs.currentdir()
	if dir then
		lfs.chdir(dir)
	end
	local cmd = table.concat({filename, api.map(function(v) return lfs.Q(v) end, ...)}, " ")
	-- log environment
	if env then
		local envlog = {}
		for i, v in pairs(env) do
			table.insert(envlog, i.."="..v)
		end
		log.d("env: "..table.concat(envlog, ";;"))
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
				elseif filetype == "dynamic" then
					if conf["target.system"] == "mingw" then
						instdir = path.install.bin
					else
						instdir = path.install.lib
					end
					filex = string.format(conf["target.dynamic.format"], file)
				elseif filetype == "static" then
					instdir = path.install.lib
					filex = string.format(conf["target.static.format"], file)
				elseif filetype == "exec" then
					instdir = path.install.bin
					filex = string.format(conf["target.exec.format"], file)
				end

				if instdir then
					local instfile = lfs.concatfilenames(instdir, file)
					local instfilex
					if filex then
						instfilex = lfs.concatfilenames(instdir, filex)
					end
					if not (lfs.isfile(file) or lfs.isfile(instfile) or (instfilex and lfs.isfile(instfilex))) then
						if instfilex then
							instfile = instfile.." or "..instfilex
						end
						log.d(filetype.." file "..file.." or "..instfile.." is not installed")
						installed = false
					end
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
	return string.format(conf["target.static.format"], name)
end

function api.dynamicname(name)
	return string.format(conf["target.dynamic.format"], name)
end

function api.execname(name)
	return string.format(conf["target.exec.format"], name)
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

return api 
