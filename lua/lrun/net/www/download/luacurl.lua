-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015,  Intelibo Ltd                            --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      luacurl.lua                                        --
-- Description:   Downloading method with luacurl                    --
--                                                                   --
-----------------------------------------------------------------------

local curl     = require "luacurl"
local table    = require "table"
local string   = require "lrun.util.string"
local lfs      = require "lrun.util.lfs"
local io       = require "io"
local os       = require "os"

local assert, type, tonumber = assert, type, tonumber

-----------------------------------------------------------------------
-- class definition ---------------------------------------------------
-----------------------------------------------------------------------
module "lrun.net.www.download.luacurl"

-----------------------------------------------------------------------
-- default attributes -------------------------------------------------
-----------------------------------------------------------------------

-- connect timeout in seconds
CONNECT_TIMEOUT = 30

-- default user agent
USER_AGENT = "LuaCURL "..curl._VERSION

----------------------------------------------------------
-- local definitions  -------------------------------------------------
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- public methods  ----------------------------------------------------
-----------------------------------------------------------------------

function download(url, filename, opts)
	if type(url) == "table" then
		opts = url
	else
		if type(filename) == "table" then
			opts = filename
			opts.url = url
		else
			opts = opts or {}
			opts.url = url
			opts.filename = filename
		end
	end
	local url, filename, progresscb, sink, useragent, timeout, proxy = opts.url, opts.filename, opts.progresscb, nil, USER_AGENT, opts.timeout or CONNECT_TIMEOUT, opts.proxy

	local headers = {}
	local c = curl.new()
	c:setopt(curl.OPT_URL, url)
	c:setopt(curl.OPT_CONNECTTIMEOUT, timeout)
	c:setopt(curl.OPT_NOPROGRESS, progresscb == nil)
	c:setopt(curl.OPT_HEADERFUNCTION, function (_, line)
		string.gsub(line, "(.-)%:(.*)", function (n, v)
			headers[string.lower(n)] = string.trim(v)
		end)
		return string.len(line)
	end)

	local ok, err, file
	if filename then
		file, err = io.open(filename, "wb")
		if not file then
			return nil, err
		end
		c:setopt(curl.OPT_WRITEDATA, file)
		c:setopt(curl.OPT_FAILONERROR, true)
	end
	local result
	c:setopt(curl.OPT_WRITEFUNCTION, function (fd, chunk)
		if file then
			return fd:write(chunk) and string.len(chunk) or 0
		else
			if sink then
				ok, err = sink(chunk)
				if not ok then
					return nil, err
				end
			else
				result = result or {}
				table.insert(result, chunk)
			end
		end
		return string.len(chunk)
	end)

	if proxy then
		c:setopt(curl.OPT_PROXY, proxy)
	end

	ok, err = c:perform()
	local code = c:getinfo(curl.INFO_RESPONSE_CODE)
	c:close()
	if file then
		file:close()
	end
	if not ok then
		return nil, code, headers
	end
	if result then
		return table.concat(result), code, headers
	end
	return true, code, headers
end
