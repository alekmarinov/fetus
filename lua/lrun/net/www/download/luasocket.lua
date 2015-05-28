-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015,  Intelibo Ltd                            --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      luasocket.lua                                      --
-- Description:   Downloading method with luasocket                  --
--                                                                   --
-----------------------------------------------------------------------

local http     = require "socket.http"
local table    = require "table"
local string   = require "string"
local lfs      = require "lrun.util.lfs"
local io       = require "io"
local os       = require "os"

local assert, type, tonumber = assert, type, tonumber
local print,pairs = print,pairs
-----------------------------------------------------------------------
-- class definition ---------------------------------------------------
-----------------------------------------------------------------------
module "lrun.net.www.download.luasocket"

-----------------------------------------------------------------------
-- default attributes -------------------------------------------------
-----------------------------------------------------------------------

-- connect timeout in seconds
CONNECT_TIMEOUT = 30

-- default user agent
USER_AGENT = http.USERAGENT

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
	local url, filename, progresscb, sink, useragent, timeout = opts.url, opts.filename, opts.progresscb, nil, USER_AGENT, opts.timeout or CONNECT_TIMEOUT

	local result = {}

	local sendheaders =
	{
		["user-agent"] = useragent,
		["accept-charset"] = "ISO-8859-1,utf-8;q=0.7,*;q=0.7",
		["accept-language"] = "en-us,en;q=0.5",
		["accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
		["accept-encoding"] = "gzip,deflate,sdch",
	}
--[[
	local ok, code, headers, err = http.request
	{
		method = "HEAD",
		url = url,
		headers = sendheaders
	}
	if tonumber(code)~= 200 then
		return nil, err or code
	end
]]
	local file
	if filename then
		file, err = io.open(filename, "wb")
		if not file then
			return nil, err
		end
	end
	local totalsize = nil -- headers["content-length"]
	local downloadedsize = 0
	local timenow = os.time()
	local lastspeed
	ok, code, headers, err = http.request
	{
		method = "GET",
		url = url,
		sink = function(chunk)
			local ok, err = true
			if chunk then
				if file then
					file:write(chunk)
				else
					if sink then
						ok, err = sink(chunk)
						if not ok then
							return nil, err
						end
					else
						table.insert(result, chunk)
					end
				end
				if progresscb then
					downloadedsize = downloadedsize + chunk:len()
					local speed = 0
					local elapsed = os.time() - timenow
					if elapsed > 0 then
						speed = downloadedsize / elapsed
					end
					local fract = totalsize and downloadedsize / totalsize or 0
					if fract < 0.001 then
						fract = 0
					end
					lastspeed = speed
					if not progresscb(fract, speed) then
						return nil
					end
				end
			end
			return ok
		end,
		headers = sendheaders,
		proxy = opts.proxy,
		redirect = opts.redirect
	}
	if tonumber(code) ~= 200 then
		if file then
			file:close()
			lfs.delete(filename)
		end
		return nil, err or code
	end
	if progresscb then
		progresscb(1, lastspeed)
	end
	if file then
		file:close()
		return true, code, headers
	else
		if sink then
			return true, code, headers
		else
			return table.concat(result), code, headers
		end
	end
end
