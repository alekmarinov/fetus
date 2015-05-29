-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      lospec.lua                                         --
-- Description:   lospec file utilities                              --
--                                                                   --
-----------------------------------------------------------------------

local lfs        = require "lrun.util.lfs"
local config     = require "lrun.util.config"
local string     = require "lrun.util.string"
local table      = require "lrun.util.table"

local lospec = {}

-- locates lospec file corresponding to specified pckname and version
-- returns the full file path
function lospec.findfile(pckname, version)
	local lospecdir = lfs.concatfilenames(config.get(_conf, "dir.lospec"), pckname)
	if not lfs.isdir(lospecdir) then
		return nil, lospecdir.." doesn't exists"
	end
	local lospecfile
	if not version then
		local lospecs = {}
		for file in lfs.dir(lospecdir) do
			if lfs.ext(file) == ".lospec" and string.starts(file, pckname.."-", 1) then
				table.insert(lospecs, file)
			end
		end
		if #lospecs == 0 then
			return nil, "No .lospecs found for `"..pckname.."'"
		end
		table.sort(lospecs)
		lospecfile = lospecs[#lospecs]
		string.gsub(lospecfile, "[^%-]*%-(.-)%.lospec", function (v)
			version = v
		end)
		lospecfile = lfs.concatfilenames(lospecdir, lospecfile)
	else
		lospecfile = lfs.concatfilenames(lospecdir, pckname.."-"..version..".lospec")
	end
	if not lfs.isfile(lospecfile) then
		return nil, lospecfile.." not found"
	end
	return lospecfile, version
end

return lospec
