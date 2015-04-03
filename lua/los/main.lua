-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2012,  AVIQ Systems AG                              --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      main.lua                                           --
-- Description:   Main interface to LOS tool                         --
--                                                                   --
-----------------------------------------------------------------------

local lfs         = require "lrun.util.lfs"
local config      = require "lrun.util.config"
local log         = require "los.log"
local env         = require "los.env"

module ("los.main", package.seeall)

_NAME = "LOS"
_VERSION = "0.1"
_DESCRIPTION = "LOS is Lua OS environment building tool"

local defaultconf="los.conf"
local appwelcome = _NAME.." ".._VERSION.." Copyright (C) 2006-2012 AVIQ Bulgaria Ltd"
local usagetext = "Usage: ".._NAME.." [OPTION]... COMMAND [ARGS]..."
local usagetexthelp = "Try ".._NAME.." --help' for more options."
local errortext = _NAME..": %s"
local helptext = [[
-c   --config CONFIG  config file path (default ]]..defaultconf..[[)
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
			else
				opts.command = {string.lower(arg)}
			end
		else
			table.insert(opts.command, arg)
		end
		i = i + 1
	end
	if not opts.command then
		usage("Missing parameter COMMAND")
	end

	--- set program defaults
	opts.config = opts.config or defaultconf
	if not lfs.isfile(opts.config) then
		exiterror("Config file `"..opts.config.."' is missing")
	end
	opts.conf, err = config.load(opts.config)
	if not opts.conf then
		exiterror(err)
	end	
	return opts
end

-----------------------------------------------------------------------
-- Entry Point --------------------------------------------------------
-----------------------------------------------------------------------

function main(...)
	local args = {...}

	-- parse program options
	local opts = parseoptions(...)

	log.setverbosity(opts.quiet, opts.verbose)

	-- register configuration globaly
	_G._conf = opts.conf

	local cmdname = table.remove(opts.command, 1):lower()
	log.info(_NAME.." started with command "..cmdname:lower().." "..table.concat(opts.command, " "))

	local ok, err
	if cmdname == "install" then
		if #opts.command == 0 then
			err = "install requires 1 or more arguments, try install --help"
		else
			ok, err = env.requires(unpack(opts.command))
			if ok then
				ok.install()
			end
		end
	else
		exiterror("Unknown command "..cmdname)
	end

	if not ok then
		exiterror(err)
	end
end
