-------------------------------------------------------------------------------
-- $Id: socket.lua,v 1.2.1.1 2006/01/07 14:26:20 alek Exp $
--
-- Sends the logging information through a socket using luasocket
--
-- Authors:
--   Thiago Costa Ponte (thiago@ideais.com.br)
--
-- Copyright (c) 2004 Kepler Project
-------------------------------------------------------------------------------

require"logging"

function logging.socket(sock, logPattern)

    return logging.new( function(self, level, message)
                            local s = logging.prepareLogMsg(logPattern, os.date(), level, message)
                            
                            local cond, err = sock:send(s)
                            if not cond then
                                return nil, err
                            end

                            return true
                        end
                      )
end
