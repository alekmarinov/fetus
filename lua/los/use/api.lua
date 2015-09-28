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
	local cmd = "dos2unix"
	if table.getn{...} == 0 then
		cmd = cmd .. " *"
	end
	return lfs.executein(dir, cmd, ...)
end

function api.makepathdir(...)
	return lfs.addpathsep(api.makepath(...))
end

function api.catfile(file, text)
	local fd, err = io.open(file, "w")
	if not fd then
		return nil, err
	end
	local ok, err = fd:write(text)
	fd:close()
	return ok, err
end

function api.appendfile(file, text)
	local fd, err = io.open(file, "a+")
	if not fd then
		return nil, err
	end
	local ok, err = fd:write(text)
	fd:close()
	return ok, err
end

function api.readfile(file)
	local fd, err = io.open(file, "rb")
	if not fd then
		return nil, err
	end
	local ok, err = fd:read("*a")
	fd:close()
	return ok, err
end

function api.copy(src, dst)
	rollback.push(lfs.delete, dst)
	if lfs.isfile(src) then
		lfs.mkdir(lfs.dirname(dst))
	else
		lfs.mkdir(dst)
	end

	log.i("copy ", src, dst)
	assert(lfs.copy(src, dst))
	rollback.pop()
end

api.makepath = lfs.concatfilenames
api.system = lfs.osname

return api
