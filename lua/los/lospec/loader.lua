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
local extract    = require "lrun.util.extract"
local dw         = require "lrun.net.www.download.luasocket"
local rollback   = require "los.rollback"
local version    = require "los.lospec.version"
local package    = require "los.lospec.package"

local _G, assert, setfenv, loadfile, ipairs, pairs, type, pcall, string, tostring, getfenv, setmetatable, rawset, rawget, io =
	  _G, assert, setfenv, loadfile, ipairs, pairs, type, pcall, string, tostring, getfenv, setmetatable, rawset, rawget, io

local loaders = _G.package.loaders

module "los.lospec.loader"

local lomod_mt = 
{
	__newindex = function(t, name, value)
		if name == "package" then
			value = package.parse(value)
		end
		rawset(t, name, value)
	end,
	__index = function(t, name)
		-- access to los configuration
		if name == "_NAME" then
			return t.package and t.package._NAME or _NAME
		elseif name == "conf" then
			return setmetatable({}, {__index = function (t1, k) 
				return config.get(_G._conf, k)
			end})
		-- logging
		elseif name == "log" then
			return setmetatable({}, {__index = function(t1, level)
				local logger
				if level == "d" then
					logger = _G._log.debug
				elseif level == "i" then
					logger = _G._log.info
				elseif level == "w" then
					logger = _G._log.warn
				elseif level == "e" then
					logger = _G._log.error
				end
				if logger then
					return function(...)
						return logger(_G._log, t.package.name..": "..table.concat({...}, " "))
					end
				else
					error("logger "..level.." is undefined")
				end
			end})
		-- paths
		elseif name == "path" then
			return setmetatable({}, {__index = function(t1, name)
				if name == "src" then
					local basename = lfs.basename(t.package.source)
					local srcdir = lfs.path(t.conf["dir.src"])
					local src = {}
					src.dir = assert(extract.unarchdir(basename, srcdir, t.package.archdir))
					src.file = lfs.concatfilenames(srcdir, lfs.basename(t.package.source))
					src.url = t.package.source
					return src
				elseif name == "install" then
					local install = {}
					install.dir = lfs.path(t.conf["dir.install"])
					install.bin = lfs.concatfilenames(install.dir, "bin")
					install.lib = lfs.concatfilenames(install.dir, "lib")
					install.inc = lfs.concatfilenames(install.dir, "include")
					return install
				end
			end})
		end
	end
}

-- require loading module in specified environment
function requirein(modname, env)
	local err = {}
	for i, loader in ipairs(loaders) do
		local func = loader(modname)
		if type(func) == "function" then
			local oenv = getfenv(func)
			setfenv(func, env)
			local res = func(modname) or true
			setfenv(func, oenv)
			return res
		else
			table.insert(err, res)
		end
	end
	return nil, table.concat(err, "\n")
end

-- declares imported definitions to be accessible from lospec
local importapi =
{
	"print",
	"getfenv",
	"setfenv",
	["requirein"] = requirein,
	["loaders"] = loaders,
	["rollback"] = rollback,
	"pairs",
	"ipairs",
	["string"] = string,
	["table"] = table,
	["lfs"] = lfs,
	["extract"] = extract,
	["dw"] = dw,
	["config"] = config,
	["io"] = io,
	["_conf"] = _G._conf,
	"_log",
	"type",
	"assert",
	"tostring",
	"error"
}

-- extend lospec api
local extapi =
{
	use = function (usable)
		-- load usable module
		local lomod = getfenv(2) -- parent env
		lomod[usable] = requirein ("los.use."..usable, lomod)
		return lomod[usable]
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
		return nil, "can't find los module matching "..dep.name
	end
	return lfs.concatfilenames(lospecdir, lospecfiles[lospecveridx]), lospecvers[lospecveridx]
end

-- loads lospec file
function load(lospecfile)
	-- prepare environment
	local lomod = {}

	_G._log:info(_NAME..": .load: "..lospecfile)

	local function importfunc(name, func)
		lomod[name] = func
		setfenv(func, lomod)
	end

	-- import base api
	for i, f in pairs(importapi) do
		if type(i) == "string" then
			lomod[i] = f
		else
			lomod[f] = _G[f]
		end
	end

	-- import extended api
	for i, f in pairs(extapi) do
		importfunc(i, f)
	end

	local err
	lomod._init, err = _G.loadfile(lospecfile)
	if not lomod._init then
		return nil, err
	end

	setfenv(lomod._init, lomod)
	setfenv(1, lomod)
	use "api"

	setmetatable(lomod, lomod_mt)

	return lomod
end

-- executes los module
function exec(lomod)
	local ok, err = pcall(lomod._init)
	if not ok then
		return nil, err
	end
	return true
end
