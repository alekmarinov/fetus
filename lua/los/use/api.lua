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
	log.i("download", path.src.url)
	local outfile = path.src.file
	rollback.push(lfs.delete, outfile)
	if not lfs.isfile(outfile) then
		local ok, err = lfs.mkdir(lfs.dirname(outfile))
		if not ok then
			return nil, err
		end
		log.i("downloading", path.src.url, outfile)
		assert(dw.download(path.src.url, outfile))
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
	local fd, err = io.open(file, w)
	if not fd then
		return nil, err
	end
	local ok, err = fd:write(text)
	fd:close()
	if not ok then
		return nil, err
	end
	return true
end

function api.copy(src, dst)
	rollback.push(lfs.delete, dst)
	if lfs.isfile(src) then
		lfs.mkdir(lfs.dirname(dst))
	else
		lfs.mkdir(dst)
	end

	log.i("copy ", src, dst)
	local ok, err = lfs.copy(src, dst)
	if not ok then
		return nil, err
	end
	rollback.pop()
end

api.makepath = lfs.concatfilenames
api.system = lfs.osname
hardware = lfs.hardware

return api
