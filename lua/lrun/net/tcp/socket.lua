-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015,  Intelibo Ltd                            --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      socket.lua                                         --
-- Description:   LuaSocket wrapper                                  --
--                                                                   --
-----------------------------------------------------------------------

require("socket")
require("copas")

module ("lrun.net.tcp.socket", package.seeall)

TIMEOUT=0

function factory(sock)
	return function()
		if not sock then 
			sock = socket.tcp()
		end
		local w = copas.wrap(sock)
		function w:connect(host, port)
			return copas.connect(self.socket, host, port)
		end
		function w:close()
			return self.socket:close()
		end
		w:settimeout(TIMEOUT)
		return w
	end
end

function new(sock)
	return factory(sock)()
end

return getfenv()
