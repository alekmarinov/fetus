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
local unarch  = require "lrun.util.extract".unarch

function download(source)
	print("api:download "..(source or "nil"))
	local srcdir = config.get(_conf, "dir.src")
	local ok, err = lfs.mkdir(srcdir)
	if not ok then
		print("mkdir "..srcdir.." failed. "..err)
		return nil, err
	end
	local filename = lfs.basename(source)
	local outfile = lfs.concatfilenames(srcdir, filename)
	if not lfs.isfile(outfile) then
		ok, err = dw.download(source, outfile)
		if not ok then
			return nil, err
		end
	end
	return outfile
end

function extract(packname)
	print("api:extract "..packname)
	local ext = lfs.ext(packname)
	local subpackname = lfs.stripext(packname)
	local targetdir = subpackname
	if (ext == ".gz" or ext == ".bz2") and lfs.ext(subpackname) == ".tar" then
		targetdir = lfs.stripext(subpackname)
	end
	local srcdir = config.get(_conf, "dir.src")
	if not lfs.isdir(targetdir) then
		print("unarch -> ", packname, srcdir)
		return unarch(packname, srcdir)
	end
	return targetdir
end
