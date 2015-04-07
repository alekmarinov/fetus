-------------------------------------------------------------------------------
-- $Id: console.lua,v 1.2.1.1 2006/01/07 14:26:20 alek Exp $
--
-- Prints logging information to console
--
-- Authors:
--   Thiago Costa Ponte (thiago@ideais.com.br)
--
-- Copyright (c) 2004 Kepler Project
-------------------------------------------------------------------------------

require"logging"

function logging.console(logPattern)

    return logging.new(  function(self, level, message)
                            io.stdout:write(logging.prepareLogMsg(logPattern, os.date(), level, message))
                            return true
                        end
                      )
end