------------------------------------------------------------------
--																--
-- Copyright (C) 2003-2015, Intelibo Ltd						--
--																--
-- Project:       los											--
-- Filename:      init.lua										--
-- Description:   Main interface to los							--
--																--
------------------------------------------------------------------

local lfs         = require "lrun.util.lfs"
local config      = require "lrun.util.config"
local string      = require "lrun.util.string"
local table      = require "lrun.util.table"
local requires    = require "los.requires"

local los = {}

los._NAME = "los"
los._VERSION = "0.1"
los._DESCRIPTION = "los is command line tool providing lua powered development and runtime environment"

local defaultconf = "conf/los.conf"
local appwelcome = los._NAME.." "..los._VERSION.." Copyright (C) 2003-2015 Intelibo Ltd"
local usagetext = "Usage: "..los._NAME.." [OPTION]... COMMAND [ARGS]..."
local usagetexthelp = "Try "..los._NAME.." --help' for more options."
local errortext = los._NAME..": %s"
local helptext = [[
-c   --config CONFIG  config file path (default ]]..defaultconf..[[)
     --config-dump    dumps all configuration
-Dname=value          overwrites config definition for name
-q   --quiet          no output messages
-v   --verbose        verbose messages
-h,  --help           print this help.

where COMMAND can be one below:

install <project> [version]
]]

--- exit with usage information when the application arguments are wrong 
local function usage(errmsg)
    assert(type(errmsg) == "string", "expected string, got "..type(errmsg))
    io.stderr:write(string.format(usagetext, errmsg).."\n\n")
    io.stderr:write(usagetexthelp.."\n")
    os.exit(1)
end

--- exit with error message
local function exiterror(errmsg)
    assert(type(errmsg) == "string", "expected string, got "..type(errmsg))
    io.stderr:write(string.format(errortext, errmsg).."\n")
    os.exit(1)
end

-----------------------------------------------------------------------
-- Setup prorgam start ------------------------------------------------
-----------------------------------------------------------------------

--- parses program arguments
local function parseoptions(...)
	local opts = {}
	local args = {...}
	local err
	local i = 1
	while i <= #args do
		local arg = args[i]
		if not opts.command then
			if arg == "-h" or arg == "--help" then
				io.stderr:write(appwelcome.."\n")
				io.stderr:write(usagetext.."\n\n")
				io.stderr:write(helptext)
				os.exit(1)
			elseif arg == "-c" or arg == "--config" then
				i = i + 1
				opts.config = args[i]
				if not opts.config then
					exiterror(arg.." option expects parameter")
				end
			elseif arg == "--config-dump" then
				opts.configdump = true
			elseif arg == "-v" or arg == "--verbose" then
				opts.verbose = true
				if opts.quiet then
					exiterror(arg.." cannot be used together with -v")
				end
			elseif arg == "-q" or arg == "--quiet" then
				opts.quiet = true
				if opts.verbose then
					exiterror(arg.." cannot be used together with -q")
				end
			elseif arg:sub(1, 2) == "-D" then
				local parts = string.explode(arg:sub(3), "=")
				opts.defines = opts.defines or {}
				opts.defines[parts[1]] = parts[2] or "true"
			else
				opts.command = {string.lower(arg)}
			end
		else
			table.insert(opts.command, arg)
		end
		i = i + 1
	end
	return opts
end

-----------------------------------------------------------------------
-- Entry Point --------------------------------------------------------
-----------------------------------------------------------------------

function los.main(losdir, ...)
	local args = {...}

	-- parse program options
	local opts = parseoptions(...)

	--- load configuration
	opts.config = opts.config or lfs.concatfilenames(losdir, defaultconf)
	if not lfs.isfile(opts.config) then
		exiterror("Config file `"..opts.config.."' is missing")
	end
	opts.conf, err = config.load(opts.config)
	if not opts.conf then
		exiterror(err)
	end	
	config.set(opts.conf, "dir.lospec", lfs.concatfilenames(losdir, "lospec"))
	config.set(opts.conf, "dir.usable", lfs.concatfilenames(losdir, "usable"))

	if opts.defines then
		for dname, dvalue in pairs(opts.defines) do
			config.set(opts.conf, dname, dvalue)
		end
	end

	if opts.configdump then
		print(los._NAME.." configuration")
		print("-------------")
		for _, key in ipairs(table.values(config.keys(opts.conf), true)) do
			print(key)
			print(key.." = "..config.get(opts.conf, key))
		end
		print()
	end

	if not opts.command then
		usage("Missing parameter COMMAND")
	end

	-- register configuration globaly
	_G._conf = opts.conf

	local cmdname = table.remove(opts.command, 1):lower()
	print(_NAME.." started with command "..cmdname:lower().." "..table.concat(opts.command, " "))

	local ok, err
	if cmdname == "install" then
		if #opts.command == 0 then
			err = "install requires 1 or more arguments, try install --help"
		else
			local mod, err = requires(unpack(opts.command))
			if not mod then
				exiterror(err)
			end
			ok, err = mod.install()
			if not ok then
				exiterror(err)
			end
		end
	else
		exiterror("Unknown command "..cmdname)
	end

	if not ok then
		exiterror(err)
	end
end

return los
