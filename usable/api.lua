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

function installdir()
	return lfs.path(config.get(_conf, "dir.install"))
end

function sourcedir()
	return lfs.path(config.get(_conf, "dir.src"))
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
	local os = require "os"
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
lfs.hardware = function()
	if not lfs.isunixlike() then
		return nil, "arch is not unixlike"
	end
	local io = require "io"
	local os = require "os"

	local retval = io.popen("uname -m")
	local ret = nil
	if retval then
		ret = retval:read "*a"
		retval:close()
	end
	return ret:gsub("\n",""):gsub("\r","")
end

function system()
	return lfs.osname()
end

function hardware()
	return lfs.hardware()
end
