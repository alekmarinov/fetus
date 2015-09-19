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
	log.i("download "..path.src.url)
	local outfile = path.src.file
	if not lfs.isfile(outfile) then
		local ok, err = lfs.mkdir(lfs.dirname(outfile))
		if not ok then
			return nil, err
		end
		ok, err = dw.download(path.src.url, outfile)
		if not ok then
			return nil, err
		end
	end
	return outfile
end

function api.unarch()
	log.i("unarch "..path.src.file)
	return extract.unarch(path.src.file, conf["dir.src"])
end

function api.dos2unix(dir, ...)
	return lfs.executein(dir, "dos2unix", ...)
end

function api.makepath(...)
	return lfs.concatfilenames(...)
end

function api.makepathdir(...)
	return lfs.addpathsep(makepath(...))
end

--
-- NOTE: iss hacked functions :)
--
function api.copy(src,dst)
	print("copying: "..src.." -> "..dst)
	return lfs.copy(src,dst)
end

function api.copydir(src,dst)
	assert(type(src) == "string")
	assert(type(dst) == "string")

	print("copying: "..src.." -> "..dst)
	lfs.mkdir(lfs.ospath(dst))
	if lfs.isunixlike() then
		return lfs.execute("cp -arfP "..lfs.ospath(src).."* "..lfs.ospath(dst))
	else
		return lfs.execute("xcopy /H /R /Q /E /I "..lfs.ospath(src).."*.* "..lfs.ospath(dst))
	end
end

function api.catfile(file,text)
	lfs.execute("echo '"..text.."' > "..file)
end

-- FIXME: to be moved to lfs... or not?
-- lfs.hardware -> lfs.cpuarch

function api.system()
	return lfs.osname()
end

function api.hardware()
	return lfs.hardware()
end

return api
