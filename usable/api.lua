-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      api.lua                                            --
-- Description:   exported api to lospec                             --
--                                                                   --
-----------------------------------------------------------------------

local config  = require "lrun.util.config"
local dw      = require "lrun.net.www.download.luasocket"
local lfs     = require "lrun.util.lfs"
local lextract = require "lrun.util.extract"

function localfilefromurl(url)
	local srcdir = config.get(_conf, "dir.src")
	local filename = lfs.basename(url)
	return lfs.concatfilenames(srcdir, filename)
end

function srcdirfromurl(url)
	local localfile = localfilefromurl(url)
	local _, srcdir = lextract.unarchcmd(localfile)
	return srcdir
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

	print("api:extract "..packname)
	local srcdir = config.get(_conf, "dir.src")
	return lextract.unarch(packname, srcdir)
end
