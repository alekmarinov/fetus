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
local md5        = require "md5"
require "ex"

local _G, assert, setfenv, ipairs, pairs, unpack, type, pcall, string, tostring, getfenv, setmetatable, rawset, rawget, io, os =
	  _G, assert, setfenv, ipairs, pairs, unpack, type, pcall, string, tostring, getfenv, setmetatable, rawset, rawget, io, os

local loaders = _G.package.loaders

local print = print

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
						logger(_G._log, t.package.name..": "..table.concat({...}, " "))
						io.stdout:flush()
					end
				else
					error("logger "..level.." is undefined")
				end
			end})
		-- paths
		elseif name == "path" then
			return setmetatable({}, {__index = function(t1, name)
				if name == "src" then
					local src = {}
					src.url = t.package.source
					if type(src.url) == "table" then
						src.url = src.url[t.conf["host.system"]] or src.url[1]
					end
					local basename = lfs.basename(src.url)
					local srcdir = lfs.path(t.conf["dir.src"])
					src.dir = assert(extract.unarchdir(basename, srcdir, t.package.archdir))
					src.file = lfs.concatfilenames(srcdir, lfs.basename(src.url))
					
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
	"setmetatable",
	"pcall",
	["md5"] = md5,
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
	["os"] = os,
	"_log",
	"type",
	"unpack",
	"assert",
	"tostring",
	"error"
}

-- extend lospec api
local extapi =
{
	use = function (usable, opts)
		-- load usable module
		local lomod = getfenv(2) -- parent env
		lomod[usable] = requirein ("los.use."..usable, lomod)
		lomod[usable].opts = opts or {}
		return lomod[usable]
	end
}

function parselospecfilename(lospecfile)
	return lfs.basename(lospecfile):gmatch("(.-)%-(.-)%.lospec")()
end

-- returns list with all available package names matching specified pattern
-- @param pattern: string pattern to match against each package name
function list(pattern)
	local lospecsdir = config.get(_G._conf, "dir.lospec")
	if not lfs.isdir(lospecsdir) then
		return nil, lospecsdir.." doesn't exists"
	end
	local lospecfiles = {}
	for depname in lfs.dir(lospecsdir) do
		if not pattern or depname:match(pattern) then
			for lospecfile in lfs.dir(lfs.concatfilenames(lospecsdir, depname)) do
				if lfs.ext(lospecfile) == ".lospec" and string.starts(lospecfile, depname.."-", 1) then
					local ver = assert(version.parsefromlospecfile(lospecfile))
					table.insert(lospecfiles, depname.."@"..ver.string)
				end
			end
		end
	end
	return lospecfiles
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
	local lospecmap = {}
	for _, lospecfile in ipairs(lospecfiles) do
		local ver = assert(version.parsefromlospecfile(lospecfile))
		if ver then
			table.insert(lospecvers, ver)
			lospecmap[ver] = lospecfile
		else
			_G._log:warn(_NAME..": failed version.parsefromlospecfile "..lospecfile)
		end
	end

	table.sort(lospecvers)
	local lospecveridx = version.bestindexof(lospecvers, dep.constraints)
	if not lospecveridx then
		return nil, "can't find los module matching "..dep.name
	end
	local bestver = lospecvers[lospecveridx]
	return lfs.concatfilenames(lospecdir, lospecmap[bestver]), bestver
end

-- loads lospec file
function loadfile(lospecfile)
	-- prepare environment
	local lomod = {
		lospecfile = lospecfile
	}

	_G._log:info(_NAME..": .loadfile: "..lospecfile)

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

function load(depstring)
	_G._log:info(_NAME..": .load: "..depstring)

	local dep, err = version.parsedep(depstring)
	if not dep then
		_G._log:error(_NAME..": "..(err or "can't parse "..depstring))
		return nil, err
	end

	local file, err = findfile(dep)
	if not file then
		return nil, err
	end
	return loadfile(file)
end

-- executes los module
function exec(lomod)
	local ok, err = pcall(lomod._init)
	if not ok then
		return nil, err
	end
	return true
end
