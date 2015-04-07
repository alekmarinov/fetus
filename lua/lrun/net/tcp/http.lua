-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015,  Intelibo Ltd                            --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      http.lua                                           --
-- Description:   HTTP client protocol handler                       --
--                                                                   --
-----------------------------------------------------------------------

require ("copas")
require ("socket.url")
require ("socket.http")
local cosocket = require ("lrun.net.tcp.socket")

module ("lrun.net.tcp.http", package.seeall)

-- Package information 
_COPYRIGHT   = "Copyright (C) 2003-2006 AVIQ Systems AG"
_DESCRIPTION = "HTTP client protocol handler"
_VERSION     = "http 1.0"

function request(req, data)
	local reqt = req
	if type(req) == "string" then 
		reqt = {url = req}
	end
	reqt.create = reqt.create or cosocket.factory()
	return socket.http.request(reqt)
end

return getfenv()
