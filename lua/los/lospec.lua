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
local version    = require "los.lospec.format.version"

local _G, assert, setfenv, loadfile, ipairs, pairs, type, pcall, string, tostring, getfenv, print =
	  _G, assert, setfenv, loadfile, ipairs, pairs, type, pcall, string, tostring, getfenv, print

module "los.lospec"

-- declares imported definitions to be accessible from lospec
local importapi =
{
	"print", -- debug
	"getfenv",
	"setfenv",
	"package",
	"require",
	"pairs",
	"ipairs",
	["string"] = string,
	["table"] = table,
	["lfs"] = lfs,
	["config"] = config,
	["_conf"] = _G._conf,
	"_log",
	"type",
	"assert",
	"loadfile"
}

-- extend lospec api
local extapi =
{
	use = function (usable)
		-- load usable module
		local usemod = require ("los.use."..usable)

		-- import usable api with environment set to this los module environment
		local env = getfenv()
		for i, v in pairs(usemod) do
			if type(v) == "function" then
				setfenv(v, env)
			end
			env[i] = v
		end
		env[usable] = usemod
	end
}

function parselospecfilename(lospecfile)
	return lfs.basename(lospecfile):gmatch("(.-)%-(.-)%.lospec")()
end

-- locates lospec file corresponding to specified parsed dependency
-- returns the full file path to lospec file
-- @param dep: table representing parsed dependency description
function findfile(dep)
	local lospecdir = lfs.concatfilenames(config.get(_G._conf, "dir.lospec"), dep.name)
	if not lfs.isdir(lospecdir) then
		return nil, lospecdir.." doesn't exists"
	end
	local lospecfiles = {}
	for file in lfs.dir(lospecdir) do
		if lfs.ext(file) == ".lospec" and string.starts(file, dep.name.."-", 1) then
			table.insert(lospecfiles, file)
		end
	end
	if #lospecfiles == 0 then
		return nil, "No .lospecs found for `"..pckname.."'"
	end

	local lospecvers = {}
	for _, lospecfile in ipairs(lospecfiles) do
		local ver = assert(version.parsefromlospecfile(lospecfile))
		if ver then
			table.insert(lospecvers, ver)
		else
			_G._log:warn(_NAME..": failed version.parsefromlospecfile "..lospecfile)
		end
	end

	local lospecveridx = version.bestindexof(lospecvers, dep.constraints)
	if not lospecveridx then
		return nil, "can't find los module matching "..depstring
	end
	return lfs.concatfilenames(lospecdir, lospecfiles[lospecveridx]) , lospecvers[lospecveridx]
end

-- loads lospec file
function load(lospecfile)
	_G._log:info(_NAME..": .load: "..lospecfile)

	-- prepare environment
	local env = {}

	local function importfunc(name, func)
		env[name] = func
		setfenv(func, env)
	end

	-- import base api
	for i, f in pairs(importapi) do
		if type(i) == "string" then
			env[i] = f
		else
			env[f] = _G[f]
		end
	end

	-- import extended api
	for i, f in pairs(extapi) do
		importfunc(i, f)
	end

	local f, err = _G.loadfile(lospecfile)
	if not f then
		return nil, err
	end
	setfenv(f, env)
	setfenv(1, env)
	use "api"
	return f, env
end

-- executes los module
function exec(lomod)
	local ok, err = pcall(lomod)
	if not ok then
		return nil, err
	end
	return true
end
