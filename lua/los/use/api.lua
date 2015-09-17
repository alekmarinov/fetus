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

module "los.use.api"

function installdir()
	return lfs.path(config.get(_conf, "dir.install"))
end

function localfilefromurl(url)
	local srcdir = config.get(_conf, "dir.src")
	local filename = lfs.basename(url)
	return lfs.concatfilenames(srcdir, filename)
end

function srcdirfromurl(url, archdir)
	local localfile = localfilefromurl(url)
	print("srcdirfromurl: ", localfile, archdir, "->", lextract.unarchdir(localfile, lfs.dirname(localfile), archdir))
	return lextract.unarchdir(localfile, lfs.dirname(localfile), archdir)
end

function download(source)
	assert(type(source) == "string")

	print("api:download "..source)
	local outfile = localfilefromurl(source)
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

function extract(packname)
	assert(type(packname) == "string")

	print("api:unpack "..packname)
	local srcdir = config.get(_conf, "dir.src")
	return lextract.unarch(packname, srcdir)
end

return _M
