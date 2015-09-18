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

function download(source)
	assert(type(source) == "string")

	log.i("download "..source)
	local outfile = path.src.file
	if not lfs.isfile(outfile) then
		local ok, err = lfs.mkdir(lfs.dirname(outfile))
		if not ok then
			return nil, err
		end
		ok, err = dw.download(source, outfile)
		if not ok then
			return nil, err
		end
	end
	return outfile
end

function unarch(packname)
	assert(type(packname) == "string")

	log.i("unarch "..packname)
	return extract.unarch(packname, conf["dir.src"])
end

function makepath(...)
	return lfs.concatfilenames(...)
end

function makepathdir(...)
	return lfs.addpathsep(makepath(...))
end

--
-- NOTE: iss hacked functions :)
--
function copy(src,dst)
	print("copying: "..src.." -> "..dst)
	return lfs.copy(src,dst)
end

function copydir(src,dst)
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

function catfile(file,text)
	lfs.execute("echo '"..text.."' > "..file)
end

-- FIXME: to be moved to lfs... or not?
-- lfs.hardware -> lfs.cpuarch

function system()
	return lfs.osname()
end

function hardware()
	return lfs.hardware()
end
